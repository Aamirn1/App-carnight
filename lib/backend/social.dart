import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityPost {
  CommunityPost.fromJson(Map<String, dynamic> row)
    : id = row['id'] as String,
      ownerId = row['owner_id'] as String,
      caption = row['caption'] as String,
      name = row['display_name'] as String,
      createdAt = row['created_at'] as String,
      likes = (row['like_count'] as num).toInt(),
      comments = (row['comment_count'] as num).toInt(),
      liked = row['liked'] as bool,
      following = row['following'] as bool,
      images = (row['images'] as List<dynamic>).cast<String>();
  final String id, ownerId, caption, name, createdAt;
  final int likes, comments;
  final bool liked, following;
  final List<String> images;
}

class Conversation {
  Conversation.fromJson(Map<String, dynamic> row)
    : id = row['id'] as String,
      requester = row['requester_id'] as String,
      recipient = row['recipient_id'] as String,
      status = row['status'] as String,
      listingId = row['listing_id'] as String?;
  final String id, requester, recipient, status;
  final String? listingId;
  String other(String me) => requester == me ? recipient : requester;
}

class ChatMessage {
  ChatMessage.fromJson(Map<String, dynamic> row)
    : id = row['id'] as String,
      sender = row['sender_id'] as String,
      body = row['body'] as String,
      createdAt = row['created_at'] as String;
  final String id, sender, body, createdAt;
}

class SocialRepository {
  SocialRepository(this.client);
  final SupabaseClient client;
  String get me =>
      client.auth.currentUser?.id ??
      (throw const AuthException('Sign in required.'));

  Future<List<CommunityPost>> feed({
    bool following = false,
    CommunityPost? before,
  }) async {
    final rows = await client.rpc<List<dynamic>>(
      'cn_feed',
      params: {
        'following_only': following,
        'before_time': before?.createdAt,
        'before_id': before?.id,
      },
    );
    return rows
        .map((row) => CommunityPost.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  String imageUrl(String path) =>
      client.storage.from('cn-media').getPublicUrl(path);
  Future<void> like(String post, bool value) async {
    if (value) {
      await client.from('cn_likes').upsert({
        'user_id': me,
        'post_id': post,
      }, ignoreDuplicates: true);
    } else {
      await client
          .from('cn_likes')
          .delete()
          .eq('user_id', me)
          .eq('post_id', post);
    }
  }

  Future<void> follow(String person, bool value) async {
    if (value) {
      await client.from('cn_follows').upsert({
        'follower_id': me,
        'followed_id': person,
      }, ignoreDuplicates: true);
    } else {
      await client
          .from('cn_follows')
          .delete()
          .eq('follower_id', me)
          .eq('followed_id', person);
    }
  }

  Future<List<Map<String, dynamic>>> comments(String post, {int offset = 0}) =>
      client
          .from('cn_comments')
          .select('id,user_id,body,created_at')
          .eq('post_id', post)
          .order('created_at')
          .order('id')
          .range(offset, offset + 19);
  Future<void> comment(String post, String body) async {
    final text = body.trim();
    if (text.isEmpty || text.length > 500)
      throw ArgumentError('Use 1–500 characters.');
    await client.from('cn_comments').insert({
      'user_id': me,
      'post_id': post,
      'body': text,
    });
  }

  Future<void> deleteComment(String id) async {
    await client.from('cn_comments').delete().eq('id', id).eq('user_id', me);
  }

  Future<List<Map<String, dynamic>>> people(String query) => client
      .from('cn_profiles')
      .select('id,display_name')
      .neq('id', me)
      .ilike('display_name', '%${query.trim()}%')
      .order('display_name')
      .order('id')
      .limit(20);
  Future<void> ensureProfile(String name) async {
    await client.from('cn_profiles').upsert({
      'id': me,
      'display_name': name.trim().isEmpty ? 'Car enthusiast' : name.trim(),
    }, ignoreDuplicates: true);
  }

  Future<Set<String>> followingIds(List<String> people) async {
    if (people.isEmpty) return {};
    final rows = await client
        .from('cn_follows')
        .select('followed_id')
        .eq('follower_id', me)
        .inFilter('followed_id', people);
    return rows.map((r) => r['followed_id'] as String).toSet();
  }

  Future<List<Conversation>> inbox({int offset = 0}) async {
    final rows = await client
        .from('cn_conversations')
        .select()
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + 19);
    return rows.map(Conversation.fromJson).toList();
  }

  Future<Conversation> conversation(String id) async => Conversation.fromJson(
    await client.from('cn_conversations').select().eq('id', id).single(),
  );
  Future<Map<String, String>> names(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows = await client
        .from('cn_profiles')
        .select('id,display_name')
        .inFilter('id', ids);
    return {
      for (final r in rows) r['id'] as String: r['display_name'] as String,
    };
  }

  Future<String> request(String target, {String? listingId}) async =>
      await client.rpc<String>(
            'cn_request_conversation',
            params: {'target_id': target, 'for_listing': listingId},
          );
  Future<void> respond(String conversation, bool accept) async {
    await client.rpc<void>(
      'cn_respond_conversation',
      params: {'conversation': conversation, 'accept_request': accept},
    );
  }

  Future<List<ChatMessage>> messages(
    String conversation, {
    int offset = 0,
  }) async {
    final rows = await client
        .from('cn_messages')
        .select()
        .eq('conversation_id', conversation)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + 29);
    return rows.map(ChatMessage.fromJson).toList();
  }

  Future<void> send(String conversation, String body, String requestId) async {
    final text = body.trim();
    if (text.isEmpty || text.length > 2000)
      throw ArgumentError('Use 1–2000 characters.');
    await client.rpc<String>(
      'cn_send_message',
      params: {
        'conversation': conversation,
        'message_body': text,
        'request_id': requestId,
      },
    );
  }

  Future<void> block(String person, {String name = 'Car enthusiast'}) async {
    await client.from('cn_blocks').upsert({
      'blocker_id': me,
      'blocked_id': person,
      'blocked_label': name,
    }, ignoreDuplicates: true);
  }

  Future<List<Map<String, dynamic>>> blocked() => client
      .from('cn_blocks')
      .select('blocked_id,blocked_label')
      .eq('blocker_id', me)
      .limit(100);
  Future<void> unblock(String person) async {
    await client
        .from('cn_blocks')
        .delete()
        .eq('blocker_id', me)
        .eq('blocked_id', person);
  }

  Future<void> report(String person, String reason) async {
    await client.from('cn_reports').insert({
      'reporter_id': me,
      'reported_user_id': person,
      'reason': reason.trim(),
    });
  }
}
