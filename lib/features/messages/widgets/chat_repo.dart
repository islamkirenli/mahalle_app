import 'package:supabase_flutter/supabase_flutter.dart';

class ConversationOverview {
  final String conversationId;
  final String otherUserId;
  final String? otherDisplayName;
  final String? otherAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  ConversationOverview({
    required this.conversationId,
    required this.otherUserId,
    this.otherDisplayName,
    this.otherAvatarUrl,
    this.lastMessage,
    this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationOverview.fromMap(Map<String, dynamic> m) {
    return ConversationOverview(
      conversationId: m['conversation_id'] as String,
      otherUserId: m['other_user_id'] as String,
      otherDisplayName: m['other_display_name'] as String?,
      otherAvatarUrl: m['other_avatar_url'] as String?,
      lastMessage: m['last_message'] as String?,
      lastMessageAt: m['last_message_at'] == null
          ? null
          : DateTime.parse(m['last_message_at'] as String),
      unreadCount: (m['unread_count'] ?? 0) as int,
    );
  }
}

class ChatMessage {
  final int id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) {
    // id bazen num/string gelebilir → int'e güvenli çevir
    final dynamicId = m['id'];
    final intId = switch (dynamicId) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v) ?? 0,
      _ => 0,
    };

    // created_at bazen String, bazen DateTime gelebilir
    final ca = m['created_at'];
    final created = switch (ca) {
      DateTime v => v,
      String v => DateTime.tryParse(v) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      _ => DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    };

    return ChatMessage(
      id: intId,
      conversationId: (m['conversation_id'] ?? m['thread_id'])
          as String, // olası kalıntı için
      senderId: m['sender_id'] as String,
      content: (m['content'] ?? '').toString(),
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() => {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': content,
      };
}

class ChatRepo {
  final SupabaseClient _sb;
  ChatRepo(this._sb);

  String get _uid => _sb.auth.currentUser!.id;

  /// 1-1 sohbeti getirir/oluşturur
  Future<String> getOrCreateConversationWith(String otherUserId) async {
    final res = await _sb.rpc('get_or_create_1to1_conversation', params: {
      'other_user': otherUserId,
    });
    return res as String;
  }

  /// Konuşma listesi (view üzerinden) - tek seferlik fetch
  Future<List<ConversationOverview>> fetchConversations() async {
    final data = await _sb
        .from('v_conversations_overview')
        .select('*')
        .eq('user_id', _uid)
        .order('last_message_at', ascending: false);
    return (data as List)
        .map((e) => ConversationOverview.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Stream<List<ChatMessage>> messagesStream(String conversationId) async* {
    // --- İlk yükleme: hatayı yüzeye çıkar, parse güvenli ---
    try {
      final initial = await _sb
          .from('messages')
          .select('id, conversation_id, sender_id, content, created_at')
          .eq('conversation_id', conversationId)
          .order('id', ascending: true);

      yield (initial as List)
          .map((e) => ChatMessage.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // ilk yükleme hatası durumunda en azından boş liste ver
      yield const <ChatMessage>[];
    }

    // --- Realtime ---
    yield* _sb
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('id', ascending: true)
        .map((rows) => rows
            .map((e) => ChatMessage.fromMap(e as Map<String, dynamic>))
            .toList());
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final payload = {
      'conversation_id': conversationId,
      'sender_id': _uid,
      'content': text,
    };
    // RLS/insert hatasını yüzeye çıkarmak için:
    await _sb.from('messages').insert(payload).select().single();
  }

  /// Sohbeti açınca okundu say
  Future<void> markConversationRead(String conversationId) async {
    await _sb
        .from('conversation_participants')
        .update({'last_read_at': DateTime.now().toIso8601String()}).match(
            {'conversation_id': conversationId, 'user_id': _uid});
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    return await _sb
        .from('profiles')
        .select('id, display_name, avatar_url, photo_url')
        .ilike('display_name', '%$q%')
        .neq('id', _uid)
        .limit(20);
  }
}
