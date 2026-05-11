import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ClaudeService {
  static const String _apiUrl = '/.netlify/functions/chat';

  static Future<({String content, int inputTokens, int outputTokens})> sendMessage({
    required List<Message> history,
    required String userMessage,
    required String personaId,
    required String model,
    Attachment? attachment,
  }) async {
    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            // Prior turns as plain text — attachments only apply to the current message
            'history': history.map((m) => m.toApi()).toList(),
            'userMessage': userMessage,
            'persona': personaId,
            'model': model,
            // Attachment is sent separately; the Netlify function builds the content blocks
            if (attachment != null) 'attachment': attachment.toJson(),
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (
        content: data['content'] as String,
        inputTokens: (data['inputTokens'] as num).toInt(),
        outputTokens: (data['outputTokens'] as num).toInt(),
      );
    } else {
      String errorMessage;
      try {
        final error = jsonDecode(response.body) as Map<String, dynamic>;
        errorMessage = error['error'] as String? ?? 'Request failed (${response.statusCode})';
      } catch (_) {
        errorMessage = 'Request failed (${response.statusCode})';
      }
      throw Exception(errorMessage);
    }
  }
}
