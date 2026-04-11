sealed class MessageContentSegment {
  const MessageContentSegment();
}

class MessageTextSegment extends MessageContentSegment {
  const MessageTextSegment(this.text);

  final String text;

  @override
  bool operator ==(Object other) =>
      other is MessageTextSegment && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

class MessageImageSegment extends MessageContentSegment {
  const MessageImageSegment({
    required this.url,
    this.altText,
  });

  final String url;
  final String? altText;

  @override
  bool operator ==(Object other) =>
      other is MessageImageSegment &&
      other.url == url &&
      other.altText == altText;

  @override
  int get hashCode => Object.hash(url, altText);
}

List<MessageContentSegment> parseMessageContent(String input) {
  if (input.isEmpty) {
    return const <MessageContentSegment>[MessageTextSegment('')];
  }

  final matches = <_SegmentMatch>[];
  final markdownPattern = RegExp(r'!\[([^\]]*)\]\((https?:\/\/[^\s)]+)\)');
  final urlPattern = RegExp(r'https?:\/\/[^\s]+');

  for (final match in markdownPattern.allMatches(input)) {
    matches.add(
      _SegmentMatch(
        start: match.start,
        end: match.end,
        segment: MessageImageSegment(
          url: match.group(2)!,
          altText: match.group(1),
        ),
      ),
    );
  }

  for (final match in urlPattern.allMatches(input)) {
    final rawUrl = match.group(0)!;
    final cleanedUrl = _trimTrailingPunctuation(rawUrl);
    final effectiveEnd = match.start + cleanedUrl.length;
    final isCoveredByMarkdown = matches.any(
      (item) => match.start >= item.start && effectiveEnd <= item.end,
    );
    if (isCoveredByMarkdown || !_looksLikeImageUrl(cleanedUrl)) {
      continue;
    }
    matches.add(
      _SegmentMatch(
        start: match.start,
        end: effectiveEnd,
        segment: MessageImageSegment(url: cleanedUrl),
      ),
    );
  }

  if (matches.isEmpty) {
    return <MessageContentSegment>[MessageTextSegment(input)];
  }

  matches.sort((left, right) => left.start.compareTo(right.start));

  final segments = <MessageContentSegment>[];
  var cursor = 0;
  for (final match in matches) {
    if (match.start > cursor) {
      segments.add(MessageTextSegment(input.substring(cursor, match.start)));
    }
    segments.add(match.segment);
    cursor = match.end;
  }

  if (cursor < input.length) {
    segments.add(MessageTextSegment(input.substring(cursor)));
  }

  return segments;
}

String _trimTrailingPunctuation(String url) {
  var result = url;
  while (result.isNotEmpty &&
      const <String>{'.', ',', ';', '!', '?', ')'}
          .contains(result.substring(result.length - 1))) {
    result = result.substring(0, result.length - 1);
  }
  return result;
}

bool _looksLikeImageUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasAuthority) {
    return false;
  }

  final host = uri.host.toLowerCase();
  if (host == 'image.pollinations.ai') {
    return true;
  }

  final path = uri.path.toLowerCase();
  return path.endsWith('.png') ||
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.gif') ||
      path.endsWith('.webp') ||
      path.endsWith('.bmp') ||
      path.endsWith('.svg');
}

class _SegmentMatch {
  const _SegmentMatch({
    required this.start,
    required this.end,
    required this.segment,
  });

  final int start;
  final int end;
  final MessageImageSegment segment;
}
