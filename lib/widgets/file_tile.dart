import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/drive_node.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';

class FileTile extends StatelessWidget {
  final DriveNode node;

  const FileTile({super.key, required this.node});

  ({IconData icon, Color color}) get _style {
    switch (node.iconHint) {
      case 'pdf':
        return (icon: Icons.picture_as_pdf_rounded, color: AppColors.coral);
      case 'image':
        return (icon: Icons.image_rounded, color: AppColors.skyBlue);
      case 'ppt':
        return (icon: Icons.slideshow_rounded, color: AppColors.amber);
      case 'doc':
        return (icon: Icons.description_rounded, color: AppColors.purple);
      case 'xls':
        return (icon: Icons.grid_on_rounded, color: AppColors.tealLight);
      default:
        return (icon: Icons.insert_drive_file_rounded, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: style.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(style.icon, color: style.color),
        ),
        title: Text(node.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            node.sizeBytes != null ? Text(_formatSize(node.sizeBytes!)) : null,
        trailing: IconButton(
          icon: Icon(Icons.download_rounded, color: style.color),
          tooltip: 'Download',
          onPressed: () => _download(context),
        ),
        onTap: () => _open(context),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    if (node.viewUrl == null) return;
    final uri = Uri.parse(node.viewUrl!);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not open file')));
      }
    }
  }

  Future<void> _download(BuildContext context) async {
    if (node.downloadUrl == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text('Downloading ${node.name}...')));

    try {
      await DownloadService().downloadAndOpen(
        url: node.downloadUrl!,
        fileName: node.name,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
