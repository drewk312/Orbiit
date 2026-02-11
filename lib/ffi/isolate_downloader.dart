import 'dart:async';
import 'dart:io';
import 'dart:isolate';

enum DownloadMessageType { started, progress, completed, error, cancelled }

class DownloadMessage {
  final DownloadMessageType type;
  final double progress;
  final String? message;
  final String? error;
  final int bytesDownloaded;
  final int totalBytes;

  DownloadMessage({
    required this.type,
    this.progress = 0.0,
    this.message,
    this.error,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
  });
}

class IsolateDownloader {
  Isolate? _isolate;
  final ReceivePort _receivePort = ReceivePort();
  final StreamController<DownloadMessage> _streamController =
      StreamController<DownloadMessage>.broadcast();

  Stream<DownloadMessage> get messageStream => _streamController.stream;

  IsolateDownloader();

  Future<void> startDownload(String url, String destPath) async {
    try {
      _isolate = await Isolate.spawn(
        _downloadIsolate,
        {
          'sendPort': _receivePort.sendPort,
          'url': url,
          'destPath': destPath,
        },
      );

      _receivePort.listen((message) {
        if (message is Map) {
          final typeStr = message['type'];

          if (typeStr == 'started') {
            _streamController.add(DownloadMessage(
              type: DownloadMessageType.started,
              message: message['message'],
            ));
          } else if (typeStr == 'progress') {
            _streamController.add(DownloadMessage(
              type: DownloadMessageType.progress,
              progress: (message['progress'] as num).toDouble(),
              message: message['message'],
              bytesDownloaded: (message['bytesDownloaded'] as num).toInt(),
              totalBytes: (message['totalBytes'] as num).toInt(),
            ));
          } else if (typeStr == 'completed') {
            _streamController.add(DownloadMessage(
              type: DownloadMessageType.completed,
              progress: 1,
              message: message['message'],
              bytesDownloaded: (message['bytesDownloaded'] as num).toInt(),
              totalBytes: (message['totalBytes'] as num).toInt(),
            ));
            cancel();
          } else if (typeStr == 'error') {
            _streamController.add(DownloadMessage(
              type: DownloadMessageType.error,
              error: message['error'],
              message: message['message'],
            ));
            cancel();
          }
        }
      });
    } catch (e) {
      _streamController.add(DownloadMessage(
        type: DownloadMessageType.error,
        error: e.toString(),
        message: 'Startup Error',
      ));
    }
  }

  Future<void> cancel() async {
    _streamController.add(DownloadMessage(type: DownloadMessageType.cancelled));
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    // Don't close stream controller immediately as it might be listened to,
    // or arguably we should. But broadcast streams handle this.
  }

