import 'dart:convert';
import 'dart:typed_data';

enum MessageRole { user, assistant }

enum AttachmentKind { image, pdf, text }

class Attachment {
  final String filename;
  final String mediaType;
  final String base64Data;
  final AttachmentKind kind;

  const Attachment({
    required this.filename,
    required this.mediaType,
    required this.base64Data,
    required this.kind,
  });

  // Decoded bytes — used for image previews in the message bubble
  Uint8List get bytes => base64Decode(base64Data);

  static AttachmentKind kindFromMediaType(String mediaType) {
    if (mediaType.startsWith('image/')) return AttachmentKind.image;
    if (mediaType == 'application/pdf') return AttachmentKind.pdf;
    return AttachmentKind.text;
  }

  Map<String, dynamic> toJson() => {
        'filename': filename,
        'mediaType': mediaType,
        'base64Data': base64Data,
        'kind': kind.name,
      };
}

class Message {
  final MessageRole role;
  final String content;
  final Attachment? attachment;
  final int? inputTokens;
  final int? outputTokens;
  final DateTime timestamp;

  Message({
    required this.role,
    required this.content,
    this.attachment,
    this.inputTokens,
    this.outputTokens,
  }) : timestamp = DateTime.now();

  // Plain-text representation for history — attachments only apply to the
  // message being sent, not prior turns, so history is always text-only.
  Map<String, String> toApi() => {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': content,
      };
}

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
