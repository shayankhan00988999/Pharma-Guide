import 'dart:io';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/drive_node.dart';
import '../services/document_cache_service.dart';
import '../theme/app_theme.dart';

/// Built-in document reader. Students read notes without leaving the app.
///
/// - PDFs and images are downloaded once into a local cache and rendered
///   natively (smooth pinch-zoom, page counter, jump-to-page). Opened files
///   also work offline afterwards.
/// - Word / PowerPoint / Excel and any other type are shown through an
///   embedded preview inside the app, so the student is never bounced out
///   to the browser or the Drive app.
class DocumentViewerScreen extends StatefulWidget {
  final DriveNode node;

  const DocumentViewerScreen({super.key, required this.node});

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

enum _Kind { pdf, image, web }

enum _Phase { loading, pdf, image, web, error }

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final _cache = DocumentCacheService();
  final _cancel = CancelToken();

  _Phase _phase = _Phase.loading;
  double? _progress;
  String? _error;
  File? _file;

  PdfControllerPinch? _pdf;
  final ValueNotifier<int> _page = ValueNotifier<int>(1);
  int _pages = 0;

  WebViewController? _web;
  double _webProgress = 0;

  DriveNode get node => widget.node;

  _Kind get _kind {
    final name = node.name.toLowerCase();
    if (node.iconHint == 'pdf' || name.endsWith('.pdf')) return _Kind.pdf;
    const imageExt = ['.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'];
    if (node.iconHint == 'image' || imageExt.any(name.endsWith)) {
      return _Kind.image;
    }
    return _Kind.web;
  }

