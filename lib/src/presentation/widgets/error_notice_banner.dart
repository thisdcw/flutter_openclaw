import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../application/models/app_error_notice.dart';
import '../localization/localized_app_error_text.dart';

class ErrorNoticeBanner extends StatefulWidget {
  const ErrorNoticeBanner({
    super.key,
    required this.notice,
  });

  final AppErrorNotice notice;

  @override
  State<ErrorNoticeBanner> createState() => _ErrorNoticeBannerState();
}

class _ErrorNoticeBannerState extends State<ErrorNoticeBanner> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localized = localizeAppErrorText(context, widget.notice);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localized.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (localized.hint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              localized.hint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
          if (widget.notice.hasTechnicalDetails) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    side: BorderSide(
                      color: theme.colorScheme.onErrorContainer.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    _expanded
                        ? localized.hideDetailsLabel
                        : localized.detailsLabel,
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: widget.notice.technicalDetails),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    if (messenger == null) {
                      return;
                    }
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(localized.copiedLabel),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    side: BorderSide(
                      color: theme.colorScheme.onErrorContainer.withOpacity(0.5),
                    ),
                  ),
                  child: Text(localized.copyErrorLabel),
                ),
              ],
            ),
          ],
          if (_expanded && widget.notice.hasTechnicalDetails) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onErrorContainer.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: SelectableText(
                widget.notice.technicalDetails,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
