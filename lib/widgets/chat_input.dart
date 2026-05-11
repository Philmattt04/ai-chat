import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../models/message.dart';

class ChatInput extends StatefulWidget {
  final Function(String text, Attachment? attachment) onSubmit;
  final bool loading;

  const ChatInput({super.key, required this.onSubmit, required this.loading});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  bool _hasText = false;
  Attachment? _attachment;
  bool _pickingFile = false;

  // File types the picker will accept
  static const _allowedExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'webp',   // images
    'pdf',                                   // PDF documents
    'txt', 'md', 'csv', 'json',             // plain text
    'dart', 'py', 'js', 'ts', 'tsx', 'jsx', // code
    'swift', 'kt', 'java', 'go', 'rs', 'c', 'cpp', 'h',
  ];

  static const _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    setState(() => _pickingFile = true);
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      if (bytes.length > _maxFileSizeBytes) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File must be under 10 MB')),
          );
        }
        return;
      }

      final ext = (file.extension ?? '').toLowerCase();
      final mediaType = _mediaTypeFromExtension(ext);

      setState(() {
        _attachment = Attachment(
          filename: file.name,
          mediaType: mediaType,
          base64Data: base64Encode(bytes),
          kind: Attachment.kindFromMediaType(mediaType),
        );
      });
    } finally {
      if (mounted) setState(() => _pickingFile = false);
    }
  }

  String _mediaTypeFromExtension(String ext) {
    const map = {
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg',
      'png': 'image/png', 'gif': 'image/gif', 'webp': 'image/webp',
      'pdf': 'application/pdf',
    };
    return map[ext] ?? 'text/plain';
  }

  void _removeAttachment() => setState(() => _attachment = null);

  void _submit() {
    final text = _ctrl.text.trim();
    if ((text.isEmpty && _attachment == null) || widget.loading) return;
    final attachment = _attachment;
    _ctrl.clear();
    setState(() => _attachment = null);
    widget.onSubmit(text, attachment);
  }

  bool get _canSend =>
      (_hasText || _attachment != null) && !widget.loading && !_pickingFile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0f0f0f) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : const Color(0xFFe5e7eb),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attachment preview chip
          if (_attachment != null)
            _AttachmentChip(
              attachment: _attachment!,
              onRemove: _removeAttachment,
              isDark: isDark,
            ),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // File picker button
              _IconBtn(
                icon: _pickingFile
                    ? Icons.hourglass_empty_rounded
                    : Icons.attach_file_rounded,
                onTap: widget.loading ? null : _pickFile,
                isDark: isDark,
                tooltip: 'Attach file',
              ),
              const SizedBox(width: 6),

              // Text input
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1a1a2e)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFe5e7eb),
                    ),
                  ),
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.enter): _submit,
                    },
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      maxLines: 6,
                      minLines: 1,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xFFe5e7eb)
                            : const Color(0xFF1f2937),
                      ),
                      decoration: InputDecoration(
                        hintText: _attachment != null
                            ? 'Add a message… (optional)'
                            : 'Message Vox AI… (Enter to send)',
                        hintStyle: TextStyle(
                          color: isDark
                              ? const Color(0xFF4b5563)
                              : const Color(0xFF9ca3af),
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              AnimatedOpacity(
                opacity: _canSend ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 150),
                child: GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4f46e5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: widget.loading
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.arrow_upward_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Small icon button used in the input row
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isDark;
  final String tooltip;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.isDark,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFe5e7eb),
            ),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isDark
                ? const Color(0xFF6b7280)
                : const Color(0xFF9ca3af),
          ),
        ),
      ),
    );
  }
}

// Preview chip shown above the input when a file is attached
class _AttachmentChip extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onRemove;
  final bool isDark;

  const _AttachmentChip({
    required this.attachment,
    required this.onRemove,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1e1e2e)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFe5e7eb),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (attachment.kind == AttachmentKind.image)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                attachment.bytes,
                width: 24,
                height: 24,
                fit: BoxFit.cover,
              ),
            )
          else
            Icon(
              attachment.kind == AttachmentKind.pdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.insert_drive_file_rounded,
              size: 16,
              color: isDark
                  ? const Color(0xFF9ca3af)
                  : const Color(0xFF6b7280),
            ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              attachment.filename,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFFd1d5db)
                    : const Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: isDark
                  ? const Color(0xFF6b7280)
                  : const Color(0xFF9ca3af),
            ),
          ),
        ],
      ),
    );
  }
}