  static Future<void> _downloadIsolate(Map<String, dynamic> config) async {
    final sendPort = config['sendPort'] as SendPort;
    final url = config['url'] as String;
    final destPath = config['destPath'] as String;

    try {
      sendPort.send(
          {'type': 'started', 'message': 'Connecting...', 'progress': 0.0});

      final finalFile = File(destPath);
      final partFile = File('$destPath.part');

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15);

      int totalBytes = -1;

      try {
        final headReq = await client.headUrl(Uri.parse(url));
        final headResp = await headReq.close();
        if (headResp.contentLength > 0) totalBytes = headResp.contentLength;
        // Drain any body? HEAD shouldn't have one but good practice.
        await headResp
            .drain()
            .timeout(const Duration(seconds: 5), onTimeout: () {});
      } catch (e) {
        // ignore head failure
      }

      // 1. Check if the FINAL file already exists and is valid
      if (await finalFile.exists()) {
        try {
          final len = await finalFile.length();

          if (totalBytes > 0 && len >= totalBytes) {
            sendPort.send({
              'type': 'completed',
              'progress': 1.0,
              'message': 'File verified complete',
              'bytesDownloaded': totalBytes,
              'totalBytes': totalBytes,
            });
            client.close();
            return;
          } else {
            // Move incomplete final file to .part
            if (await partFile.exists()) {
              await partFile.delete();
            }
            await finalFile.rename(partFile.path);
          }
        } catch (e) {
          // ignore
        }
      }

      int downloaded = 0;
      if (await partFile.exists()) {
        downloaded = await partFile.length();
      }

      if (datasetLooksComplete(downloaded, totalBytes)) {
        if (await finalFile.exists()) await finalFile.delete();
        await partFile.rename(destPath);

        sendPort.send({
          'type': 'completed',
          'progress': 1.0,
          'message': 'Download complete',
          'bytesDownloaded': totalBytes,
          'totalBytes': totalBytes,
        });
        client.close();
        return;
      }

      int retryCount = 0;
      const maxRetries = 100; // Robust

      while (retryCount < maxRetries) {
        bool success = false;
        try {
          final request = await client.getUrl(Uri.parse(url));

          if (await partFile.exists()) {
            downloaded = await partFile.length();
          } else {
            downloaded = 0;
          }

          if (downloaded > 0) {
            request.headers.add('Range', 'bytes=$downloaded-');
          }

          final response = await request.close();
          final statusCode = response.statusCode;

          if (statusCode == 200) {
            if (downloaded > 0) {
              try {
                await partFile.delete();
              } catch (_) {}
              downloaded = 0;
            }
            if (response.contentLength > 0) totalBytes = response.contentLength;
          } else if (statusCode == 206) {
            if (totalBytes == -1) {
              final contentRange =
                  response.headers.value(HttpHeaders.contentRangeHeader);
              if (contentRange != null) {
                final match = RegExp(r'/(\d+)').firstMatch(contentRange);
                if (match != null) totalBytes = int.parse(match.group(1)!);
              }
            }
          } else if (statusCode == 416) {
            success = true; // Loop break
            break;
          } else {
            throw SocketException('HTTP $statusCode');
          }

          final int effectiveTotal = totalBytes > 0
              ? totalBytes
              : (downloaded + response.contentLength);

          final sink = partFile.openWrite(mode: FileMode.append);

          DateTime lastUpdate = DateTime.now();
          int bytesSinceLast = 0;
          double speed = 0;

          await for (final chunk in response) {
            sink.add(chunk);
            downloaded += chunk.length;
            bytesSinceLast += chunk.length;

            final now = DateTime.now();
            final diff = now.difference(lastUpdate).inMilliseconds;

            if (diff > 500) {
              final timeSec = diff / 1000.0;
              final instantSpeed = bytesSinceLast / timeSec;
              speed = (speed == 0)
                  ? instantSpeed
                  : (speed * 0.7 + instantSpeed * 0.3);

              final mbCurrent = (downloaded / 1024 / 1024).toStringAsFixed(1);
              final mbTotal = effectiveTotal > 0
                  ? (effectiveTotal / 1024 / 1024).toStringAsFixed(1)
                  : '???';
              final speedMB = (speed / 1024 / 1024).toStringAsFixed(1);
              final msg = '$mbCurrent / $mbTotal MB • $speedMB MB/s';

              sendPort.send({
                'type': 'progress',
                'progress': effectiveTotal > 0
                    ? (downloaded / effectiveTotal).clamp(0.0, 1.0)
                    : 0.0,
                'message': msg,
                'bytesDownloaded': downloaded,
                'totalBytes': effectiveTotal > 0 ? effectiveTotal : 0
              });

              lastUpdate = now;
              bytesSinceLast = 0;
            }
          }

          await sink.flush();
          await sink.close();

          if (datasetLooksComplete(downloaded, totalBytes)) {
            success = true;
            break;
          } else {
            // incomplete, loop
          }
        } catch (e) {
          retryCount++;
          sendPort.send({
            'type': 'progress',
            'progress': 0.0,
            'message': 'Retrying ($retryCount/$maxRetries)...',
            'bytesDownloaded': downloaded,
            'totalBytes': totalBytes
          });
          await Future.delayed(const Duration(seconds: 2));
        }

        if (success) break;
      }

      if (datasetLooksComplete(downloaded, totalBytes)) {
        if (await finalFile.exists()) await finalFile.delete();
        await partFile.rename(destPath);

        sendPort.send({
          'type': 'completed',
          'progress': 1.0,
          'message': 'Download complete',
          'bytesDownloaded': downloaded,
          'totalBytes': totalBytes,
        });
      } else {
        throw Exception('Download failed after max retries.');
      }

      client.close();
    } catch (e) {
      sendPort.send({
        'type': 'error',
        'error': e.toString(),
        'message': 'Isolate Error: $e'
      });
    }
  }

  static bool datasetLooksComplete(int downloaded, int totalBytes) {
    if (totalBytes > 0 && downloaded >= totalBytes) return true;
    return false;
  }
}
