import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' show NetworkImageLoadException;
import 'package:flutter/services.dart';

import '../../infrastructure/platform/image_save_service.dart';

class ImagePreviewScreen extends StatefulWidget {
  const ImagePreviewScreen.memory({
    super.key,
    required Uint8List bytes,
    required this.fileName,
    required this.mimeType,
  })  : bytes = bytes,
        imageUrl = null;

  const ImagePreviewScreen.network({
    super.key,
    required this.imageUrl,
    required this.fileName,
    required this.mimeType,
  }) : bytes = null;

  final Uint8List? bytes;
  final String? imageUrl;
  final String fileName;
  final String mimeType;

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final ImageSaveService _imageSaveService = ImageSaveService();
  bool _isSaving = false;
  int _reloadVersion = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.fileName),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveImage,
            icon: Icon(
              _isSaving ? Icons.downloading_rounded : Icons.download_rounded,
            ),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: widget.bytes != null
              ? Image.memory(widget.bytes!)
              : Image.network(
                  widget.imageUrl!,
                  key: ValueKey<String>(
                    'network-preview-${widget.imageUrl!}-$_reloadVersion',
                  ),
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _NetworkImageFallback(
                      message: _friendlyImageError(error),
                      onRetry: () {
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _reloadVersion++;
                        });
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _saveImage() async {
    setState(() {
      _isSaving = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = widget.bytes ?? await _downloadImage(widget.imageUrl!);
      await _imageSaveService.saveImage(
        bytes: bytes,
        fileName: widget.fileName,
        mimeType: widget.mimeType,
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Image saved')),
      );
    } on ImageSaveException catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Saving image failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<Uint8List> _downloadImage(String imageUrl) async {
    final bundle = NetworkAssetBundle(Uri.parse(imageUrl));
    final data = await bundle.load(imageUrl);
    return data.buffer.asUint8List();
  }

  String _friendlyImageError(Object error) {
    if (error is NetworkImageLoadException) {
      if (error.statusCode == 429) {
        return '图片服务限流（HTTP 429），请稍后重试。';
      }
      return '图片加载失败（HTTP ${error.statusCode}）。';
    }
    return '图片加载失败，请重试。';
  }
}

class _NetworkImageFallback extends StatelessWidget {
  const _NetworkImageFallback({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.image_not_supported_outlined,
              color: Colors.white70,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试加载'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withOpacity(0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
