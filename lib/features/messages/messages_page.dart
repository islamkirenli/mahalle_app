import 'package:flutter/material.dart';
import 'package:mahalle_app/features/messages/widgets/chat_repo.dart';
import 'package:mahalle_app/features/messages/widgets/chat_thread_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final _convos = List.generate(
    10,
    (i) => _Conversation(
      name: i.isEven ? 'Ayşe K.' : 'Mert T.',
      lastMessage: i % 3 == 0
          ? 'Akşam görüşürüz!'
          : i % 3 == 1
              ? 'Fotoğrafları attım.'
              : 'Tamamdır, teşekkürler 🙏',
      time: i == 0 ? 'Şimdi' : (i < 3 ? '${i * 5} dk' : 'Dün'),
      unread: i % 4 == 1 ? 2 : 0,
      typing: i == 0, // örnek: biri yazıyor
    ),
  );

  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _convos
        .where((c) =>
            c.name.toLowerCase().contains(_query.toLowerCase()) ||
            c.lastMessage.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesajlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment),
            tooltip: 'Yeni sohbet',
            onPressed: () async {
              // Basit kullanıcı arama sheet’i
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const _NewChatSheet(),
              );
            },
          ),
        ],
      ),
      body: _ConversationsList(),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Yeni sohbet',
        onPressed: () {
          // TODO: yeni sohbet başlat
        },
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
    );
  }
}

class _Conversation {
  _Conversation({
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.unread,
    this.typing = false,
  });

  final String name;
  final String lastMessage;
  final String time;
  final int unread;
  final bool typing;
}

class _ConversationsList extends StatefulWidget {
  const _ConversationsList();

  @override
  State<_ConversationsList> createState() => _ConversationsListState();
}

class _ConversationsListState extends State<_ConversationsList> {
  late final ChatRepo _repo;
  List<ConversationOverview> _items = [];
  bool _loading = true;
  RealtimeChannel? _messagesChannel;
  String get _uid => Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    final sb = Supabase.instance.client;
    _repo = ChatRepo(sb);
    _load();

    // Mesaj INSERT olaylarını dinle -> listeyi yenile
    _messagesChannel = sb.channel('conv_list_refresh')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'conversation_id',
          value: '*', // tümünü dinleyeceğiz; filtre yoksa tamam
        ),
        callback: (payload) {
          // kullanıcı ilgili konuşmanın içindeyse unread vs değişir; listeyi yenile
          _load();
        },
      )
      ..subscribe();
  }

  @override
  void dispose() {
    if (_messagesChannel != null) {
      Supabase.instance.client.removeChannel(_messagesChannel!);
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _repo.fetchConversations();
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  String _timeOrDash(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const Center(child: Text('Henüz konuşma yok'));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final c = _items[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: (c.otherAvatarUrl?.isNotEmpty ?? false)
                  ? NetworkImage(c.otherAvatarUrl!)
                  : null,
              child: (c.otherAvatarUrl == null || c.otherAvatarUrl!.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(c.otherDisplayName ?? 'Kullanıcı'),
            subtitle: Text(
              (c.lastMessage?.isNotEmpty ?? false)
                  ? c.lastMessage!
                  : 'Yeni sohbet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_timeOrDash(c.lastMessageAt)),
                if (c.unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${c.unreadCount}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatThreadPage(
                  conversationId: c.conversationId,
                  title: c.otherDisplayName,
                ),
              ));
              // dönüşte okundu/son mesaj değişmiş olabilir, yenile
              _load();
            },
          );
        },
      ),
    );
  }
}

class _NewChatSheet extends StatefulWidget {
  const _NewChatSheet();

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  final _query = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  late final ChatRepo _repo;

  @override
  void initState() {
    super.initState();
    _repo = ChatRepo(Supabase.instance.client);
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final r = await _repo.searchUsers(_query.text);
    setState(() {
      _results = r;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Yeni sohbet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _query,
                      decoration: const InputDecoration(
                        hintText: 'İsim ara…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _search, child: const Text('Ara')),
                ],
              ),
              const SizedBox(height: 12),
              if (_loading) const LinearProgressIndicator(),
              ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, i) {
                  final u = _results[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: ((u['avatar_url'] != null &&
                              (u['avatar_url'] as String).isNotEmpty)
                          ? NetworkImage(u['avatar_url'] as String)
                          : (u['photo_url'] != null &&
                                  (u['photo_url'] as String).isNotEmpty)
                              ? NetworkImage(u['photo_url'] as String)
                              : null) as ImageProvider<Object>?,
                      child: ((u['avatar_url'] == null ||
                                  (u['avatar_url'] as String).isEmpty) &&
                              (u['photo_url'] == null ||
                                  (u['photo_url'] as String).isEmpty))
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(u['display_name'] ?? 'Kullanıcı'),
                    onTap: () async {
                      final convId = await _repo
                          .getOrCreateConversationWith(u['id'] as String);
                      if (!context.mounted) return;
                      Navigator.of(context).pop(); // sheet kapat
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatThreadPage(
                          conversationId: convId,
                          title: u['display_name'] as String?,
                        ),
                      ));
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
