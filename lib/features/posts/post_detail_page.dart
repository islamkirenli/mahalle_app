import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../posts/post_repo.dart';

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  Map<String, dynamic>? _post;
  bool _loading = true;

  late final PageController _pc;
  int _page = 0;

  bool _liked = false;
  int _likes = 0;
  int _comments = 0;
  int _shares = 0;

  final _commentCtrl = TextEditingController();

  final _scroll = ScrollController();
  final _commentsKey = GlobalKey();
  bool _loadingComments = true;
  List<Map<String, dynamic>> _commentsList = [];

  @override
  void initState() {
    super.initState();
    _pc = PageController();
    _load();
  }

  @override
  void dispose() {
    _pc.dispose();
    _commentCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await postRepo.fetchPost(widget.postId);
      if (p == null) {
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final liked = await postRepo.isLikedByMe(widget.postId);
      setState(() {
        _post = p;
        _liked = liked;
        _likes = (p['likes_count'] as int?) ?? 0;
        _comments = (p['comments_count'] as int?) ?? 0;
        _shares = (p['shares_count'] as int?) ?? 0;
        _loading = false;
      });
      await _loadComments();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gönderi yüklenemedi.')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      setState(() => _loadingComments = true);
      final list = await postRepo.commentsList(widget.postId);
      if (!mounted) return;
      setState(() {
        _commentsList = list;
        _loadingComments = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingComments = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yorumlar yüklenemedi.')),
      );
    }
  }

  List<String> _imagesOf(Map<String, dynamic> p) {
    final atts = p['attachments'];
    final legacy = p['image_url'] as String?;
    final list = <String>[];
    if (atts is List) {
      for (final a in atts) {
        if (a is String && a.isNotEmpty) list.add(a);
      }
    }
    if (list.isEmpty && legacy != null && legacy.isNotEmpty) {
      list.add(legacy);
    }
    return list;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Gönderi')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Gönderi')),
        body: const Center(child: Text('Gönderi bulunamadı.')),
      );
    }

    final p = _post!;
    final author = (p['author_name'] as String?) ?? 'Komşu';
    final handle = (p['district'] as String?) ?? '';
    final text = (p['text'] as String?) ?? '';
    final createdAt = DateTime.tryParse(p['created_at'] as String? ?? '');
    final timeAgo = createdAt == null ? '' : _relative(createdAt);
    final images = _imagesOf(p);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gönderi'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: primary.withOpacity(.12),
                child: Text(author.isEmpty ? '?' : author.characters.first),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(
                          author,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
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
                    ]),
                    if (timeAgo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('• $timeAgo',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // METİN
          if (text.isNotEmpty) Text(text, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),

          // GÖRSELLER
          if (images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (images.length == 1)
                      Image.network(
                        images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, size: 40)),
                        loadingBuilder: (c, w, p) => p == null
                            ? w
                            : const Center(
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                      ),
                    if (images.length > 1)
                      PageView.builder(
                        controller: _pc,
                        onPageChanged: (i) => setState(() => _page = i),
                        itemCount: images.length,
                        itemBuilder: (_, i) => Image.network(
                          images[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined, size: 40),
                          ),
                          loadingBuilder: (c, w, p) => p == null
                              ? w
                              : const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                        ),
                      ),
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
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ACTION BAR
          Row(
            children: [
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final prev = _liked;
                      setState(() {
                        _liked = !prev;
                        _likes += _liked ? 1 : -1;
                      });
                      try {
                        if (_liked) {
                          await postRepo.like(widget.postId);
                        } else {
                          await postRepo.unlike(widget.postId);
                        }
                      } catch (_) {
                        if (!mounted) return;
                        setState(() {
                          _liked = prev;
                          _likes += _liked ? 1 : -1;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Beğeni işlemi başarısız.')),
                        );
                      }
                    },
                    icon: Icon(
                      _liked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      color: _liked ? primary : null,
                    ),
                  ),
                  Text('$_likes', style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      final ctx = _commentsKey.currentContext;
                      if (ctx != null) {
                        Scrollable.ensureVisible(
                          ctx,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      } else {
                        _scroll.animateTo(
                          _scroll.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    icon: const Icon(Icons.mode_comment_outlined),
                  ),
                  Text('$_comments', style: theme.textTheme.labelLarge),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      try {
                        await postRepo.share(widget.postId);
                        if (!mounted) return;
                        setState(() => _shares += 1);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Paylaşıldı.')),
                        );
                      } catch (_) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Paylaşım başarısız.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.share_outlined),
                  ),
                  Text('$_shares', style: theme.textTheme.labelLarge),
                ],
              ),
              const Spacer(),
              Icon(Icons.visibility_outlined, size: 18, color: theme.hintColor),
              const SizedBox(width: 4),
              Text('Herkese Açık',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.hintColor)),
            ],
          ),

          // --- YORUMLAR BÖLÜMÜ (inline) ---
          const SizedBox(height: 12),
          Container(
            key: _commentsKey, // ← butondan buraya kaydırıyoruz
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yorumlar ($_comments)',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),

                if (_loadingComments)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_commentsList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Henüz yorum yok. İlk yorumu sen yaz!',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.hintColor),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _commentsList.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withOpacity(.4),
                    ),
                    itemBuilder: (_, i) {
                      final m = _commentsList[i];
                      final title = (m['display_name'] as String?)?.trim();
                      final name =
                          (title != null && title.isNotEmpty) ? title : 'Komşu';
                      final avatar = (m['avatar_url'] as String?) ?? '';
                      final text = m['text'] as String? ?? '';
                      final createdAt =
                          DateTime.tryParse(m['created_at'] as String? ?? '');

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: avatar.isEmpty
                              ? Text(name.characters.first)
                              : null,
                        ),
                        title: Text(name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(text),
                            if (createdAt != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  _relative(createdAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.hintColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 12),

                // Yorum yaz alanı
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Yorum yaz…',
                          prefixIcon: Icon(Icons.mode_comment_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        final t = _commentCtrl.text.trim();
                        if (t.isEmpty) return;
                        try {
                          await postRepo.addComment(widget.postId, t);
                          if (!mounted) return;
                          _commentCtrl.clear();
                          setState(() => _comments += 1); // optimistic sayaç
                          await _loadComments(); // listeyi yenile
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Yorum eklenemedi.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Gönder'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