  String get _previewUrl =>
      'https://drive.google.com/file/d/${node.id}/preview';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cancel.cancel();
    _pdf?.dispose();
    _page.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _progress = null;
      _error = null;
    });

    final kind = _kind;
    if (kind == _Kind.web) {
      _openWeb();
      return;
    }

    try {
      var lastShown = 0.0;
      final file = await _cache.fetch(
        node,
        cancelToken: _cancel,
        onProgress: (p) {
          // Throttle rebuilds: only repaint on ~2% steps.
          if (!mounted) return;
          if (p == null || (p - lastShown) >= 0.02 || p >= 1) {
            lastShown = p ?? lastShown;
            setState(() => _progress = p);
          }
        },
      );
      if (!mounted) return;
      _file = file;

      if (kind == _Kind.pdf) {
        _pdf?.dispose();
        _pdf = PdfControllerPinch(document: PdfDocument.openFile(file.path));
        _page.value = 1;
        _pages = 0;
        setState(() => _phase = _Phase.pdf);
      } else {
        setState(() => _phase = _Phase.image);
      }
    } catch (e) {
      if (!mounted) return;
      if (e is DioException && CancelToken.isCancel(e)) return;
      // Native rendering wasn't possible (e.g. a very large file Drive
      // won't hand out directly) — fall back to the embedded preview.
      _openWeb();
    }
  }

  void _openWeb() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _webProgress = p / 100);
          },
          onWebResourceError: (e) {
            if (e.isForMainFrame == false) return;
            if (!mounted) return;
            setState(() {
              _phase = _Phase.error;
              _error = 'Could not load this document. '
                  'Please check your internet connection and try again.';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(_previewUrl));

    setState(() {
      _web = controller;
      _webProgress = 0;
      _phase = _Phase.web;
    });
  }

  Future<void> _openExternally() async {
    final file = _file;
    if (file != null) {
      await OpenFilex.open(file.path);
    }
  }

  Future<void> _openInBrowser() async {
    final url = node.viewUrl ?? _previewUrl;
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _askPage() async {
    if (_pages <= 0) return;
    final controller = TextEditingController();
    final target = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.night2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Go to page',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '1 – $_pages',
            hintStyle: const TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.tealLight),
            ),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(int.tryParse(v)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(int.tryParse(controller.text)),
            child: const Text('Go',
                style: TextStyle(
                    color: AppColors.tealLight, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (target != null) _goToPage(target);
  }

  void _goToPage(int page) {
    if (_pdf == null || _pages <= 0) return;
    _pdf!.jumpToPage(page.clamp(1, _pages));
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.night,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.loading:
        return _buildLoading();
      case _Phase.pdf:
        return _buildPdf();
      case _Phase.image:
        return _buildImage();
      case _Phase.web:
        return _buildWeb();
      case _Phase.error:
        return _buildError();
    }
  }

  // ---- header

  ({IconData icon, Color color, String label}) get _typeStyle {
    switch (node.iconHint) {
      case 'pdf':
        return (
          icon: Icons.picture_as_pdf_rounded,
          color: AppColors.coral,
          label: 'PDF'
        );
      case 'image':
        return (
          icon: Icons.image_rounded,
          color: AppColors.skyBlue,
          label: 'Image'
        );
      case 'ppt':
        return (
          icon: Icons.slideshow_rounded,
          color: AppColors.amber,
          label: 'Presentation'
        );
      case 'doc':
        return (
          icon: Icons.description_rounded,
          color: AppColors.purpleLight,
          label: 'Document'
        );
      case 'xls':
        return (
          icon: Icons.grid_on_rounded,
          color: AppColors.tealLight,
          label: 'Spreadsheet'
        );
      default:
        return (
          icon: Icons.insert_drive_file_rounded,
          color: Colors.white70,
          label: 'File'
        );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildHeader(BuildContext context) {
    final style = _typeStyle;
    final subtitle = [
      style.label,
      if (node.sizeBytes != null) _formatSize(node.sizeBytes!),
    ].join('  ·  ');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.night2,
        border: Border(
          bottom: BorderSide(color: Color(0x1FFFFFFF), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: style.color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                color: AppColors.night2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                onSelected: (v) {
                  if (v == 'external') _openExternally();
                  if (v == 'browser') _openInBrowser();
                },
                itemBuilder: (_) => [
                  if (_file != null)
                    _menuItem('external', Icons.open_in_new_rounded,
                        'Open with another app'),
                  _menuItem('browser', Icons.public_rounded, 'Open in browser'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // ---- loading

  Widget _buildLoading() {
    final style = _typeStyle;
    final pct = _progress != null ? '${(_progress! * 100).round()}%' : null;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 84,
                    height: 84,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 4,
                      color: AppColors.tealLight,
                      backgroundColor: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  Icon(style.icon, color: style.color, size: 34),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Preparing your document',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pct ?? 'Just a moment…',
              style: TextStyle(color: Colors.white.withOpacity(0.65)),
            ),
          ],
        ),
      ),
    );
  }

  // ---- error

  Widget _buildError() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(28),
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 46, color: AppColors.coral),
            const SizedBox(height: 14),
            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.85)),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
            TextButton(
              onPressed: _openInBrowser,
              child: const Text('Open in browser',
                  style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  // ---- PDF

  Widget _buildPdf() {
    final controller = _pdf!;
    return Stack(
      children: [
        Positioned.fill(
          child: PdfViewPinch(
            controller: controller,
            onDocumentLoaded: (doc) {
              if (mounted) setState(() => _pages = doc.pagesCount);
            },
            onPageChanged: (page) => _page.value = page,
            builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
              options: const DefaultBuilderOptions(),
              documentLoaderBuilder: (_) => const Center(
                child: CircularProgressIndicator(color: AppColors.tealLight),
              ),
              pageLoaderBuilder: (_) => const Center(
                child: CircularProgressIndicator(color: AppColors.tealLight),
              ),
              errorBuilder: (_, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 44, color: AppColors.coral),
                      const SizedBox(height: 12),
                      const Text(
                        'This PDF could not be displayed here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.teal),
                        onPressed: _openWeb,
                        child: const Text('Open preview'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_pages > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 18 + MediaQuery.of(context).padding.bottom,
            child: Center(child: _buildPagePill()),
          ),
      ],
    );
  }

  Widget _buildPagePill() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.night2.withOpacity(0.72),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          child: ValueListenableBuilder<int>(
            valueListenable: _page,
            builder: (context, page, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded,
                        color: Colors.white),
                    tooltip: 'Previous page',
                    onPressed: page > 1 ? () => _goToPage(page - 1) : null,
                  ),
                  GestureDetector(
                    onTap: _askPage,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '$page / $_pages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white),
                    tooltip: 'Next page',
                    onPressed:
                        page < _pages ? () => _goToPage(page + 1) : null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---- image

  Widget _buildImage() {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 5,
      child: Center(
        child: Image.file(
          _file!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Padding(
            padding: EdgeInsets.all(28),
            child: Text(
              'This image could not be displayed.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // ---- embedded preview (Word / PowerPoint / Excel / other)

  Widget _buildWeb() {
    return Stack(
      children: [
        Positioned.fill(child: WebViewWidget(controller: _web!)),
        if (_webProgress < 1)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value: _webProgress == 0 ? null : _webProgress,
              minHeight: 3,
              color: AppColors.tealLight,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }
}
