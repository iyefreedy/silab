import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:silab/constants/route_constants.dart';
import 'package:silab/enums/menu_action.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';
import 'package:silab/utilities/generics/get_arguments.dart';

import '../../services/cloud/room.dart';
import '../../services/cloud/tool.dart';

class ToolsView extends StatelessWidget {
  const ToolsView({Key? key}) : super(key: key);

  Future<DocumentReference<Room>> fetchReference(BuildContext context) async {
    final reference = context.getArgument<DocumentReference<Room>>();

    if (reference == null) {
      return Future.error('Reference not provided');
    }

    return reference;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentReference<Room>>(
      future: fetchReference(context),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final reference = snapshot.requireData;
        return _ToolList(reference: reference);
      },
    );
  }
}

class _ToolList extends StatelessWidget {
  const _ToolList({
    Key? key,
    required this.reference,
  }) : super(key: key);

  final DocumentReference<Room> reference;

  Future<Room> fetchRooms() async {
    final document = await reference.get();

    return document.data()!;
  }

  Stream<QuerySnapshot<Tool>> allTools() {
    return FirebaseCloudStorage().allTools(room: reference);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Room>(
          future: fetchRooms(),
          builder: (context, snapshot) {
            return Text('Daftar Alat ${snapshot.data?.name}');
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Tool>>(
        stream: allTools(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView.builder(
              itemCount: 20,
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: ListTile(
                    tileColor: Colors.grey.shade300,
                  ),
                );
              },
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'),
            );
          }

          final tools = snapshot.requireData;
          return ListView.builder(
            itemCount: tools.size,
            itemBuilder: (context, index) {
              return _ToolItem(
                reference: tools.docs[index].reference,
                tool: tools.docs[index].data(),
              );
            },
          );
        },
      ),
    );
  }
}

class _ToolItem extends StatelessWidget {
  const _ToolItem({
    Key? key,
    required this.reference,
    required this.tool,
  }) : super(key: key);

  final DocumentReference<Tool> reference;
  final Tool tool;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(tool.name),
      subtitle: Text('Jumlah Unit : ${tool.quantity}'),
      leading: Image.network('${tool.image}'),
      // trailing: _buildPoupMenuButton(context),
    );
  }

  List<PopupMenuEntry<MenuItemAction>> get popupMenuItems {
    return [
      const PopupMenuItem(
        value: MenuItemAction.edit,
        child: Text('Ubah'),
      ),
      const PopupMenuItem(
        value: MenuItemAction.delete,
        child: Text('Hapus'),
      ),
    ];
  }
}
