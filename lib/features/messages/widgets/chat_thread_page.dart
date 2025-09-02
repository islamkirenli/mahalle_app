import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_repo.dart';
import 'dart:async';

class ChatThreadPage extends StatefulWidget {
  final String conversationId;
  final String? title; // karşı taraf adı

  const ChatThreadPage({
    super.key,
    required this.conversationId,
    this.title,
  });

  @override
  State<ChatThreadPage> createState() => _ChatThreadPageState();
}

class _ChatThreadPageState extends State<ChatThreadPage> {
  late final ChatRepo _repo;
  late final String _uid;
  final _controller = TextEditingController();
  List<ChatMessage> _messages = [];
  StreamSubscription<List<ChatMessage>>? _sub;

  ChatMessage _fromMapSafe(Map<String, dynamic> m) {
    // id → int
    final dynamicId = m['id'];
    final intId = switch (dynamicId) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };

    // created_at → DateTime
    final ca = m['created_at'];
    final created = switch (ca) {
      DateTime v => v,
      String v => DateTime.tryParse(v) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      _ => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    };

    return ChatMessage(
      id: intId,
      conversationId: (m['conversation_id'] ?? m['thread_id']) as String,
      senderId: (m['sender_id'] ?? '') as String,
      content: (m['content'] ?? '').toString(),
      createdAt: created.toLocal(),
    );
  }

  @override
  void initState() {
    super.initState();
    final sb = Supabase.instance.client;
    _repo = ChatRepo(sb);
    _uid = sb.auth.currentUser!.id;

    // 1) İlk açılışta mesajları tek seferlik çek (alanları açık seç)
    () async {
      try {
        final rows = await sb
            .from('messages')
            .select('id, conversation_id, sender_id, content, created_at')
            .eq('conversation_id', widget.conversationId)
            .order('created_at', ascending: true);

        setState(() {
          _messages = (rows as List)
              .map((e) => _fromMapSafe(e as Map<String, dynamic>))
              .toList();
        });

        // Okundu say
        unawaited(_repo.markConversationRead(widget.conversationId));
      } catch (e) {
        debugPrint('Initial messages fetch error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mesajlar yüklenemedi: $e')),
          );
        }
      }
    }();

    // 2) Realtime stream’e doğrudan abone ol (repo yerine doğrudan tablo)
    _sub = sb
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at', ascending: true)
        // <<< AKIŞI ÖNCE ChatMessage listesine map ediyoruz
        .map((rows) => rows.map((e) => _fromMapSafe(e)).toList())
        .listen((list) {
          setState(() => _messages = list);
          _repo.markConversationRead(widget.conversationId);
        });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _hhmm(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    debugPrint('SEND -> conv=${widget.conversationId}');
    _controller.clear(); // optimistic UI
    try {
      await _repo.sendMessage(
          conversationId: widget.conversationId, text: text);
      // sayfa açıkken okundu say (async, hatayı umursama)
      // ignore: unawaited_futures
      _repo.markConversationRead(widget.conversationId);
    } catch (e) {
      // Hata olursa text'i geri koy ve kullanıcıya bildir
      _controller.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mesaj gönderilemedi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Sohbet')),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Henüz mesaj yok'))
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      final isMine = m.senderId == _uid;
                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            color: isMine
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.12)
                                : Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isMine
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Text(m.content,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(
                                _hhmm(m.createdAt.toLocal()),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            child: Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Mesaj yaz...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
