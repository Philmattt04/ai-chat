import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/claude_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/persona_selector.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  const ChatScreen({
    super.key,
    required this.onToggleTheme,
    required this.themeMode,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final _scrollCtrl = ScrollController();
  bool _loading = false;
  String _error = '';
  String _persona = 'assistant';
  String _model = 'claude-sonnet-4-6';

  int get _totalInputTokens =>
      _messages.fold(0, (sum, m) => sum + (m.inputTokens ?? 0));
  int get _totalOutputTokens =>
      _messages.fold(0, (sum, m) => sum + (m.outputTokens ?? 0));

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    setState(() {
      _loading = true;
      _error = '';
    });
    _scrollToBottom();

    try {
      final result = await ClaudeService.sendMessage(
        history: _messages,
        userMessage: text,
        personaId: _persona,
        model: _model,
      );

      setState(() {
        // Add user message (with input token count)
        _messages.add(Message(
          role: MessageRole.user,
          content: text,
          inputTokens: result.inputTokens,
        ));
        // Add Claude response
        _messages.add(Message(
          role: MessageRole.assistant,
          content: result.content,
          outputTokens: result.outputTokens,
        ));
        _loading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _error = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;
    final bgColor = isDark ? const Color(0xFF0f0f0f) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF4f46e5).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                  child: Text('✨', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 10),
            Text(
              'AI Chat',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            if (_totalOutputTokens > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_totalInputTokens}↑ ${_totalOutputTokens}↓',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: isDark
                        ? const Color(0xFF6b7280)
                        : const Color(0xFF9ca3af),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Model toggle
          GestureDetector(
            onTap: () => setState(() {
              _model = _model == 'claude-sonnet-4-6'
                  ? 'claude-haiku-4-5-20251001'
                  : 'claude-sonnet-4-6';
            }),
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFe5e7eb),
                ),
              ),
              child: Text(
                _model.contains('haiku') ? 'Haiku' : 'Sonnet',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF9ca3af)
                      : const Color(0xFF6b7280),
                ),
              ),
            ),
          ),
          // Clear chat
          if (_messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded,
                  size: 19,
                  color: isDark
                      ? const Color(0xFF6b7280)
                      : const Color(0xFF9ca3af)),
              tooltip: 'Clear chat',
              onPressed: _clearChat,
            ),
          // Theme toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 19,
              color: isDark
                  ? const Color(0xFF6b7280)
                  : const Color(0xFF9ca3af),
            ),
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(54),
          child: Column(
            children: [
              Divider(
                height: 1,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.07)
                    : const Color(0xFFe5e7eb),
              ),
              const SizedBox(height: 8),
              PersonaSelector(
                selected: _persona,
                onSelect: (id) => setState(() => _persona = id),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty && !_loading
                ? _EmptyState(isDark: isDark)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    itemCount: _messages.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _messages.length) {
                        return const TypingIndicator();
                      }
                      return MessageBubble(message: _messages[i]);
                    },
                  ),
          ),
          if (_error.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF7f1d1d).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color:
                        const Color(0xFFef4444).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFFfca5a5)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _error = ''),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: Color(0xFFfca5a5)),
                  ),
                ],
              ),
            ),
          ChatInput(onSubmit: _sendMessage, loading: _loading),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✨',
              style: TextStyle(
                  fontSize: 40,
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFd1d5db))),
          const SizedBox(height: 12),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? const Color(0xFF4b5563)
                  : const Color(0xFF9ca3af),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a persona above and send your first message.',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? const Color(0xFF374151)
                  : const Color(0xFFd1d5db),
            ),
          ),
        ],
      ),
    );
  }
}
