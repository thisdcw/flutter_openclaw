enum ChatCommandHintKind {
  none,
  standaloneGateway,
  inlineDirective,
  standaloneRecommended,
  localCommand,
}

class ChatCommandSuggestion {
  const ChatCommandSuggestion({
    required this.command,
    required this.descriptionKey,
    required this.groupKey,
    this.templateSuffix,
    this.isDiscovery = false,
  });

  final String command;
  final String descriptionKey;
  final String groupKey;
  final String? templateSuffix;
  final bool isDiscovery;

  String get template => '$command${templateSuffix ?? ''}';
}

class ChatCommandAssistResult {
  const ChatCommandAssistResult({
    required this.hintKind,
    this.matchedCommand,
    this.containsInlineDirective = false,
  });

  final ChatCommandHintKind hintKind;
  final String? matchedCommand;
  final bool containsInlineDirective;
}

List<ChatCommandSuggestion> filterSlashSuggestions(String query) {
  final trimmed = query.trim();
  if (!trimmed.startsWith('/')) {
    return slashSuggestionCandidates;
  }

  final lower = trimmed.toLowerCase();
  return slashSuggestionCandidates
      .where((suggestion) => suggestion.command.startsWith(lower))
      .toList();
}

final List<ChatCommandSuggestion> discoveryCommands = const [
  ChatCommandSuggestion(
    command: '/new',
    descriptionKey: 'commandDescriptionNew',
    groupKey: 'commandGroupSessionLabel',
    isDiscovery: true,
  ),
  ChatCommandSuggestion(
    command: '/status',
    descriptionKey: 'commandDescriptionStatus',
    groupKey: 'commandGroupStatusLabel',
    isDiscovery: true,
  ),
  ChatCommandSuggestion(
    command: '/model',
    descriptionKey: 'commandDescriptionModel',
    groupKey: 'commandGroupSettingsLabel',
    templateSuffix: ' ',
    isDiscovery: true,
  ),
  ChatCommandSuggestion(
    command: '/think',
    descriptionKey: 'commandDescriptionThink',
    groupKey: 'commandGroupSettingsLabel',
    templateSuffix: ' ',
    isDiscovery: true,
  ),
  ChatCommandSuggestion(
    command: '/help',
    descriptionKey: 'commandDescriptionHelp',
    groupKey: 'commandGroupStatusLabel',
    isDiscovery: true,
  ),
];

final List<ChatCommandSuggestion> slashSuggestionCandidates = const [
  ChatCommandSuggestion(
    command: '/new',
    descriptionKey: 'commandDescriptionNew',
    groupKey: 'commandGroupSessionLabel',
  ),
  ChatCommandSuggestion(
    command: '/reset',
    descriptionKey: 'commandDescriptionReset',
    groupKey: 'commandGroupSessionLabel',
  ),
  ChatCommandSuggestion(
    command: '/compact',
    descriptionKey: 'commandDescriptionCompact',
    groupKey: 'commandGroupSessionLabel',
  ),
  ChatCommandSuggestion(
    command: '/stop',
    descriptionKey: 'commandDescriptionStop',
    groupKey: 'commandGroupSessionLabel',
  ),
  ChatCommandSuggestion(
    command: '/status',
    descriptionKey: 'commandDescriptionStatus',
    groupKey: 'commandGroupStatusLabel',
  ),
  ChatCommandSuggestion(
    command: '/help',
    descriptionKey: 'commandDescriptionHelp',
    groupKey: 'commandGroupStatusLabel',
  ),
  ChatCommandSuggestion(
    command: '/model',
    templateSuffix: ' ',
    descriptionKey: 'commandDescriptionModel',
    groupKey: 'commandGroupSettingsLabel',
  ),
  ChatCommandSuggestion(
    command: '/think',
    templateSuffix: ' ',
    descriptionKey: 'commandDescriptionThink',
    groupKey: 'commandGroupSettingsLabel',
  ),
  ChatCommandSuggestion(
    command: '/fast',
    descriptionKey: 'commandDescriptionFast',
    groupKey: 'commandGroupSettingsLabel',
  ),
];

