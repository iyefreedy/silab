import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:silab/constants/app_constants.dart';
import 'package:silab/enums/loan_status.dart';
import 'package:silab/services/auth/auth_user.dart';
import 'package:silab/services/cloud/loan.dart';
import 'package:silab/services/cloud/room.dart';
import 'package:silab/services/cloud/tool.dart';
import 'package:http/http.dart' as http;

class FirebaseCloudStorage {
  final usersCollection =
      FirebaseFirestore.instance.collection('users').withConverter<AuthUser>(
            fromFirestore: (snapshot, _) => AuthUser.fromJson(snapshot.data()!),
            toFirestore: (user, _) => user.toJson(),
          );

  // Room Collection
  final roomsCollection =
      FirebaseFirestore.instance.collection('rooms').withConverter<Room>(
            fromFirestore: (snapshot, _) => Room.fromJson(snapshot.data()!),
            toFirestore: (room, _) => room.toJson(),
          );

  // Tool Collection
  final toolsCollection = FirebaseFirestore.instance
      .collection('tools')
      .withConverter<Tool>(
          fromFirestore: (snapshot, _) => Tool.fromJson(snapshot.data()!),
          toFirestore: (tool, _) => tool.toJson());

  // Loan collection
  final loansCollection = FirebaseFirestore.instance
      .collection('loans')
      .withConverter<Loan>(
          fromFirestore: (snapshot, _) => Loan.fromJson(snapshot.data()!),
          toFirestore: (loan, _) => loan.toJson());

  final imagesRef = FirebaseStorage.instance.ref('images');

  Stream<QuerySnapshot<AuthUser>> allUsers() {
    return usersCollection.where('role', isNotEqualTo: 'admin').snapshots();
  }

  Future<Map<String, Object?>> getUserByRole({
    required String role,
    required String uniqueNumber,
  }) async {
    final document = await FirebaseFirestore.instance
        .collection(role)
        .doc(uniqueNumber)
        .get();

    return document.data()!;
  }

  Future<AuthUser> getUser({
    required String userId,
    required AuthUser user,
  }) async {
    final document = await usersCollection.doc(userId).get();

    if (!document.exists) {
      await usersCollection.doc(userId).set(user);
      final newDocument = await usersCollection.doc(userId).get();

      return newDocument.data()!;
    }

    return document.data()!;
  }

  Future<AuthUser> getUserById({
    required String userId,
  }) async {
    try {
      final document = await usersCollection.doc(userId).get();
      log('${document.data()?.name}');

      return document.data()!;
    } on FirebaseException catch (e, s) {
      log('Error Message : ${e.message}');
      log('Error Code : ${e.code}');
      log('$s');
      throw Exception(e.message);
    } on Exception catch (x) {
      log('$x');
      rethrow;
    }
  }

  Stream<QuerySnapshot<Room>> allRooms() {
    final roomQuerySnapshots = roomsCollection.snapshots();

    return roomQuerySnapshots;
  }

  Future<DocumentReference<Room>> addRoom() async {
    final room = Room(name: '', description: '', image: noImageAvailable);

    final document = await roomsCollection.add(room);

    return document;
  }

  Stream<QuerySnapshot<Tool>> allTools({
    DocumentReference<Room>? room,
  }) {
    if (room == null) return toolsCollection.snapshots();
    final toolsQuerySnapshot =
        toolsCollection.where('roomId', isEqualTo: room.id).snapshots();

    return toolsQuerySnapshot;
  }

