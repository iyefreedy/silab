import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:silab/services/auth/auth_user.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Pengguna'),
      ),
      body: StreamBuilder<QuerySnapshot<AuthUser>>(
        stream: FirebaseCloudStorage().allUsers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final users = snapshot.requireData;
          return ListView.builder(
            itemCount: users.size,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text('Nama Pengguna : ${users.docs[index].data().name}'),
              );
            },
          );
        },
      ),
    );
  }
}