ChatCommandAssistResult analyzeChatDraft(String draft) {
  final trimmed = draft.trim();
  if (trimmed.isEmpty) {
    return const ChatCommandAssistResult(hintKind: ChatCommandHintKind.none);
  }

  if (_isLocalClear(trimmed)) {
    return const ChatCommandAssistResult(
      hintKind: ChatCommandHintKind.localCommand,
      matchedCommand: '/clear',
    );
  }

  final standaloneMatch = _matchCommandAtStart(trimmed);
  if (standaloneMatch != null && _standaloneCommands.contains(standaloneMatch.command)) {
    return ChatCommandAssistResult(
      hintKind: ChatCommandHintKind.standaloneGateway,
      matchedCommand: standaloneMatch.command,
    );
  }

  final directiveMatch = _firstCommandMatch(trimmed, _inlineDirectiveCommands);
  if (directiveMatch != null) {
    return ChatCommandAssistResult(
      hintKind: ChatCommandHintKind.inlineDirective,
      matchedCommand: directiveMatch.command,
      containsInlineDirective: true,
    );
  }

  final inlineStandaloneMatch = _firstCommandMatch(trimmed, _standaloneRecommendedCommands);
  if (inlineStandaloneMatch != null) {
    final before = trimmed.substring(0, inlineStandaloneMatch.start).trim();
    final after = trimmed.substring(inlineStandaloneMatch.end).trim();
    if (before.isNotEmpty || after.isNotEmpty) {
      return ChatCommandAssistResult(
        hintKind: ChatCommandHintKind.standaloneRecommended,
        matchedCommand: inlineStandaloneMatch.command,
      );
    }
  }

  return const ChatCommandAssistResult(hintKind: ChatCommandHintKind.none);
}

bool _isLocalClear(String trimmed) {
  return trimmed.toLowerCase() == '/clear';
}

final RegExp _commandPattern = RegExp(r'/[A-Za-z]+', caseSensitive: false);

_CommandMatch? _matchCommandAtStart(String text) {
  final match = _commandPattern.matchAsPrefix(text);
  if (match == null || !_hasCommandBoundary(text, match.start, match.end)) {
    return null;
  }
  final command = _normalizeCommand(match.group(0)!);
  return _CommandMatch(command, match.start, match.end);
}

_CommandMatch? _firstCommandMatch(String text, Set<String> candidates) {
  for (final match in _commandPattern.allMatches(text)) {
    if (!_hasCommandBoundary(text, match.start, match.end)) {
      continue;
    }
    final command = _normalizeCommand(match.group(0)!);
    if (candidates.contains(command)) {
      return _CommandMatch(command, match.start, match.end);
    }
  }
  return null;
}

bool _hasCommandBoundary(String text, int start, int end) {
  final hasValidLeadingBoundary =
      start == 0 || text[start - 1].trim().isEmpty;
  final hasValidTrailingBoundary =
      end == text.length ||
      text[end] == ':' ||
      text[end].trim().isEmpty;
  return hasValidLeadingBoundary && hasValidTrailingBoundary;
}

String _normalizeCommand(String raw) {
  final lower = raw.toLowerCase();
  return _commandAlias[lower] ?? lower;
}

const Set<String> _standaloneCommands = {
  '/new',
  '/reset',
  '/compact',
  '/stop',
  '/status',
  '/help',
  '/model',
  '/think',
  '/fast',
};

const Set<String> _inlineDirectiveCommands = {
  '/think',
  '/fast',
  '/verbose',
  '/reasoning',
  '/model',
  '/queue',
  '/elevated',
  '/exec',
};

const Set<String> _standaloneRecommendedCommands = {
  '/new',
  '/reset',
  '/compact',
  '/stop',
};

const Map<String, String> _commandAlias = {
  '/t': '/think',
  '/thinking': '/think',
  '/reason': '/reasoning',
  '/v': '/verbose',
};

class _CommandMatch {
  const _CommandMatch(this.command, this.start, this.end);
  final String command;
  final int start;
  final int end;
}
