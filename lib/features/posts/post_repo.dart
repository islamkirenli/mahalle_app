import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PostRepo {
  final _sb = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String?> uploadImage(File file) async {
    final uid = _sb.auth.currentUser!.id;
    final key =
        '${uid}/${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.jpg';
    await _sb.storage.from('post-images').upload(key, file);
    return _sb.storage.from('post-images').getPublicUrl(key);
  }

  Future<void> createPost({required String text, String? imageUrl}) async {
    final uid = _sb.auth.currentUser!.id;

    final prof = await _sb
        .from('profiles')
        .select('district')
        .eq('id', uid)
        .maybeSingle();

    await _sb.from('posts').insert({
      'author_id': uid,
      'text': text,
      'image_url': imageUrl,
      'district': prof?['district'],
    });
  }

  Stream<List<Map<String, dynamic>>> feedStream() {
    return _sb
        .from('posts')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  Future<bool> isLikedByMe(String postId) async {
    final uid = _sb.auth.currentUser!.id;
    final row = await _sb
        .from('post_likes')
        .select('post_id')
        .eq('post_id', postId)
        .eq('user_id', uid)
        .maybeSingle();
    return row != null;
  }

  Future<void> like(String postId) async {
    final uid = _sb.auth.currentUser!.id;
    await _sb.from('post_likes').insert({'post_id': postId, 'user_id': uid});
  }

  Future<void> unlike(String postId) async {
    final uid = _sb.auth.currentUser!.id;
    await _sb
        .from('post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', uid);
  }

  Future<void> addComment(String postId, String text) async {
    final uid = _sb.auth.currentUser!.id;
    await _sb.from('post_comments').insert({
      'post_id': postId,
      'user_id': uid,
      'text': text,
    });
  }

  Future<void> share(String postId) async {
    final uid = _sb.auth.currentUser!.id;
    await _sb.from('post_shares').insert({'post_id': postId, 'user_id': uid});
  }

  Future<List<Map<String, dynamic>>> likers(String postId) async {
    final likes = await _sb
        .from('post_likes')
        .select('user_id, created_at')
        .eq('post_id', postId)
        .order('created_at', ascending: false);

    if (likes.isEmpty) return [];

    final ids =
        (likes as List).map((e) => (e as Map)['user_id'] as String).toList();

    final uniqIds = ids.toSet().toList();
    if (uniqIds.isEmpty) return [];
    final idsSql = '(${uniqIds.map((e) => '"$e"').join(',')})';

    final profiles = await _sb
        .from('profiles')
        .select('id, display_name, avatar_url')
        .filter('id', 'in', idsSql);

    final byId = {
      for (final p in (profiles as List))
        (p as Map)['id'] as String: p as Map<String, dynamic>
    };

    return [
      for (final l in likes)
        {
          'user_id': (l as Map)['user_id'],
          'created_at': l['created_at'],
          'display_name': byId[l['user_id']]?['display_name'] as String?,
          'avatar_url': byId[l['user_id']]?['avatar_url'] as String?,
        }
    ];
  }

  Future<List<Map<String, dynamic>>> comments(String postId) async {
    final rows = await _sb
        .from('post_comments')
        .select('id, user_id, text, created_at')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    if (rows.isEmpty) return [];

    final ids = (rows as List)
        .map((e) => (e as Map)['user_id'] as String)
        .toSet()
        .toList();

    if (ids.isEmpty) return rows.cast<Map<String, dynamic>>();

    // Supabase Dart: "in" filtresini string ile veririz
    final idsSql = '(${ids.map((e) => '"$e"').join(',')})';

    final profiles = await _sb
        .from('profiles')
        .select('id, display_name, avatar_url')
        .filter('id', 'in', idsSql);

    final byId = {
      for (final p in (profiles as List))
        (p as Map)['id'] as String: p as Map<String, dynamic>
    };

    return [
      for (final r in rows)
        {
          ...r,
          'display_name': byId[r['user_id']]?['display_name'],
          'avatar_url': byId[r['user_id']]?['avatar_url'],
        }
    ];
  }
}

final postRepo = PostRepo();
