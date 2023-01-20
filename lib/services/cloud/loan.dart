import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:silab/enums/loan_status.dart';
import 'package:silab/services/cloud/room.dart';
import 'package:silab/services/cloud/tool.dart';

const isApprovedField = 'is_approved';
const roomIdField = 'room';
const toolsField = 'tools';
const startTimeField = 'start_time';
const endTimeField = 'end_time';
const createdAtField = 'created_at';
const updatedAtField = 'updated_at';
const userIdField = 'user_id';

class Loan {
  final bool isApproved;
  final String userId;
  final LoanStatus status;
  final Room? room;
  final List<Tool> tools;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    required this.isApproved,
    required this.userId,
    required this.status,
    required this.room,
    required this.tools,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Loan.create({
    required DateTime selectedDate,
    required String userId,
  }) {
    Loan loan = Loan(
      isApproved: false,
      room: null,
      status: LoanStatus.pending,
      userId: userId,
      tools: [],
      startTime: selectedDate,
      endTime: selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return loan;
  }

  Loan copyWith({
    bool? isApproved,
    String? userId,
    LoanStatus? loanStatus,
    Room? room,
    List<Tool>? tools,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Loan(
      isApproved: isApproved ?? this.isApproved,
      userId: userId ?? this.userId,
      room: room ?? this.room,
      tools: tools ?? this.tools,
      status: loanStatus ?? status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Loan.fromJson(Map<String, Object?> json)
      : this(
          isApproved: json[isApprovedField] as bool,
          room: json['room'] == null
              ? null
              : Room.fromJson(json['room'] as Map<String, Object?>),
          userId: json[userIdField] as String,
          tools: (json['tools'] as List)
              .cast<Map<String, Object?>>()
              .map((e) => Tool.fromJson(e))
              .toList(),
          status: describeEnum(json['status'] as String),
          startTime: (json[startTimeField] as Timestamp).toDate(),
          endTime: (json[endTimeField] as Timestamp).toDate(),
          createdAt: (json[createdAtField] as Timestamp).toDate(),
          updatedAt: (json[updatedAtField] as Timestamp).toDate(),
        );

  Map<String, dynamic> toJson() {
    return {
      isApprovedField: isApproved,
      userIdField: userId,
      'status': status.name,
      roomIdField: room?.toJson(),
      toolsField: tools.map((e) => e.toJson()).toList(),
      startTimeField: Timestamp.fromDate(startTime),
      endTimeField: Timestamp.fromDate(endTime),
      createdAtField: Timestamp.fromDate(createdAt),
      updatedAtField: Timestamp.fromDate(updatedAt),
    };
  }

  List<Object?> get props => [];
}
