import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:silab/constants/route_constants.dart';
import 'package:silab/enums/menu_action.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';
import 'package:silab/utilities/dialogs/confirmation_dialog.dart';
import 'package:silab/utilities/dialogs/delete_dialog.dart';
import 'package:silab/utilities/generics/get_arguments.dart';

import '../../services/cloud/room.dart';
import '../../services/cloud/tool.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({Key? key}) : super(key: key);

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
    return FutureBuilder<Room>(
      future: fetchRooms(),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: FutureBuilder<Room>(
              future: fetchRooms(),
              builder: (context, snapshot) {
                return Text('Daftar Alat ${snapshot.data?.name}');
              },
            ),
            actions: [
              IconButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(adminCreateToolRoute, arguments: reference),
                  icon: const Icon(Icons.add)),
            ],
          ),
          body: StreamBuilder<QuerySnapshot<Tool>>(
            stream: allTools(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
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
      },
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

  void _onSelected(MenuItemAction value) async {}

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.network('${tool.image}'),
      title: Text(tool.name),
      subtitle: Text('Jumlah Unit : ${tool.quantity}'),
      trailing: _buildPoupMenuButton(context),
    );
  }

  PopupMenuButton<MenuItemAction> _buildPoupMenuButton(BuildContext context) {
    return PopupMenuButton<MenuItemAction>(
      onSelected: (value) async {
        switch (value) {
          case MenuItemAction.edit:
            Navigator.of(context)
                .pushNamed(adminEditToolRoute, arguments: reference);
            break;
          case MenuItemAction.delete:
            final shouldDelete = await showDeleteDialog(context);
            if (shouldDelete) {
              await reference.delete();
            }
            break;
        }
      },
      itemBuilder: (context) => popupMenuItems,
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
