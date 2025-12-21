import 'package:supabase_flutter/supabase_flutter.dart';

class FriendService {
  SupabaseClient get _sb => Supabase.instance.client;

  // Enviar solicitud (yo -> otro)
  Future<void> sendRequest({required String toUserId}) async {
    final me = _sb.auth.currentUser;
    if (me == null) throw Exception("No estás logueado");
    if (toUserId == me.id) throw Exception("No puedes enviarte solicitud a ti mismo");

    await _sb.from('friend_requests').insert({
      'requester_id': me.id,
      'addressee_id': toUserId,
      'status': 'pending', // debe existir en tu enum
    });
  }

  // Solicitudes entrantes pendientes (otros -> yo)
  Future<List<FriendRequestItem>> listIncomingPending() async {
    final me = _sb.auth.currentUser;
    if (me == null) throw Exception("No estás logueado");

    final data = await _sb
        .from('friend_requests')
        .select('id,requester_id,created_at')
        .eq('addressee_id', me.id)
        .eq('status', 'pending')
        .order('created_at');

    return (data as List)
        .map((m) => FriendRequestItem.fromMap(m as Map<String, dynamic>))
        .toList();
  }

  // Aceptar solicitud: crea amistad y marca request accepted
  Future<void> acceptRequest({
    required String requestId,
    required String fromUserId,
  }) async {
    final me = _sb.auth.currentUser;
    if (me == null) throw Exception("No estás logueado");

    // 1) Insert friendship (par ordenado)
    final myId = me.id;
    final low = myId.compareTo(fromUserId) < 0 ? myId : fromUserId;
    final high = myId.compareTo(fromUserId) < 0 ? fromUserId : myId;

    // Si ya existe (unique pair), puede fallar: lo manejas con try/catch o onConflict si lo soportas
    await _sb.from('friendships').insert({
      'user_low': low,
      'user_high': high,
    });

    // 2) Update request status + responded_at
    await _sb
        .from('friend_requests')
        .update({
          'status': 'accepted',
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId);
  }

  Future<void> rejectRequest({required String requestId}) async {
    final me = _sb.auth.currentUser;
    if (me == null) throw Exception("No estás logueado");

    await _sb
        .from('friend_requests')
        .update({
          'status': 'rejected',
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId);
  }

  // Lista amistades del usuario actual
  Future<List<FriendSummary>> listFriends() async {
    final me = _sb.auth.currentUser;
    if (me == null) throw Exception("No estás logueado");

    final data = await _sb
        .from('friendships')
        .select('user_low,user_high,created_at')
        .or('user_low.eq.${me.id},user_high.eq.${me.id}')
        .order('created_at', ascending: false);

    final rows = (data as List).cast<Map<String, dynamic>>();

    return rows.map((m) {
      final low = m['user_low'] as String;
      final high = m['user_high'] as String;
      final createdAt = DateTime.parse(m['created_at'] as String);

      final friendId = (low == me.id) ? high : low;

      return FriendSummary(friendUserId: friendId, createdAt: createdAt);
    }).toList();
  }
}

class FriendRequestItem {
  FriendRequestItem({
    required this.id,
    required this.fromUserId,
    required this.createdAt,
  });

  final String id;
  final String fromUserId; // esto representa requester_id
  final DateTime createdAt;

  factory FriendRequestItem.fromMap(Map<String, dynamic> m) {
    return FriendRequestItem(
      id: m['id'] as String,
      fromUserId: m['requester_id'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
    );
  }
}

class FriendSummary {
  FriendSummary({required this.friendUserId, required this.createdAt});

  final String friendUserId;
  final DateTime createdAt;
}
