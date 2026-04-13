import 'package:flutter/material.dart';

class BootstrapImportSheet extends StatefulWidget {
  const BootstrapImportSheet({
    super.key,
    required this.onSubmit,
  });

  final ValueChanged<String> onSubmit;

  @override
  State<BootstrapImportSheet> createState() => _BootstrapImportSheetState();
}

class _BootstrapImportSheetState extends State<BootstrapImportSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '导入配对码',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: '粘贴扫码内容或 bootstrap token',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSubmit(_controller.text),
              child: const Text('导入'),
            ),
          ),
        ],
      ),
    );
  }
}
