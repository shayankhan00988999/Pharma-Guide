import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/drive_node.dart';

/// Fetches a Drive file into a local cache folder so the in-app reader
/// can render it from disk.
///
/// - A file that was already opened once is served instantly from the
///   cache (and works offline).
/// - The cache key includes the file's last-modified stamp, so if you
///   replace a file in Drive the students automatically get the new
///   version instead of a stale copy.
/// - Downloads go to a ".part" file first and are only renamed when
///   complete, so an interrupted download never leaves a broken file.
class DocumentCacheService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 90),
      followRedirects: true,
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      },
    ),
  );

  Future<File> _cacheFileFor(DriveNode node) async {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/reader_cache');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final safeName = node.name.replaceAll(RegExp(r'[^\w\.\- ]'), '_');
    final stamp = (node.modifiedAt ?? '').hashCode.toRadixString(16);
    return File('${dir.path}/${node.id}_${stamp}_$safeName');
  }

  /// Returns the local copy of [node], downloading it first if needed.
  /// Throws if the download fails or Drive returns a web page instead of
  /// the real file (which happens for very large files, where Drive
  /// shows a "can't scan for viruses" page).
  Future<File> fetch(
    DriveNode node, {
    void Function(double? progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final target = await _cacheFileFor(node);
    if (await target.exists() && await target.length() > 0) {
      return target;
    }

    final url = node.downloadUrl;
    if (url == null) {
      throw Exception('No download link available for this file.');
    }

    final part = File('${target.path}.part');
    if (await part.exists()) await part.delete();

    await _dio.download(
      url,
      part.path,
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) {
        if (onProgress == null) return;
        onProgress(total > 0 ? received / total : null);
      },
    );

    if (await _looksLikeHtml(part) && !node.name.toLowerCase().endsWith('.html')) {
      await part.delete();
      throw Exception('Drive returned a web page instead of the file.');
    }

    await part.rename(target.path);
    return target;
  }

  Future<bool> _looksLikeHtml(File file) async {
    final chunks = await file.openRead(0, 512).toList();
    final bytes = chunks.expand((c) => c).toList();
    final head = String.fromCharCodes(bytes).trimLeft().toLowerCase();
    return head.startsWith('<!doctype html') || head.startsWith('<html');
  }
}
