import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BootstrapScanScreen extends StatefulWidget {
  const BootstrapScanScreen({
    super.key,
    required this.onScanned,
  });

  final ValueChanged<String> onScanned;

  @override
  State<BootstrapScanScreen> createState() => _BootstrapScanScreenState();
}

class _BootstrapScanScreenState extends State<BootstrapScanScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描配对二维码'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) {
            return;
          }
          final barcode = capture.barcodes.isNotEmpty
              ? capture.barcodes.first
              : null;
          final rawValue = barcode?.rawValue;
          if (rawValue == null || rawValue.trim().isEmpty) {
            return;
          }
          _handled = true;
          widget.onScanned(rawValue);
          Navigator.of(context).maybePop();
        },
      ),
    );
  }
}
