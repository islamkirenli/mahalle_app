import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../posts/post_repo.dart';

class SupabaseFeed extends StatelessWidget {
  const SupabaseFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: postRepo.feedStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final items = snap.data ?? const [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Henüz gönderi yok. İlk paylaşımı sen yap!'),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _FeedPostCard(post: items[i]),
        );
      },
    );
  }
}

class _FeedPostCard extends StatefulWidget {
  const _FeedPostCard({required this.post});
  final Map<String, dynamic> post;

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  bool _liked = false;
  int _likes = 0;
  late final PageController _pc;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final p = widget.post;

    final text = (p['text'] as String?) ?? '';
    final createdAt = DateTime.tryParse(p['created_at'] as String? ?? '');
    final timeAgo = createdAt == null ? '' : _relative(createdAt);

    // type rozet
    final type = (p['type'] as String?) ?? 'duyuru';
    final typeLabel = switch (type) {
      'duyuru' => 'Duyuru',
      'etkinlik' => 'Etkinlik',
      'ilan' => 'İlan',
      'yardim' => 'Yardım',
      'pazarIlani' => 'Pazar',
      _ => null,
    };

    // görseller: attachments[] varsa hepsini kullan, yoksa image_url
    List<String> images = [];
    final atts = p['attachments'];
    if (atts is List) {
      for (final a in atts) {
        if (a is String && a.isNotEmpty) images.add(a);
      }
    }
    final legacy = p['image_url'] as String?;
    if (images.isEmpty && legacy != null && legacy.isNotEmpty) {
      images = [legacy];
    }

    // yazar adı (şimdilik profilden join yapmıyoruz; mock baş harf/isim)
    final author = (p['author_name'] as String?) ?? 'Komşu';
    final handle = (p['district'] as String?) ?? '';

    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: primary.withOpacity(.12),
                  child: Text(author.characters.isEmpty
                      ? '?'
                      : author.characters.first),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              author,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (handle.isNotEmpty)
                            Text(
                              handle,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          if (timeAgo.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '• $timeAgo',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (typeLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            typeLabel,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: primary),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 10),

            // METİN
            if (text.isNotEmpty) Text(text, style: theme.textTheme.bodyLarge),

            // GÖRSELLER (çoklu destek)
            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Tek görsel: direkt göster
                      if (images.length == 1)
                        Image.network(
                          images.first,
                          fit: BoxFit.cover,
                          loadingBuilder: (c, w, p) {
                            if (p == null) return w;
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Center(
                              child:
                                  Icon(Icons.broken_image_outlined, size: 40)),
                        ),

                      // Çoklu görsel: PageView
                      if (images.length > 1)
                        PageView.builder(
                          controller: _pc,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemCount: images.length,
                          itemBuilder: (_, i) => Image.network(
                            images[i],
                            fit: BoxFit.cover,
                            loadingBuilder: (c, w, p) {
                              if (p == null) return w;
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (_, __, ___) => const Center(
                              child:
                                  Icon(Icons.broken_image_outlined, size: 40),
                            ),
                          ),
                        ),

                      // Çoklu görseller için sayfa sayacı (sağ üst)
                      if (images.length > 1)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_page + 1}/${images.length}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),

                      // Nokta göstergeleri (alt orta)
                      if (images.length > 1)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (i) {
                              final active = i == _page;
                              return Container(
                                width: active ? 10 : 7,
                                height: active ? 10 : 7,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3),
                                decoration: BoxDecoration(
                                  color: active ? Colors.white : Colors.white70,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 6),

            // ACTION BAR (şimdilik local sayaç)
            Row(
              children: [
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() {
                        _liked = !_liked;
                        _likes += _liked ? 1 : -1;
                      }),
                      icon: Icon(
                        _liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                        color: _liked ? primary : null,
                      ),
                    ),
                    Text(_fmt(_likes),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: _liked ? primary : null,
                          fontWeight: _liked ? FontWeight.w600 : null,
                        )),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Yorumlar yakında')),
                        );
                      },
                      icon: const Icon(Icons.mode_comment_outlined),
                    ),
                    Text('0', style: theme.textTheme.labelLarge),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () {},
                      icon: const Icon(Icons.share_outlined),
                    ),
                    Text('0', style: theme.textTheme.labelLarge),
                  ],
                ),
                const Spacer(),
                Icon(Icons.visibility_outlined,
                    size: 18, color: theme.hintColor),
                const SizedBox(width: 4),
                Text('Herkese Açık',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.hintColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}B';
    return '$n';
  }

  String _relative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
    if (diff.inHours < 24) return '${diff.inHours} sa';
    if (diff.inDays < 7) return '${diff.inDays} gün';
    return DateFormat('dd.MM.yyyy').format(dt);
  }
}
