import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/board_message.dart';

class BoardService {
  BoardService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  CollectionReference<Map<String, dynamic>> get _messages =>
      _db.collection('messages');

  Stream<List<BoardMessage>> watchMessages() => _messages
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(BoardMessage.fromDocument).toList());

  Future<void> createMessage({
    required String operationId,
    required String authorUid,
    required String authorName,
    required String text,
  }) async {
    final ref = _messages.doc(operationId);
    await _db.runTransaction((transaction) async {
      if ((await transaction.get(ref)).exists) return;
      transaction.set(ref, {
        'authorUid': authorUid,
        'authorName': authorName,
        'text': text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
        'schemaVersion': 2,
      });
    });
  }

  Future<void> updateMessage(String id, String text) =>
      _messages.doc(id).update({
        'text': text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 2,
      });
  Future<void> deleteMessage(String id) => _messages.doc(id).delete();
}
