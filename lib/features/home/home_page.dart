import 'package:flutter/material.dart';
import 'package:mahalle_app/features/notifications/notifications_page.dart';
import 'package:mahalle_app/features/messages/messages_page.dart';
import 'package:mahalle_app/features/home/widgets/supabase_feed.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mahalle"),
        actions: [
          IconButton(
            tooltip: "Bildirimler",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),

// Mesajlar butonu
          IconButton(
            tooltip: "Mesajlar",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MessagesPage()),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
        ],
      ),
      body: const SupabaseFeed(),
    );
  }
}

//burası
class PostCard extends StatefulWidget {
  const PostCard({super.key, required this.post});
  final Post post;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _likes;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _likes = widget.post.likes;
    _liked = false; // TODO: backend'den 'likedByMe' gelirse onunla başlat
  }

  void _toggleLike() {
    setState(() {
      _liked = !_liked;
      _likes += _liked ? 1 : -1;
    });
    // TODO: backend'e like/unlike isteği gönder
  }

  void _showLikers() {
    final likers = List.generate(_likes, (i) => 'Kullanıcı ${i + 1}');
    final sheetCtrl = DraggableScrollableController();

    showModalBottomSheet(
      context: context,
      useRootNavigator: false, // yerel navigator kullan
      isScrollControlled: true,
      isDismissible: true, // kullanıcı aşağı çekerek de kapatabilsin
      enableDrag: false, // boyut/kapama üst başlıktan kontrol
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) {
        return DraggableScrollableSheet(
          controller: sheetCtrl,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.5, 0.95],
          expand: false,
          builder: (context, providedScrollController) {
            final visibleListCtrl = ScrollController();

            return Column(
              children: [
                // Yalnızca buradan sürüklenince boyut değişsin
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    final h = MediaQuery.of(context).size.height;
                    final next =
                        (sheetCtrl.size - (details.primaryDelta ?? 0) / h)
                            .clamp(0.3, 0.95);
                    sheetCtrl.jumpTo(next);
                  },
                  onVerticalDragEnd: (details) async {
                    final vy = details.velocity.pixelsPerSecond.dy; // + = aşağı
                    final s = sheetCtrl.size;

                    // Çok aşağı ve yarımdan da düşük ⇒ güvenli kapat (mikro-görev)
                    if (vy > 900 && s <= 0.6) {
                      Future.microtask(() {
                        final nav = Navigator.of(c);
                        if (nav.canPop()) nav.pop();
                      });
                      return;
                    }

                    // Snap kararları
                    if (s >= 0.85) {
                      await sheetCtrl.animateTo(0.95,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut);
                    } else if (s <= 0.42) {
                      Future.microtask(() {
                        final nav = Navigator.of(c);
                        if (nav.canPop()) nav.pop();
                      });
                    } else {
                      await sheetCtrl.animateTo(0.5,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: Text('Beğenenler',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),

                // providedScrollController'ı etkisizleştir
                Offstage(
                  offstage: true,
                  child: ListView(
                    controller: providedScrollController,
                    shrinkWrap: true,
                    children: const [SizedBox(height: 0.1)],
                  ),
                ),

                // İçerik: sadece liste kayar
                Expanded(
                  child: ListView.separated(
                    controller: visibleListCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: likers.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => ListTile(
                      leading: CircleAvatar(child: Text(likers[i][0])),
                      title: Text(likers[i]),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showComments() {
    final comments = List.generate(
      widget.post.comments,
      (i) => ('Kullanıcı ${i + 1}', 'Yorum metni ${i + 1}...'),
    );
    final sheetCtrl = DraggableScrollableController();

    showModalBottomSheet(
      context: context,
      useRootNavigator: false,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (c) {
        return DraggableScrollableSheet(
          controller: sheetCtrl,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.5, 0.95],
          expand: false,
          builder: (context, providedScrollController) {
            final visibleListCtrl = ScrollController();

            return Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    final h = MediaQuery.of(context).size.height;
                    final next =
                        (sheetCtrl.size - (details.primaryDelta ?? 0) / h)
                            .clamp(0.3, 0.95);
                    sheetCtrl.jumpTo(next);
                  },
                  onVerticalDragEnd: (details) async {
                    final vy = details.velocity.pixelsPerSecond.dy;
                    final s = sheetCtrl.size;

                    if (vy > 900 && s <= 0.6) {
                      Future.microtask(() {
                        final nav = Navigator.of(c);
                        if (nav.canPop()) nav.pop();
                      });
                      return;
                    }
                    if (s >= 0.85) {
                      await sheetCtrl.animateTo(0.95,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut);
                    } else if (s <= 0.42) {
                      Future.microtask(() {
                        final nav = Navigator.of(c);
                        if (nav.canPop()) nav.pop();
                      });
                    } else {
                      await sheetCtrl.animateTo(0.5,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 8),
                    child: Text('Yorumlar',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                Offstage(
                  offstage: true,
                  child: ListView(
                    controller: providedScrollController,
                    shrinkWrap: true,
                    children: const [SizedBox(height: 0.1)],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: visibleListCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final (user, text) = comments[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(user[0])),
                        title: Text(user),
                        subtitle: Text(text),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final post = widget.post;

    return Card(
      elevation: 0.5,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // TODO: Detay sayfasına gidebilirsin
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER (aynen kalsın) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primary.withOpacity(.12),
                    child: Text(post.author.characters.first),
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
                                post.author,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              post.handle,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• ${post.timeAgo}',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        if (post.typeLabel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              post.typeLabel!,
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

              // --- TEXT ---
              Text(post.text, style: theme.textTheme.bodyLarge),

              // --- IMAGE (varsa) ---
              if (post.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(color: theme.colorScheme.surfaceVariant),
                        Image.network(
                          post.imageUrl!,
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
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 6),

              _ActionBar(
                liked: _liked,
                likes: _likes,
                comments: post.comments,
                shares: post.shares,
                onToggleLike: _toggleLike,
                onShowLikers: _showLikers,
                onShowComments: _showComments, // ← eklendi
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.liked,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.onToggleLike,
    required this.onShowLikers,
    required this.onShowComments,
  });

  final bool liked;
  final int likes;
  final int comments;
  final int shares;
  final VoidCallback onToggleLike;
  final VoidCallback onShowLikers;
  final VoidCallback onShowComments;

  @override
  Widget build(BuildContext context) {
    final subtle = Theme.of(context).hintColor;
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        //Beğeni
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onToggleLike,
              icon: Icon(
                liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                color: liked ? primary : null,
              ),
            ),
            GestureDetector(
              onTap: onShowLikers,
              child: Text(
                _fmt(likes),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: liked ? primary : null,
                      fontWeight: liked ? FontWeight.w600 : null,
                    ),
              ),
            ),
          ],
        ),

        const SizedBox(width: 16),

        // Yorum
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onShowComments,
              icon: const Icon(Icons.mode_comment_outlined),
            ),
            GestureDetector(
              onTap: onShowComments,
              child: Text(
                _fmt(comments),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ],
        ),

        const SizedBox(width: 16),

        // Paylaş
        Row(
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () {
                // TODO: paylaş
              },
              icon: const Icon(Icons.share_outlined),
            ),
            Text(_fmt(shares), style: Theme.of(context).textTheme.labelLarge),
          ],
        ),

        const Spacer(),
        Icon(Icons.visibility_outlined, size: 18, color: subtle),
        const SizedBox(width: 4),
        Text(
          'Herkese Açık',
          style:
              Theme.of(context).textTheme.labelSmall?.copyWith(color: subtle),
        ),
      ],
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}B';
    return '$n';
  }
}

// Basit Post modeli (mock)
class Post {
  final String author;
  final String handle;
  final String timeAgo;
  final String text;
  final String? imageUrl;
  final int likes;
  final int comments;
  final int shares;
  final String? typeLabel;

  Post({
    required this.author,
    required this.handle,
    required this.timeAgo,
    required this.text,
    required this.imageUrl,
    required this.likes,
    required this.comments,
    required this.shares,
    this.typeLabel,
  });
}
