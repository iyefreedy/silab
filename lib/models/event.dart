import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String userId;
  final bool isApproved;
  final Timestamp startTime;
  final Timestamp endTime;

  Event({
    required this.id,
    required this.userId,
    required this.isApproved,
    required this.startTime,
    required this.endTime,
  });

  Event.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> snapshot)
      : id = snapshot.id,
        userId = snapshot.data()['user_id'],
        isApproved = snapshot.data()['is_approved'],
        startTime = snapshot.data()['start_time'],
        endTime = snapshot.data()['end_time'];
}
