import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import '../main.dart'; // For AppConfig

class UpdateRelease {
  final String tagName;
  final String htmlUrl;
  final String body;
  final List<UpdateAsset> assets;

  UpdateRelease({
    required this.tagName,
    required this.htmlUrl,
    required this.body,
    required this.assets,
  });

  factory UpdateRelease.fromJson(Map<String, dynamic> json) {
    return UpdateRelease(
      tagName: json['tag_name'] ?? '',
      htmlUrl: json['html_url'] ?? '',
      body: json['body'] ?? '',
      assets: (json['assets'] as List?)
              ?.map((e) => UpdateAsset.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class UpdateAsset {
  final String name;
  final String browserDownloadUrl;
  final int size;

  UpdateAsset({
    required this.name,
    required this.browserDownloadUrl,
    required this.size,
  });

  factory UpdateAsset.fromJson(Map<String, dynamic> json) {
    return UpdateAsset(
      name: json['name'] ?? '',
      browserDownloadUrl: json['browser_download_url'] ?? '',
      size: json['size'] ?? 0,
    );
  }
}

class UpdateService {
  static const String _repoOwner = 'drewk312';
  static const String _repoName = 'Orbiit';

  // Use a simplified version comparison (assumes semver-like tags e.g. v1.0.1)
  Future<UpdateRelease?> checkForUpdates() async {
    try {
      final uri = Uri.https(
          'api.github.com', '/repos/$_repoOwner/$_repoName/releases/latest');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final release = UpdateRelease.fromJson(data);

        final currentVersion = AppConfig.version; // e.g., "1.0.0"
        final latestTag = release.tagName.replaceAll('v', ''); // e.g., "1.0.1"

        if (_isNewer(latestTag, currentVersion)) {
          return release;
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }

  bool _isNewer(String latest, String current) {
    // Basic splitting by '.'
    final lParts = latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < lParts.length && i < cParts.length; i++) {
      if (lParts[i] > cParts[i]) return true;
      if (lParts[i] < cParts[i]) return false;
    }
    // If lengths differ, the longer one is usually newer if the common parts are equal
    // but typically versions are x.y.z
    return lParts.length > cParts.length;
  }

  Future<void> downloadAndInstall(
      UpdateRelease release, Function(double) onProgress) async {
    // Find the asset usually named Setup.exe or similar
    final asset = release.assets.firstWhere(
      (a) => a.name.toLowerCase().endsWith('.exe'),
      orElse: () => throw Exception('No executable found in release'),
    );

    final downloadsDir = await getTemporaryDirectory();
    final filePath = path.join(downloadsDir.path, asset.name);

    final request = http.Request('GET', Uri.parse(asset.browserDownloadUrl));
    final response = await http.Client().send(request);

    final totalBytes = response.contentLength ?? asset.size;
    int receivedBytes = 0;

    final file = File(filePath);
    final sink = file.openWrite();

    await response.stream.listen(
      (chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        onProgress(receivedBytes / totalBytes);
      },
      onDone: () async {
        await sink.close();
        // Run the installer
        await Process.run(filePath, []);
        // Exit app? Maybe let the installer handle closing it
      },
      onError: (e) {
        sink.close();
        throw e;
      },
    ).asFuture();
  }
}
