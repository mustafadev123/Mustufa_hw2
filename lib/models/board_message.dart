import 'package:cloud_firestore/cloud_firestore.dart';

class BoardMessage {
  const BoardMessage({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.schemaVersion,
  });
  final String id, authorUid, authorName, text;
  final DateTime? createdAt, updatedAt;
  final int schemaVersion;
  factory BoardMessage.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? const <String, dynamic>{};
    DateTime? date(Object? value) => value is Timestamp ? value.toDate() : null;
    return BoardMessage(
      id: doc.id,
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Unknown',
      text: data['text'] as String? ?? '',
      createdAt: date(data['createdAt']),
      updatedAt: date(data['updatedAt']),
      schemaVersion: data['schemaVersion'] as int? ?? 1,
    );
  }
}
