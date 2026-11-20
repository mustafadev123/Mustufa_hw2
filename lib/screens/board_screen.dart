import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/board_message.dart';
import '../services/auth_service.dart';
import '../services/board_service.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({
    required this.user,
    required this.authService,
    required this.boardService,
    super.key,
  });
  final User user;
  final AuthService authService;
  final BoardService boardService;
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _text = TextEditingController();
  bool _sending = false;
  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final operationId = const Uuid().v4();
    try {
      await widget.boardService.createMessage(
        operationId: operationId,
        authorUid: widget.user.uid,
        authorName: widget.user.displayName ?? widget.user.email ?? 'Member',
        text: text,
      );
      _text.clear();
    } catch (_) {
      if (mounted) _error('Message could not be posted. Try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _error(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  Future<void> _edit(BoardMessage message) async {
    final controller = TextEditingController(text: message.text);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 500,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // showDialog completes when Navigator.pop is called, before the route's
    // reverse animation has fully detached the TextField from its controller.
    await Future<void>.delayed(kThemeAnimationDuration);
    controller.dispose();
    if (value == null || value.isEmpty || value == message.text) return;
    try {
      await widget.boardService.updateMessage(message.id, value);
    } catch (_) {
      if (mounted) _error('Edit denied or unavailable.');
    }
  }

  Future<void> _delete(BoardMessage message) async {
    final yes =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete message?'),
            content: const Text('This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
    if (!yes) return;
    try {
      await widget.boardService.deleteMessage(message.id);
    } catch (_) {
      if (mounted) _error('Delete denied or unavailable.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Vault Board'),
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: widget.authService.signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: Column(
      children: [
        Expanded(
          child: StreamBuilder<List<BoardMessage>>(
            stream: widget.boardService.watchMessages(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _BoardStatus(
                  icon: Icons.lock_outline,
                  message: 'The board could not be read. Check your access and connection.',
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final messages = snapshot.data!;
              if (messages.isEmpty) {
                return const _BoardStatus(
                  icon: Icons.mark_chat_unread_outlined,
                  message: 'The vault is quiet. Post the first message.',
                );
              }
              return ListView.builder(
                reverse: false,
                padding: const EdgeInsets.all(12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index],
                      mine = message.authorUid == widget.user.uid;
                  return Card(
                    child: ListTile(
                      title: Text(message.authorName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(message.text),
                          const SizedBox(height: 6),
                          Text(
                            message.createdAt == null
                                ? 'Sending…'
                                : DateFormat.yMMMd().add_jm().format(
                                    message.createdAt!,
                                  ),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      trailing: mine
                          ? PopupMenuButton<String>(
                              onSelected: (v) => v == 'edit'
                                  ? _edit(message)
                                  : _delete(message),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    maxLength: 500,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Write a message...',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _BoardStatus extends StatelessWidget {
  const _BoardStatus({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}
