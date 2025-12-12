import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_file/open_file.dart';

class PresentationPreviewScreen extends StatefulWidget {
  final String url;
  final String title;

  const PresentationPreviewScreen({
    super.key,
    required this.url,
    this.title = 'Presentation Preview',
  });

  @override
  State<PresentationPreviewScreen> createState() =>
      _PresentationPreviewScreenState();
}

class _PresentationPreviewScreenState extends State<PresentationPreviewScreen> {
  String? _localFilePath;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _downloadFileForPreview();
  }

  Future<void> _downloadFileForPreview() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = widget.url.split('/').last;
      final file = File('${dir.path}/$fileName');

      if (await file.exists()) {
        setState(() {
          _localFilePath = file.path;
          _isLoading = false;
        });
        return;
      }

      await Dio().download(widget.url, file.path);

      if (mounted) {
        setState(() {
          _localFilePath = file.path;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load preview: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadToStorage() async {
    if (_localFilePath == null) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      if (!kIsWeb && Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }

        if (!status.isGranted) {
          var manageStatus = await Permission.manageExternalStorage.status;
          if (!manageStatus.isGranted) {
            manageStatus = await Permission.manageExternalStorage.request();
          }
          if (!manageStatus.isGranted && !status.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
      }

      final dir = Platform.isAndroid
          ? Directory('/storage/emulated/0/Download')
          : await getApplicationDocumentsDirectory();

      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final fileName = widget.url.split('/').last;
      final savePath = '${dir.path}/$fileName';

      await Dio().download(widget.url, savePath);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to $savePath')));

        final result = await OpenFile.open(savePath);
        if (result.type != ResultType.done) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open file: ${result.message}')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPdf = widget.url.toLowerCase().endsWith('.pdf');
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: _isDownloading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download),
            onPressed: _isDownloading ? null : _downloadToStorage,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: colorScheme.error),
              ),
            )
          : isPdf && _localFilePath != null
          ? PDFView(
              filePath: _localFilePath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: true,
              pageFling: true,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.description, size: 64, color: theme.disabledColor),
                  const SizedBox(height: 16),
                  Text(
                    isPdf
                        ? 'Could not load PDF'
                        : 'Preview not available for this file type.\nPlease download to view.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _downloadToStorage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    icon: const Icon(Icons.download),
                    label: const Text('Download File'),
                  ),
                ],
              ),
            ),
    );
  }
}
