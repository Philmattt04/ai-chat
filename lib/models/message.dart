enum MessageRole { user, assistant }

class Message {
  final MessageRole role;
  final String content;
  final int? inputTokens;
  final int? outputTokens;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    this.inputTokens,
    this.outputTokens,
  }) : timestamp = DateTime.now();

  Map<String, String> toApi() => {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': content,
      };
}

// Preset personas sent as the system prompt to Claude
class Persona {
  final String id;
  final String emoji;
  final String label;
  final String? systemPrompt;

  const Persona({
    required this.id,
    required this.emoji,
    required this.label,
    this.systemPrompt,
  });

  static const List<Persona> all = [
    Persona(
      id: 'assistant',
      emoji: '🤖',
      label: 'Assistant',
      systemPrompt: null,
    ),
    Persona(
      id: 'coder',
      emoji: '💻',
      label: 'Coder',
      systemPrompt:
          'You are an expert software engineer with deep knowledge across many languages and frameworks. '
          'Give concise, correct, idiomatic code. Always explain the key decision or trade-off briefly.',
    ),
    Persona(
      id: 'writer',
      emoji: '✍️',
      label: 'Writer',
      systemPrompt:
          'You are a sharp writing editor. Cut filler, prefer active voice, and make every sentence earn its place. '
          'Give direct feedback. Show, don\'t tell.',
    ),
    Persona(
      id: 'tutor',
      emoji: '🧠',
      label: 'Tutor',
      systemPrompt:
          'You are a Socratic tutor. Never give the answer directly. '
          'Ask one clear, well-chosen question that nudges the student toward the insight themselves.',
    ),
  ];
}
