import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';

class ClaudeService {
  // Relative URL — works on Netlify since the function lives on the same origin.
  // For local dev run `netlify dev` (port 8888) or point to your deployed URL.
  static const String _apiUrl = '/.netlify/functions/chat';

  static Future<({String content, int inputTokens, int outputTokens})> sendMessage({
    required List<Message> history,
    required String userMessage,
    required String personaId,
    required String model,
  }) async {
    // Build the messages array for the API (exclude any loading placeholders)
    final messages = [
      ...history.map((m) => m.toApi()),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http
        .post(
          Uri.parse(_apiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'messages': messages,
            'persona': personaId,
            'model': model,
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
