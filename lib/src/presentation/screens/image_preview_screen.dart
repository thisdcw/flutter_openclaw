import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
              : Image.network(widget.imageUrl!),
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
}
