import 'package:flutter/material.dart';

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
            tooltip: 'Yeni mesaj',
            onPressed: () {
              // TODO: kullanıcı seç > sohbet başlat
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yeni mesaj başlat')),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Kişi veya mesaj ara…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(.4)),
              itemBuilder: (_, i) {
                final c = filtered[i];
                return ListTile(
                  onTap: () {
                    // TODO: sohbet detay sayfası
                  },
                  leading: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primary.withOpacity(.12),
                        child: Text(
                          c.name.characters.first,
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
                      ),
                      if (c.unread > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${c.unread}',
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          c.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: c.unread > 0 ? FontWeight.w700 : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        c.time,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      c.typing ? 'Yazıyor…' : c.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: c.unread > 0
                          ? theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            )
                          : null,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.hintColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
