import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _all = List.generate(12, (i) => _MockNotif.sample(i));
  final _mentions = List.generate(5, (i) => _MockNotif.sample(i, mention: true));

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Bahsetmeler'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Bildirim ayarları',
            onPressed: () {
              // TODO: ayarlar
            },
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _NotificationList(items: _all),
          _NotificationList(items: _mentions),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Hepsini okundu işaretle
          setState(() {
            for (final n in _all) n.read = true;
            for (final n in _mentions) n.read = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tüm bildirimler okundu.')),
          );
        },
        icon: const Icon(Icons.mark_email_read_outlined),
        label: const Text('Hepsini okundu işaretle'),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.items});
  final List<_MockNotif> items;

  @override
  Widget build(BuildContext context) {
    final divider = Divider(
      height: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withOpacity(.4),
    );
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: items.length,
      separatorBuilder: (_, __) => divider,
      itemBuilder: (_, i) {
        final n = items[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withOpacity(.12),
                child: Icon(
                  n.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              if (!n.read)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          title: Text(n.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: !n.read ? FontWeight.w600 : null,
                  )),
          subtitle: Text(
            n.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            n.time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          onTap: () {
            // Bildirime göre ilgili içeriğe git
          },
          onLongPress: () {
            n.read = true;
            (context as Element).markNeedsBuild();
          },
        );
      },
    );
  }
}

/// Basit mock veri modeli (örnek)
class _MockNotif {
  _MockNotif({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    this.read = false,
  });

  String title;
  String subtitle;
  String time;
  IconData icon;
  bool read;

  static _MockNotif sample(int i, {bool mention = false}) {
    final times = ['Şimdi', '5 dk', '1 sa', 'Dün', '2 gün'];
    if (mention) {
      return _MockNotif(
        title: '@osmanaga senden bahsetti',
        subtitle: '“Komşu buluşması akşam 7’de başlıyor, @sen de gelir misin?”',
        time: times[i % times.length],
        icon: Icons.alternate_email_rounded,
        read: i.isEven,
      );
    }
    final icons = [
      Icons.thumb_up_alt_outlined,
      Icons.mode_comment_outlined,
      Icons.person_add_alt_1_outlined,
      Icons.campaign_outlined,
    ];
    final titles = [
      'Gönderin beğenildi',
      'Gönderine yorum var',
      'Yeni takip isteği',
      'Mahalle duyurusu',
    ];
    final subtitles = [
      'Ayşe: Harika bir fikir!',
      'Mert: Yarın gelebilirim.',
      'Elif seni takip etmek istiyor.',
      'Yarın 20:00’da toplantı var.',
    ];
    return _MockNotif(
      title: titles[i % titles.length],
      subtitle: subtitles[i % subtitles.length],
      time: times[i % times.length],
      icon: icons[i % icons.length],
      read: i % 3 == 0,
    );
    }
}
