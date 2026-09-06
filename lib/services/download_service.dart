import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';

class DownloadService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  /// Downloads [url] to the app's documents folder under [fileName] and
  /// opens it with the device's default viewer. Returns the local path.
  Future<String> downloadAndOpen({
    required String url,
    required String fileName,
    void Function(double progress)? onProgress,
  }) async {
    await Permission.storage.request();

    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/$fileName';

    await _dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    await OpenFilex.open(savePath);
    return savePath;
  }

  Future<bool> alreadyDownloaded(String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName').exists();
  }
}