  Future<QuerySnapshot<Tool>> fetchTools({
    DocumentReference<Room>? room,
  }) async {
    if (room == null) {
      return Future.error('Silahkan pilih ruangan terlebih dahulu');
    }

    try {
      final toolsQuerySnapshot =
          await toolsCollection.where('roomId', isEqualTo: room.id).get();

      return toolsQuerySnapshot;
    } on FirebaseException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<DocumentReference<Tool>> addTool(String roomId) async {
    final tool = Tool(
      roomId: roomId,
      name: '',
      description: '',
      image: noImageAvailable,
      quantity: 0,
      status: 'Tersedia',
      purchasedDate: DateTime.now(),
    );

    final document = await toolsCollection.add(tool);

    return document;
  }

  Stream<QuerySnapshot<Loan>> allLoans({LoanStatus? status}) {
    try {
      if (status != null) {
        return loansCollection
            .where('status', isEqualTo: status.name)
            .snapshots();
      } else {
        return loansCollection.snapshots();
      }
    } on FirebaseException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<Room> fetchRoom(Room room) async {
    final roomQuery = await roomsCollection
        .where(
          'room',
          isEqualTo: room,
        )
        .limit(1)
        .get();

    return roomQuery.docs.first.data();
  }

  Future<DocumentReference<Loan>> createLoanRef(
      DateTime selectedDate, String userId) async {
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

    final loanQuerySnapshot = await loansCollection.add(loan);

    return loanQuerySnapshot;
  }

  Future<Loan> createLoan(DateTime selectedDate, String userId) async {
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

    final document = await loansCollection.add(loan);

    final fetchedLoan = await document.get();

    return fetchedLoan.data()!;
  }

  Future<Map<String, Room>> fetchAvailableRoom() async {
    final collection = await roomsCollection.get();

    Map<String, Room> maps = {};

    for (var doc in collection.docs) {
      maps[doc.id] = doc.data();
    }

    return maps;
  }

  Future<List<Tool>> fetchAvailableTools(String? roomId) async {
    final collection =
        await toolsCollection.where('roomId', isEqualTo: roomId).get();

    return collection.docs.map((e) => e.data()).toList();
  }

  Stream<QuerySnapshot<Loan>> getLoanBySelectedTime({
    required int? month,
    required int? year,
  }) {
    try {
      final dateTime = year == null || month == null
          ? DateTime.now()
          : DateTime(year, month);
      final startDay =
          Timestamp.fromDate(DateTime(dateTime.year, dateTime.month, 1));
      final endDay =
          Timestamp.fromDate(DateTime(dateTime.year, dateTime.month, 30));

      final query = loansCollection
          .where('start_time',
              isLessThanOrEqualTo: endDay, isGreaterThanOrEqualTo: startDay)
          .orderBy('start_time', descending: true);
      final snapshot = query.snapshots();

      return snapshot;
    } on FirebaseException catch (e, s) {
      log('Error Message : ${e.message}');
      log('Error Code : ${e.code}');
      log('StackTrace : $s');
      throw Exception(e.message);
    }
  }

  Future<void> addLoan({
    required String userId,
    required Room? room,
    required List<Tool> tools,
    required DateTime? startTime,
    required DateTime? endTime,
  }) async {
    try {
      if (room == null) {
        throw Exception('Ruangan tidak boleh kosong');
      }

      if (startTime == null || endTime == null) {
        throw Exception('Silahkan pilih waktu');
      }

      final availableLoanStart = await loansCollection
          .where('start_time', whereIn: [startTime, endTime]).get();
      final availableLoanEnd = await loansCollection
          .where('end_time', whereIn: [startTime, endTime]).get();

      if (availableLoanStart.docs.isNotEmpty ||
          availableLoanEnd.docs.isNotEmpty) {
        throw Exception('Waktu yang dipilih tidak tersedia');
      }

      await loansCollection.add(Loan(
        isApproved: false,
        userId: userId,
        status: LoanStatus.pending,
        room: room,
        tools: tools,
        startTime: startTime,
        endTime: endTime,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    } on FirebaseException catch (_) {
      rethrow;
    }
  }

  Stream<QuerySnapshot<Loan>> userLoan({
    required String userId,
    String? status,
  }) {
    var userLoanQuery = loansCollection.where('user_id', isEqualTo: userId);

    if (status != null) {
      userLoanQuery = loansCollection
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: status);
    }

    return userLoanQuery.snapshots();
  }

  void sendPushMessage(String body, String title, String token) async {
    log('$token');
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'key=AIzaSyATJStV4FjIbDtFiWwO0wj-DRnpSMLK_z8',
        },
        body: jsonEncode(
          <String, dynamic>{
            'notification': <String, dynamic>{
              'body': body,
              'title': title,
            },
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done'
            },
            "to": token,
          },
        ),
      );
      print('done');
    } catch (e) {
      print("error push notification");
    }
  }

  static final FirebaseCloudStorage _shared = FirebaseCloudStorage._();
  FirebaseCloudStorage._();
  factory FirebaseCloudStorage() => _shared;
}
