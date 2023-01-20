import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:silab/constants/route_constants.dart';
import 'package:silab/enums/menu_action.dart';
import 'package:silab/services/cloud/firebase_cloud_storage.dart';
import 'package:silab/services/cloud/room.dart';
import 'package:silab/utilities/dialogs/delete_dialog.dart';

class RoomsPage extends StatelessWidget {
  const RoomsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Ruangan'),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(adminCreateRoomRoute),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Room>>(
        stream: FirebaseCloudStorage().allRooms(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('${snapshot.error}'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final rooms = snapshot.requireData;
          return ListView.builder(
            itemCount: rooms.size,
            itemBuilder: (context, index) {
              return _RoomItem(
                room: rooms.docs[index].data(),
                reference: rooms.docs[index].reference,
              );
            },
          );
        },
      ),
    );
  }
}

class _RoomItem extends StatelessWidget {
  const _RoomItem({
    Key? key,
    required this.room,
    required this.reference,
  }) : super(key: key);

  final DocumentReference<Room> reference;
  final Room room;
  @override
  Widget build(BuildContext context) {
    log('message');
    return ListTile(
      leading: Image.network(room.image),
      trailing: _buildPopupMenuButton(context),
      onTap: () => Navigator.of(context)
          .pushNamed(adminToolsRoute, arguments: reference),
      title: Text(room.name),
      subtitle: Text(
        room.description,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  PopupMenuButton<MenuItemAction> _buildPopupMenuButton(BuildContext context) {
    return PopupMenuButton<MenuItemAction>(
      onSelected: (value) async {
        if (value == MenuItemAction.delete) {
          final shouldDelete = await showDeleteDialog(context);
          if (shouldDelete) {
            await reference.delete();
          }
        } else if (value == MenuItemAction.edit) {
          Navigator.of(context)
              .pushNamed(adminEditRoomRoute, arguments: reference);
        }
      },
      itemBuilder: (context) => popupMenuItems,
    );
  }

  List<PopupMenuEntry<MenuItemAction>> get popupMenuItems {
    return const [
      PopupMenuItem(
        value: MenuItemAction.edit,
        child: Text('Ubah'),
      ),
      PopupMenuItem(
        value: MenuItemAction.delete,
        child: Text('Hapus'),
      ),
    ];
  }
}
