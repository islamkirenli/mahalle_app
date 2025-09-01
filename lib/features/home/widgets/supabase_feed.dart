import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../posts/post_repo.dart';
import 'package:shimmer/shimmer.dart';

class SupabaseFeed extends StatefulWidget {
  const SupabaseFeed({super.key});

  @override
  State<SupabaseFeed> createState() => _SupabaseFeedState();
}

class _SupabaseFeedState extends State<SupabaseFeed> {
  final _scrollCtrl = ScrollController();
  final _items = <Map<String, dynamic>>[];

  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  static const _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadFirst();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _loadingInitial = true;
      _page = 0;
      _hasMore = true;
      _items.clear();
    });
    try {
      final rows = await postRepo.fetchFeedPage(page: 0, limit: _pageSize);
      setState(() {
        _items.addAll(rows);
        _loadingInitial = false;
        _hasMore = rows.length == _pageSize;
        _page = 1;
      });
    } catch (e) {
      setState(() => _loadingInitial = false);
      debugPrint('feed loadFirst error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akış yüklenemedi.')),
        );
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final rows = await postRepo.fetchFeedPage(page: _page, limit: _pageSize);
      setState(() {
        _items.addAll(rows);
        _hasMore = rows.length == _pageSize;
        _page += 1;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() => _loadingMore = false);
      debugPrint('feed loadMore error: $e');
    }
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients || _loadingMore || !_hasMore) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 600) {
      _loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingInitial) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _PostSkeleton(),
      );
    }

    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Henüz gönderi yok. İlk paylaşımı sen yap!'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFirst,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: _items.length + 1, // +1: alt yükleniyor/sonek
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i < _items.length) {
            return _FeedPostCard(post: _items[i]);
          }
          // footer
          if (_loadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          if (!_hasMore) {
            return const SizedBox.shrink();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _PostSkeleton extends StatelessWidget {
  const _PostSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Shimmer.fromColors(
      baseColor: theme.colorScheme.surfaceVariant.withOpacity(.5),
      highlightColor: theme.colorScheme.surfaceVariant.withOpacity(.2),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(.6),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          )),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                            width: 80,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5),
                            )),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    )),
              ],
            ),
            const SizedBox(height: 12),
            // text lines
            Container(
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                )),
            const SizedBox(height: 8),
            Container(
                width: 180,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                )),
            const SizedBox(height: 12),
            // image skeleton
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // action bar
            Row(
              children: List.generate(
                  3,
                  (i) => Padding(
                        padding: EdgeInsets.only(right: i == 2 ? 0 : 16),
                        child: Row(children: [
                          Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              )),
                          const SizedBox(width: 6),
                          Container(
                              width: 24,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              )),
                        ]),
                      )),
            )
          ],
        ),
      ),
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
  String? _postId;
  int _comments = 0;
  int _shares = 0;
  late final PageController _pc;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController();

    final p = widget.post;
    _postId = p['id'] as String?;
    _likes = (p['likes_count'] as int?) ?? 0;
    _comments = (p['comments_count'] as int?) ?? 0;
    _shares = (p['shares_count'] as int?) ?? 0;

    if (_postId != null) {
      postRepo.isLikedByMe(_postId!).then((v) {
        if (mounted) setState(() => _liked = v);
      });
    }
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
      child: InkWell(
        onTap: () {
          final id = (_postId ?? widget.post['id']) as String?;
          if (id != null) {
            context.push('/post/$id');
          }
        },
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
                                child: Icon(Icons.broken_image_outlined,
                                    size: 40)),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
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
                                    color:
                                        active ? Colors.white : Colors.white70,
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
                        onPressed: _postId == null
                            ? null
                            : () async {
                                final prev = _liked;
                                setState(() {
                                  _liked = !prev;
                                  _likes += _liked ? 1 : -1;
                                });
                                try {
                                  if (_liked) {
                                    await postRepo.like(_postId!);
                                  } else {
                                    await postRepo.unlike(_postId!);
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() {
                                    _liked = prev;
                                    _likes += _liked ? 1 : -1;
                                  });
                                  debugPrint('like error: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Beğeni işlemi başarısız.')),
                                  );
                                }
                              },
                        icon: Icon(
                          _liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                          color: _liked ? primary : null,
                        ),
                      ),
                      InkWell(
                        onTap: (_likes > 0) ? _showLikersSheet : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Text(
                            _fmt(_likes),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: _liked ? primary : null,
                              fontWeight: _liked ? FontWeight.w600 : null,
                              decoration: (_likes > 0)
                                  ? TextDecoration.underline
                                  : null,
                              decorationStyle: TextDecorationStyle.dotted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed:
                            (_postId == null) ? null : _showCommentsSheet,
                        icon: const Icon(Icons.mode_comment_outlined),
                      ),
                      InkWell(
                        onTap: (_postId == null) ? null : _showCommentsSheet,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Text(_fmt(_comments),
                              style: theme.textTheme.labelLarge),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _postId == null
                            ? null
                            : () async {
                                try {
                                  await postRepo.share(_postId!);
                                  if (!mounted) return;
                                  setState(() => _shares += 1); // optimistic
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Paylaşıldı.')),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  debugPrint('share error: $e');
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Paylaşım başarısız.')),
                                  );
                                }
                              },
                        icon: const Icon(Icons.share_outlined),
                      ),
                      Text(_fmt(_shares), style: theme.textTheme.labelLarge),
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

  Future<void> _showLikersSheet() async {
    final postId = (widget.post['id'] as String?);
    if (postId == null || _likes <= 0) return;

    final theme = Theme.of(context);
    final likers = await postRepo.likers(postId);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5, // ← yarım ekran
          minChildSize: 0.3,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.5, 0.95],
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Beğenenler',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController, // ← sheet’in scroll’u
                      itemCount: likers.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withOpacity(.4),
                      ),
                      itemBuilder: (_, i) {
                        final m = likers[i];
                        final name = (m['display_name'] as String?)?.trim();
                        final title =
                            (name != null && name.isNotEmpty) ? name : 'Komşu';
                        final avatar = (m['avatar_url'] as String?) ?? '';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                avatar.isNotEmpty ? NetworkImage(avatar) : null,
                            child: avatar.isEmpty
                                ? Text(title.characters.first)
                                : null,
                          ),
                          title: Text(title),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showCommentsSheet() async {
    final postId = _postId;
    if (postId == null) return;

    final theme = Theme.of(context);
    final inputCtrl = TextEditingController();

    // İlk liste
    List<Map<String, dynamic>> items = await postRepo.comments(postId);
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5, // yarım ekran
          minChildSize: 0.3,
          maxChildSize: 0.95,
          snap: true,
          snapSizes: const [0.5, 0.95],
          builder: (ctx, scrollCtrl) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 8,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
              ),
              child: Column(
                children: [
                  Text('Yorumlar',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollCtrl,
                      itemCount: items.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withOpacity(.4),
                      ),
                      itemBuilder: (_, i) {
                        final m = items[i];
                        final name =
                            ((m['display_name'] as String?) ?? 'Komşu').trim();
                        final avatar = (m['avatar_url'] as String?) ?? '';
                        final text = (m['text'] as String?) ?? '';
                        final createdAt = DateTime.tryParse(
                              m['created_at'] as String? ?? '',
                            ) ??
                            DateTime.now();

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                avatar.isNotEmpty ? NetworkImage(avatar) : null,
                            child: avatar.isEmpty
                                ? Text(name.characters.first)
                                : null,
                          ),
                          title: Text(name,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(text),
                              const SizedBox(height: 4),
                              Text(
                                _relative(createdAt),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: inputCtrl,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Yorum yaz…',
                            prefixIcon: Icon(Icons.mode_comment_outlined),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () async {
                          final txt = inputCtrl.text.trim();
                          if (txt.isEmpty) return;
                          try {
                            await postRepo.addComment(postId, txt);
                            inputCtrl.clear();
                            // Listeyi yenile
                            items = await postRepo.comments(postId);
                            if (!mounted) return;
                            setState(() => _comments += 1); // optimistic sayaç
                            (ctx as Element).markNeedsBuild(); // sheet'i yenile
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Yorum eklenemedi.')),
                            );
                          }
                        },
                        child: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
