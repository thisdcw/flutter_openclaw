import 'package:flutter/material.dart';

class ChatMarkdownText extends StatelessWidget {
  const ChatMarkdownText({
    super.key,
    required this.text,
    required this.textColor,
    this.fontSize = 14,
  });

  final String text;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = _MarkdownParser(text).parse();
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < blocks.length; index++)
          Padding(
            padding: EdgeInsets.only(bottom: index == blocks.length - 1 ? 0 : 6),
            child: _MarkdownBlockView(
              block: blocks[index],
              textColor: textColor,
              theme: theme,
              fontSize: fontSize,
            ),
          ),
      ],
    );
  }
}

class _MarkdownBlockView extends StatelessWidget {
  const _MarkdownBlockView({
    required this.block,
    required this.textColor,
    required this.theme,
    required this.fontSize,
  });

  final _MarkdownBlock block;
  final Color textColor;
  final ThemeData theme;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    switch (block) {
      case _HeadingBlock():
        final heading = block as _HeadingBlock;
        final size = switch (heading.level) {
          1 => fontSize + 5,
          2 => fontSize + 3,
          3 => fontSize + 2,
          _ => fontSize + 1,
        };
        return SelectableText.rich(
          TextSpan(
            children: _buildInlineSpans(
              heading.text,
              textColor: textColor,
              theme: theme,
              baseStyle: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontSize: size,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
          ),
        );
      case _QuoteBlock():
        final quote = block as _QuoteBlock;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: textColor.withOpacity(0.28),
                width: 3,
              ),
            ),
          ),
          child: SelectableText.rich(
            TextSpan(
              children: _buildInlineSpans(
                quote.text,
                textColor: textColor,
                theme: theme,
                baseStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                ),
              ),
            ),
          ),
        );
      case _CodeBlock():
        final code = block as _CodeBlock;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: SelectableText(
            code.text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontFamily: 'monospace',
              height: 1.45,
            ),
          ),
        );
      case _ListBlock():
        final list = block as _ListBlock;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < list.items.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == list.items.length - 1 ? 0 : 4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        list.ordered ? '${index + 1}.' : '•',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText.rich(
                        TextSpan(
                          children: _buildInlineSpans(
                            list.items[index],
                            textColor: textColor,
                            theme: theme,
                            baseStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      case _ParagraphBlock():
        final paragraph = block as _ParagraphBlock;
        return SelectableText.rich(
          TextSpan(
            children: _buildInlineSpans(
              paragraph.text,
              textColor: textColor,
              theme: theme,
              baseStyle: theme.textTheme.bodyMedium?.copyWith(
                color: textColor,
                fontSize: fontSize,
                height: 1.45,
              ),
            ),
          ),
        );
    }
  }
}

