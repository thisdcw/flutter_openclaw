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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: theme.colorScheme.outline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120E1A2B),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled && !isSending,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Message OpenClaw',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: enabled && !isSending
                ? () {
                    onSend();
                  }
                : null,
            icon: const Icon(Icons.arrow_upward_rounded),
            label: Text(isSending ? 'Sending' : 'Send'),
          ),
        ],
      ),
    );
  }
}
