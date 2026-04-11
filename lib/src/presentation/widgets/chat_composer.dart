import 'package:flutter/material.dart';

class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isSending;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled && !isSending,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Ask OpenClaw...',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: enabled && !isSending
              ? () {
                  onSend();
                }
              : null,
          child: Text(isSending ? 'Sending...' : 'Send'),
        ),
      ],
    );
  }
}