List<InlineSpan> _buildInlineSpans(
  String text, {
  required Color textColor,
  required ThemeData theme,
  TextStyle? baseStyle,
}) {
  final effectiveStyle = baseStyle ??
      theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        height: 1.45,
      ) ??
      TextStyle(color: textColor, height: 1.45);
  final pattern = RegExp(
    r'(\[([^\]]+)\]\((https?:\/\/[^)]+)\))|(`([^`]+)`)|(\*\*([^*]+)\*\*)|(\*([^*]+)\*)|(https?:\/\/[^\s]+)',
  );
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in pattern.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    if (match.group(1) != null) {
      spans.add(
        TextSpan(
          text: match.group(2),
          style: effectiveStyle.copyWith(
            color: Colors.lightBlue.shade100,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    } else if (match.group(4) != null) {
      spans.add(
        TextSpan(
          text: match.group(4),
          style: effectiveStyle.copyWith(
            fontFamily: 'monospace',
            backgroundColor: Colors.black.withOpacity(0.08),
          ),
        ),
      );
    } else if (match.group(6) != null) {
      spans.add(
        TextSpan(
          text: match.group(6),
          style: effectiveStyle.copyWith(fontWeight: FontWeight.w700),
        ),
      );
    } else if (match.group(8) != null) {
      spans.add(
        TextSpan(
          text: match.group(8),
          style: effectiveStyle.copyWith(fontStyle: FontStyle.italic),
        ),
      );
    } else if (match.group(9) != null) {
      spans.add(
        TextSpan(
          text: match.group(9),
          style: effectiveStyle.copyWith(
            color: Colors.lightBlue.shade100,
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return spans;
}

sealed class _MarkdownBlock {
  const _MarkdownBlock();
}

class _HeadingBlock extends _MarkdownBlock {
  const _HeadingBlock({
    required this.level,
    required this.text,
  });

  final int level;
  final String text;
}

class _ParagraphBlock extends _MarkdownBlock {
  const _ParagraphBlock(this.text);

  final String text;
}

class _QuoteBlock extends _MarkdownBlock {
  const _QuoteBlock(this.text);

  final String text;
}

class _CodeBlock extends _MarkdownBlock {
  const _CodeBlock({
    required this.text,
    this.language,
  });

  final String text;
  final String? language;
}

class _ListBlock extends _MarkdownBlock {
  const _ListBlock({
    required this.items,
    required this.ordered,
  });

  final List<String> items;
  final bool ordered;
}

class _MarkdownParser {
  _MarkdownParser(this.source);

  final String source;

  List<_MarkdownBlock> parse() {
    final normalized = source.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return const <_MarkdownBlock>[];
    }
    final lines = normalized.split('\n');
    final blocks = <_MarkdownBlock>[];
    var index = 0;
    while (index < lines.length) {
      final line = lines[index];
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        index++;
        continue;
      }
      if (trimmed.startsWith('```')) {
        final language = trimmed.substring(3).trim();
        final buffer = <String>[];
        index++;
        while (index < lines.length && !lines[index].trim().startsWith('```')) {
          buffer.add(lines[index]);
          index++;
        }
        if (index < lines.length) {
          index++;
        }
        blocks.add(
          _CodeBlock(
            text: buffer.join('\n'),
            language: language.isEmpty ? null : language,
          ),
        );
        continue;
      }

      final headingMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmed);
      if (headingMatch != null) {
        blocks.add(
          _HeadingBlock(
            level: headingMatch.group(1)!.length,
            text: headingMatch.group(2)!.trim(),
          ),
        );
        index++;
        continue;
      }

      if (trimmed.startsWith('>')) {
        final buffer = <String>[];
        while (index < lines.length && lines[index].trim().startsWith('>')) {
          buffer.add(
            lines[index].trim().replaceFirst(RegExp(r'^>\s?'), ''),
          );
          index++;
        }
        blocks.add(_QuoteBlock(buffer.join('\n')));
        continue;
      }

      final unorderedMatch = RegExp(r'^[-*+]\s+').hasMatch(trimmed);
      final orderedMatch = RegExp(r'^\d+\.\s+').hasMatch(trimmed);
      if (unorderedMatch || orderedMatch) {
        final items = <String>[];
        while (index < lines.length) {
          final candidate = lines[index].trim();
          if (candidate.isEmpty) {
            break;
          }
          final matchesPattern = orderedMatch
              ? RegExp(r'^\d+\.\s+').hasMatch(candidate)
              : RegExp(r'^[-*+]\s+').hasMatch(candidate);
          if (!matchesPattern) {
            break;
          }
          items.add(
            candidate.replaceFirst(
              orderedMatch ? RegExp(r'^\d+\.\s+') : RegExp(r'^[-*+]\s+'),
              '',
            ),
          );
          index++;
        }
        blocks.add(_ListBlock(items: items, ordered: orderedMatch));
        continue;
      }

      final buffer = <String>[];
      while (index < lines.length) {
        final candidate = lines[index];
        final candidateTrimmed = candidate.trim();
        if (candidateTrimmed.isEmpty ||
            candidateTrimmed.startsWith('```') ||
            candidateTrimmed.startsWith('>') ||
            RegExp(r'^(#{1,6})\s+').hasMatch(candidateTrimmed) ||
            RegExp(r'^[-*+]\s+').hasMatch(candidateTrimmed) ||
            RegExp(r'^\d+\.\s+').hasMatch(candidateTrimmed)) {
          break;
        }
        buffer.add(candidate.trimRight());
        index++;
      }
      blocks.add(_ParagraphBlock(buffer.join('\n')));
    }
    return blocks;
  }
}
