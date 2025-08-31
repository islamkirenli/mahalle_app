import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PostRepo {
  final _sb = Supabase.instance.client;
  final _uuid = const Uuid();

  Future<String?> uploadImage(File file) async {
    final uid = _sb.auth.currentUser!.id;
    final key = '${uid}/${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.jpg';
    await _sb.storage.from('post-images').upload(key, file);
    // public bucket ise:
    return _sb.storage.from('post-images').getPublicUrl(key);
  }

  Future<void> createPost({required String text, String? imageUrl}) async {
    final uid = _sb.auth.currentUser!.id;

    // kullanıcının district'ini profilden al
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

  // Basit stream (yenileri üste)
  Stream<List<Map<String, dynamic>>> feedStream() {
    return _sb
        .from('posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows);
  }
}

final postRepo = PostRepo();
