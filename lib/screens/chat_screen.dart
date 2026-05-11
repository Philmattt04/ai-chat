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
  // Each persona keeps its own independent conversation history
  final Map<String, List<Message>> _chats = {};
  List<Message> get _currentChat => _chats[_persona] ??= [];

  final _scrollCtrl = ScrollController();
  bool _loading = false;
  String _error = '';
  String _persona = 'assistant';
  String _model = 'claude-sonnet-4-6';

  int get _totalInputTokens =>
      _currentChat.fold(0, (sum, m) => sum + (m.inputTokens ?? 0));
  int get _totalOutputTokens =>
      _currentChat.fold(0, (sum, m) => sum + (m.outputTokens ?? 0));

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

  Future<void> _sendMessage(String text, Attachment? attachment) async {
    setState(() {
      _loading = true;
      _error = '';
    });
    _scrollToBottom();

    try {
      final result = await ClaudeService.sendMessage(
        history: _currentChat,
        userMessage: text,
        personaId: _persona,
        model: _model,
        attachment: attachment,
      );

      setState(() {
        _currentChat.add(Message(
          role: MessageRole.user,
          content: text,
          attachment: attachment,
          inputTokens: result.inputTokens,
        ));
        _currentChat.add(Message(
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
      _currentChat.clear();
      _error = '';
    });
  }

  void _switchPersona(String id) {
    setState(() {
      _persona = id;
      _error = '';
    });
    // Scroll to bottom of the newly selected persona's chat
    _scrollToBottom();
  }

  void _showTokenUsage(BuildContext context) {
    final isDark = widget.themeMode == ThemeMode.dark;
    final total = _totalInputTokens + _totalOutputTokens;

    // Approximate cost per million tokens (USD)
    final isHaiku = _model.contains('haiku');
    final inputRate  = isHaiku ? 0.80 : 3.00;
    final outputRate = isHaiku ? 4.00 : 15.00;
    final cost = (_totalInputTokens  / 1_000_000 * inputRate) +
                 (_totalOutputTokens / 1_000_000 * outputRate);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : const Color(0xFFe5e7eb),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Token Usage',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_model.contains('haiku') ? 'Claude Haiku' : 'Claude Sonnet'}  ·  this session',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF6b7280)
                    : const Color(0xFF9ca3af),
              ),
            ),
            const SizedBox(height: 20),
            _TokenRow(
              label: 'Input',
              sublabel: 'tokens sent',
              value: _totalInputTokens,
              color: const Color(0xFF6366f1),
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _TokenRow(
              label: 'Output',
              sublabel: 'tokens received',
              value: _totalOutputTokens,
              color: const Color(0xFF34d399),
              isDark: isDark,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFe5e7eb),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111827),
                  ),
                ),
                Text(
                  '$total tokens',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4f46e5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Estimated cost',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xFF6b7280)
                        : const Color(0xFF9ca3af),
                  ),
                ),
                Text(
                  total == 0 ? r'$0.00' : '\$${cost.toStringAsFixed(5)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: isDark
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF6b7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
              'Vox AI',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF111827),
              ),
            ),
          ],
        ),
        actions: [
          // Token usage button
          if (_totalOutputTokens > 0)
            GestureDetector(
              onTap: () => _showTokenUsage(context),
              child: Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4f46e5).withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4f46e5).withValues(alpha: isDark ? 0.3 : 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      '${_totalInputTokens + _totalOutputTokens}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF818cf8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
          if (_currentChat.isNotEmpty)
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
                onSelect: _switchPersona,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentChat.isEmpty && !_loading
                ? _EmptyState(isDark: isDark, persona: _persona)
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    itemCount: _currentChat.length + (_loading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _currentChat.length) {
                        return const TypingIndicator();
                      }
                      return MessageBubble(message: _currentChat[i]);
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

class _TokenRow extends StatelessWidget {
  final String label;
  final String sublabel;
  final int value;
  final Color color;
  final bool isDark;

  const _TokenRow({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label  ·  $sublabel',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
            ),
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFe5e7eb) : const Color(0xFF1f2937),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final String persona;
  const _EmptyState({required this.isDark, required this.persona});

  @override
  Widget build(BuildContext context) {
    final p = Persona.all.firstWhere((p) => p.id == persona,
        orElse: () => Persona.all.first);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(p.emoji,
              style: TextStyle(
                  fontSize: 40,
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFd1d5db))),
          const SizedBox(height: 12),
          Text(
            p.label,
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
            'No messages yet. Send one to start.',
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
