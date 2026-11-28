import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/models/doca_models.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/chat_file_helper.dart';
import '../../../home/presentation/widgets/full_screen_photo_viewer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.conversationId,
    required this.otherAlias,
    super.key,
  });

  final String conversationId;
  final String otherAlias;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const int _maxAttachmentBytes = 5 * 1024 * 1024; // 5 MB

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _inputFocusNode = FocusNode();
  final _imagePicker = ImagePicker();

  Timer? _pollTimer;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isPolling = false;
  bool _isSending = false;

  ChatMessage? _editingMessage;
  _PendingAttachment? _pendingAttachment;

  @override
  void initState() {
    super.initState();
    _loadMessages(showLoader: true);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollMessages(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return (pos.maxScrollExtent - pos.pixels) < 120;
  }

  String _listSignature(List<ChatMessage> list) {
    return list
        .map(
          (m) =>
              '${m.id}|${m.body}|${m.isEdited}|${m.isDeleted}|${m.deliveredAt?.millisecondsSinceEpoch ?? 0}|${m.seenAt?.millisecondsSinceEpoch ?? 0}',
        )
        .join(';;');
  }

  Future<void> _loadMessages({bool showLoader = false}) async {
    if (showLoader) {
      setState(() => _isLoading = true);
    }
    try {
      final raw = await ApiService.instance.getMessages(widget.conversationId);
      final parsed = raw
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() {
        _messages = parsed;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load chat: $e')),
      );
    }
  }

  Future<void> _pollMessages() async {
    if (_isPolling || _isLoading || _isSending || !mounted) return;
    _isPolling = true;
    try {
      final wasNearBottom = _isNearBottom();
      final oldLen = _messages.length;
      final oldSig = _listSignature(_messages);

      final raw = await ApiService.instance.getMessages(widget.conversationId);
      final parsed = raw
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      final newSig = _listSignature(parsed);
      if (newSig != oldSig) {
        setState(() => _messages = parsed);
        if (parsed.length > oldLen && wasNearBottom) {
          _scrollToBottom(animate: true);
        }
      }
    } catch (_) {
      // Silent poll failure — never spam snackbars
    } finally {
      _isPolling = false;
    }
  }

  Future<void> _sendOrSaveEdit() async {
    final text = _messageController.text.trim();
    if (_isSending) return;

    // 1. Save edit mode
    if (_editingMessage != null) {
      final target = _editingMessage!;
      if (text.isEmpty && target.attachment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message cannot be empty.')),
        );
        return;
      }

      setState(() => _isSending = true);
      try {
        final res = await ApiService.instance.editMessage(target.id, text);
        final updated = ChatMessage.fromJson(
          res['message'] as Map<String, dynamic>,
        );
        if (!mounted) return;
        setState(() {
          _messages =
              _messages.map((m) => m.id == updated.id ? updated : m).toList();
          _editingMessage = null;
          _messageController.clear();
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit failed: $e')),
        );
      } finally {
        if (mounted) setState(() => _isSending = false);
      }
      return;
    }

    // 2. Send new message (text and/or photo/PDF attachment)
    final attachment = _pendingAttachment;
    if (text.isEmpty && attachment == null) return;

    setState(() => _isSending = true);
    try {
      Map<String, dynamic>? attPayload;
      if (attachment != null) {
        attPayload = {
          'type': attachment.type,
          'name': attachment.name,
          'mimeType': attachment.mimeType,
          'size': attachment.bytes.length,
          'data': base64Encode(attachment.bytes),
        };
      }

      final res = await ApiService.instance.sendMessage(
        widget.conversationId,
        text,
        attachment: attPayload,
      );
      final created = ChatMessage.fromJson(
        res['message'] as Map<String, dynamic>,
      );

      if (!mounted) return;
      _messageController.clear();
      setState(() {
        _pendingAttachment = null;
        _messages.add(created);
      });
      _scrollToBottom(animate: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _deleteMessage(ChatMessage msg) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text(
          'This message will be deleted for everyone in this chat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final res = await ApiService.instance.deleteMessage(msg.id);
      final updated = ChatMessage.fromJson(
        res['message'] as Map<String, dynamic>,
      );
      if (!mounted) return;
      setState(() {
        _messages =
            _messages.map((m) => m.id == updated.id ? updated : m).toList();
        if (_editingMessage?.id == msg.id) {
          _editingMessage = null;
          _messageController.clear();
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1400,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > _maxAttachmentBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo is too large (max 5 MB).')),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        _editingMessage = null;
        _pendingAttachment = _PendingAttachment(
          type: 'image',
          name: picked.name.isNotEmpty ? picked.name : 'photo.jpg',
          mimeType: 'image/jpeg',
          bytes: bytes,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick photo: $e')),
      );
    }
  }

  Future<void> _pickDocument() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected file.')),
        );
        return;
      }
      if (bytes.length > _maxAttachmentBytes) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File is too large. Please keep files under 5 MB.'),
          ),
        );
        return;
      }

      final ext = file.name.contains('.')
          ? file.name.split('.').last.toLowerCase()
          : '';
      final isImg = ['png', 'jpg', 'jpeg'].contains(ext);
      final mime = switch (ext) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'jpg' || 'jpeg' => 'image/jpeg',
        'doc' => 'application/msword',
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'txt' => 'text/plain',
        _ => 'application/octet-stream',
      };

      if (!mounted) return;
      setState(() {
        _editingMessage = null;
        _pendingAttachment = _PendingAttachment(
          type: isImg ? 'image' : 'file',
          name: file.name,
          mimeType: mime,
          bytes: bytes,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick file: $e')),
      );
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.surfaceElevated,
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Take a Photo',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Capture a skin photo or prescription',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.surfaceElevated,
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: Colors.lightBlueAccent,
                  ),
                ),
                title: const Text(
                  'Photo from Gallery',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Share an existing photo (up to 5 MB)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.surfaceElevated,
                  child: Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.redAccent,
                  ),
                ),
                title: const Text(
                  'Medical Report / File (PDF, DOC)',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Attach lab reports, PDFs, or documents (up to 5 MB)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickDocument();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageActions(ChatMessage msg) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                ),
                title: const Text(
                  'Message Info (Sent, Delivered & Seen)',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showMessageInfoDialog(msg);
                },
              ),
              if (msg.isMine && !msg.isDeleted) ...[
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textPrimary,
                  ),
                  title: const Text(
                    'Edit Message',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _pendingAttachment = null;
                      _editingMessage = msg;
                      _messageController.text = msg.body;
                    });
                    _inputFocusNode.requestFocus();
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Delete Message',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _deleteMessage(msg);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageInfoDialog(ChatMessage msg) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Message Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(
              Icons.done_rounded,
              AppColors.textSecondary,
              'Sent',
              formatFullTimestamp(msg.createdAt),
            ),
            if (msg.isMine) ...[
              const SizedBox(height: 10),
              _infoRow(
                Icons.done_all_rounded,
                AppColors.textSecondary,
                'Delivered',
                msg.isDelivered
                    ? formatFullTimestamp(msg.deliveredAt ?? msg.seenAt)
                    : 'Pending',
              ),
              const SizedBox(height: 10),
              _infoRow(
                msg.isSeen ? Icons.done_all_rounded : Icons.schedule_rounded,
                msg.isSeen ? Colors.lightBlueAccent : AppColors.textSecondary,
                'Seen',
                msg.isSeen ? formatFullTimestamp(msg.seenAt) : 'Not seen yet',
              ),
            ],
            if (msg.isEdited && msg.editedAt != null) ...[
              const SizedBox(height: 10),
              _infoRow(
                Icons.edit_outlined,
                Colors.orangeAccent,
                'Edited',
                formatFullTimestamp(msg.editedAt),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, Color color, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Uint8List? _decodeBase64(String raw) {
    try {
      final clean = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(clean);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openDocumentAttachment(ChatAttachment att) async {
    final bytes = _decodeBase64(att.data);
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not decode attachment.')),
      );
      return;
    }
    final err = await openDocumentBytes(bytes: bytes, fileName: att.name);
    if (err != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  void _scrollToBottom({bool animate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lastMyMsgIndex = _messages.lastIndexWhere((m) => m.isMine);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherAlias,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const Text(
              'Hold any message for info, edit or delete',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh messages',
            onPressed: () => _loadMessages(showLoader: false),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Say hello or share a report!',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _messages.length,
                        itemBuilder: (_, idx) {
                          final msg = _messages[idx];
                          final showStatusCaption = idx == lastMyMsgIndex &&
                              msg.isMine &&
                              !msg.isDeleted;
                          return _buildMessageBubble(
                            msg,
                            showStatusCaption: showStatusCaption,
                          );
                        },
                      ),
          ),

          // Editing banner
          if (_editingMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 8,
              ),
              color: AppColors.surfaceElevated,
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Editing message',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() => _editingMessage = null);
                      _messageController.clear();
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

          // Pending photo/PDF preview bar
          if (_pendingAttachment != null) _buildPendingAttachmentBar(),

          // Input bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  if (_editingMessage == null)
                    IconButton(
                      tooltip: 'Attach photo or medical report',
                      onPressed: _isSending ? null : _showAttachmentSheet,
                      icon: const Icon(
                        Icons.attach_file_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _inputFocusNode,
                      style: const TextStyle(color: AppColors.textPrimary),
                      onSubmitted: (_) => _sendOrSaveEdit(),
                      decoration: InputDecoration(
                        hintText: _editingMessage != null
                            ? 'Update your message...'
                            : _pendingAttachment != null
                                ? 'Add a caption (optional)...'
                                : 'Write a message...',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceElevated,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    onPressed: _isSending ? null : _sendOrSaveEdit,
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _editingMessage != null
                                ? Icons.check_rounded
                                : Icons.send_rounded,
                            color: AppColors.primary,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingAttachmentBar() {
    final att = _pendingAttachment!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (att.type == 'image')
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                att.bytes,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.redAccent,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  att.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  formatFileSize(att.bytes.length),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove attachment',
            onPressed: () => setState(() => _pendingAttachment = null),
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    ChatMessage msg, {
    required bool showStatusCaption,
  }) {
    final isMine = msg.isMine;
    final metaColor = isMine
        ? AppColors.background.withValues(alpha: 0.75)
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: () => _showMessageActions(msg),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              decoration: BoxDecoration(
                color: msg.isDeleted
                    ? AppColors.surfaceElevated
                    : (isMine ? AppColors.primary : AppColors.surface),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: isMine && !msg.isDeleted
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (msg.isDeleted)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.block_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'This message was deleted',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    )
                  else ...[
                    if (msg.attachment != null) ...[
                      _buildAttachmentWidget(msg.attachment!, isMine: isMine),
                      if (msg.body.isNotEmpty) const SizedBox(height: 8),
                    ],
                    if (msg.body.isNotEmpty)
                      Text(
                        msg.body,
                        style: TextStyle(
                          color: isMine
                              ? AppColors.background
                              : AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.isEdited && !msg.isDeleted) ...[
                        Text(
                          'edited · ',
                          style: TextStyle(
                            color: metaColor,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      Text(
                        msg.sentClockTime,
                        style: TextStyle(
                          color: msg.isDeleted
                              ? AppColors.textSecondary
                              : metaColor,
                          fontSize: 10,
                        ),
                      ),
                      if (isMine && !msg.isDeleted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isSeen || msg.isDelivered
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 15,
                          color: msg.isSeen
                              ? const Color(0xFF0047AB)
                              : metaColor,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (showStatusCaption && !msg.isDeleted)
            Padding(
              padding: const EdgeInsets.only(top: 3, right: 4),
              child: Text(
                msg.isSeen
                    ? 'Seen ${formatClockTime(msg.seenAt)}'
                    : msg.isDelivered
                        ? 'Delivered ${formatClockTime(msg.deliveredAt ?? msg.seenAt)}'
                        : 'Sent ${msg.sentClockTime}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentWidget(
    ChatAttachment att, {
    required bool isMine,
  }) {
    if (att.isImage) {
      final bytes = _decodeBase64(att.data);
      if (bytes == null) {
        return const Text(
          'Could not load photo',
          style: TextStyle(color: Colors.redAccent, fontSize: 12),
        );
      }
      return GestureDetector(
        onTap: () => FullScreenPhotoViewer.open(
          context,
          photos: [bytes],
          initialIndex: 0,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220, maxWidth: 240),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
      );
    }

    // PDF / Document Medical Report Card
    final fg = isMine ? AppColors.background : AppColors.textPrimary;
    final sub = isMine
        ? AppColors.background.withValues(alpha: 0.78)
        : AppColors.textSecondary;

    return InkWell(
      onTap: () => _openDocumentAttachment(att),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.background.withValues(alpha: 0.14)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMine
                ? AppColors.background.withValues(alpha: 0.22)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              att.isPdf
                  ? Icons.picture_as_pdf_rounded
                  : Icons.insert_drive_file_rounded,
              color: att.isPdf ? Colors.redAccent : fg,
              size: 28,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    att.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (att.size > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${att.isPdf ? 'PDF' : 'File'} · ${formatFileSize(att.size)} · Tap to open',
                      style: TextStyle(color: sub, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.open_in_new_rounded, size: 16, color: sub),
          ],
        ),
      ),
    );
  }
}

class _PendingAttachment {
  const _PendingAttachment({
    required this.type,
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String type; // 'image' | 'file'
  final String name;
  final String mimeType;
  final Uint8List bytes;
}