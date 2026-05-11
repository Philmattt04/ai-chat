import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/message.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    final isUser = widget.message.role == MessageRole.user;
    _slide = Tween<Offset>(
      begin: Offset(isUser ? 0.06 : -0.06, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _copyContent() async {
    await Clipboard.setData(ClipboardData(text: widget.message.content));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                // Claude avatar
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF4f46e5).withValues(alpha: 0.2)
                        : const Color(0xFFede9fe),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('✨', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
              Flexible(
                child: GestureDetector(
                  onLongPress: _copyContent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 560),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF4f46e5)
                          : isDark
                              ? const Color(0xFF1e1e2e)
                              : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isUser ? 18 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: isUser
                              ? Text(
                                  widget.message.content,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 14, height: 1.5),
                                )
                              : MarkdownBody(
                                  data: widget.message.content,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: isDark
                                          ? const Color(0xFFd1d5db)
                                          : const Color(0xFF1f2937),
                                    ),
                                    code: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 13,
                                      backgroundColor: isDark
                                          ? const Color(0xFF2d2d3f)
                                          : const Color(0xFFe5e7eb),
                                      color: isDark
                                          ? const Color(0xFFa5b4fc)
                                          : const Color(0xFF4f46e5),
                                    ),
                                    codeblockDecoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF151521)
                                          : const Color(0xFFf3f4f6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    blockquoteDecoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF4f46e5)
                                              : const Color(0xFF6366f1),
                                          width: 3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        // Token count + copy hint for assistant messages
                        if (!isUser &&
                            widget.message.outputTokens != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 14, right: 10, bottom: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${widget.message.outputTokens} tokens',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? const Color(0xFF6b7280)
                                        : const Color(0xFF9ca3af),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: _copyContent,
                                  child: Text(
                                    _copied ? 'Copied!' : 'Copy',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _copied
                                          ? const Color(0xFF34d399)
                                          : isDark
                                              ? const Color(0xFF6b7280)
                                              : const Color(0xFF9ca3af),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Animated typing indicator shown while Claude is responding
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF4f46e5).withValues(alpha: 0.2)
                  : const Color(0xFFede9fe),
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('✨', style: TextStyle(fontSize: 13))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1e1e2e) : const Color(0xFFF3F4F6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, __) {
                    final offset = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
                    final opacity = (0.3 + 0.7 * (1 - (offset - 0.5).abs() * 2)).clamp(0.3, 1.0);
                    return Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2.5),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? const Color(0xFF6b7280)
                                : const Color(0xFF9ca3af))
                            .withValues(alpha: opacity),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
