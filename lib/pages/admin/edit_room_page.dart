import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show basename;
import 'package:silab/constants/app_constants.dart';
import 'package:silab/utilities/generics/get_arguments.dart';

import '../../helpers/loading/loading_screen.dart';
import '../../services/cloud/firebase_cloud_storage.dart';
import '../../services/cloud/room.dart';
import '../../utilities/dialogs/confirmation_dialog.dart';
import '../../utilities/dialogs/error_dialog.dart';
import '../../utilities/dialogs/message_dialog.dart';

class EditRoomPage extends StatefulWidget {
  const EditRoomPage({Key? key}) : super(key: key);

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  Future<DocumentReference<Room>> _getExistingRoom(BuildContext context) async {
    final widgetRoom = context.getArgument<DocumentReference<Room>>();

    if (widgetRoom != null) {
      return widgetRoom;
    }

    return Future.error('Document doesn\t exist');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Data Ruangan'),
      ),
      body: FutureBuilder<DocumentReference<Room>>(
        future: _getExistingRoom(context),
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

          final reference = snapshot.requireData;
          return _RoomForm(
            reference: reference,
          );
        },
      ),
    );
  }
}

class _RoomForm extends StatefulWidget {
  const _RoomForm({
    Key? key,
    required this.reference,
  }) : super(key: key);

  final DocumentReference<Room> reference;

  @override
  State<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends State<_RoomForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? _file;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late DocumentReference<Room> reference = widget.reference;

  Future<bool> _onWillPop() async {
    if (_nameController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _file != null) {
      final shouldBack = await showConfirmationDialog(
          context, 'Data belum disimpan', 'Apakah anda yakin ingin keluar ?');

      return shouldBack;
    }

    return false;
  }

  void _onSubmit() async {
    LoadingScreen().show(context: context, text: 'Please wait');
    final name = _nameController.text;
    final description = _descriptionController.text;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      TaskSnapshot? taskSnapshot;
      String? downloadUrl;
      if (_file != null) {
        taskSnapshot = await FirebaseCloudStorage()
            .imagesRef
            .child('room')
            .child(basename(_file!.path))
            .putFile(File(_file!.path));
        // taskSnapshot.
        downloadUrl = await taskSnapshot.ref.getDownloadURL();
      }
      final room = await reference.get();
      final imageUrl = room.data()?.image;

      await widget.reference.update({
        'nama': name,
        'keterangan': description,
        'foto': downloadUrl ?? imageUrl ?? noImageAvailable,
      });
      LoadingScreen().hide();
    } catch (e) {
      LoadingScreen().hide();
      showErrorDialog(context, '$e');
      log('$e');
      return;
    }

    if (!mounted) return;

    await showMessageDialog(
      context,
      'Data berhasil disimpan',
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<Room> _setupListener() async {
    final currentReference = widget.reference;

    final roomSnapshot = await currentReference.get();
    final room = roomSnapshot.data();

    if (room != null) {
      _nameController.text = room.name;
      _descriptionController.text = room.description;

      return room;
    }

    return Future.error('error');
  }

  void _onPickFile() async {
    final filePickerResult = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
    );

    if (filePickerResult == null) {
      return;
    }

    final platformFile = filePickerResult.files.first;
    final file = File(platformFile.path!);

    setState(() {
      _file = file;
    });
  }

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Room>(
      future: _setupListener(),
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

        final room = snapshot.requireData;
        return Form(
          key: _formKey,
          onWillPop: _onWillPop,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListView(
              children: [
                nameController,
                descriptionTextField,
                Card(
                  elevation: 4.0,
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        filePickerButton,
                        _file != null
                            ? Image.file(
                                _file!,
                                width: 150,
                              )
                            : Image.network(
                                room.image,
                                width: 150,
                              ),
                      ],
                    ),
                  ),
                ),
                submitButton,
              ],
            ),
          ),
        );
      },
    );
  }

  ElevatedButton get submitButton {
    return ElevatedButton(
      onPressed: _onSubmit,
      child: const Text('Simpan'),
    );
  }

  TextFormField get descriptionTextField {
    return TextFormField(
      controller: _descriptionController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Deskripsi Ruangan tidak boleh kosong';
        }

        return null;
      },
    );
  }

  TextFormField get nameController {
    return TextFormField(
      controller: _nameController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nama Ruangan tidak boleh kosong';
        }

        return null;
      },
    );
  }

  Align get filePickerButton {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: _onPickFile,
        icon: const Icon(Icons.photo),
        label: const Text('Pilih Gambar'),
      ),
    );
  }
}
