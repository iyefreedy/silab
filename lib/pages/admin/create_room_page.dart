import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show basename;

import '../../helpers/loading/loading_screen.dart';
import '../../services/cloud/firebase_cloud_storage.dart';
import '../../services/cloud/room.dart';
import '../../utilities/dialogs/error_dialog.dart';
import '../../utilities/dialogs/logout_dialog.dart';
import '../../utilities/dialogs/message_dialog.dart';

class CreateRoomPage extends StatefulWidget {
  const CreateRoomPage({Key? key}) : super(key: key);

  @override
  State<CreateRoomPage> createState() => _CreateRoomPageState();
}

class _CreateRoomPageState extends State<CreateRoomPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late FirebaseCloudStorage _cloudStorage;

  File? _file;
  DocumentReference<Room>? _room;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<DocumentReference<Room>> _createRoom() async {
    final existingRoom = _room;
    if (existingRoom != null) {
      return existingRoom;
    }
    final fetchedRoom = await _cloudStorage.addRoom();

    _room = fetchedRoom;

    return fetchedRoom;
  }

  Future<bool> _onWillPop() async {
    if (_nameController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _file != null) {
      final shouldBack = await showLogOutDialog(context);

      if (shouldBack) {
        await _room?.delete();
        return shouldBack;
      }

      return shouldBack;
    }

    await _room?.delete();

    return true;
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

  void _onSubmit() async {
    LoadingScreen().show(context: context, text: 'Please wait');

    final name = _nameController.text;
    final description = _descriptionController.text;
    final imageRef = _cloudStorage.imagesRef;

    if (!_formKey.currentState!.validate()) {
      LoadingScreen().hide();
      return;
    }

    try {
      TaskSnapshot? taskSnapshot;
      String? downloadUrl;
      if (_file != null) {
        taskSnapshot = await imageRef
            .child('room')
            .child(basename(_file!.path))
            .putFile(File(_file!.path));
        // taskSnapshot.
        downloadUrl = await taskSnapshot.ref.getDownloadURL();
      }
      await _room?.update({
        'nama': name,
        'keterangan': description,
        'foto': downloadUrl,
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

  @override
  void initState() {
    super.initState();
    _cloudStorage = FirebaseCloudStorage();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Data Ruangan'),
      ),
      body: FutureBuilder(
        future: _createRoom(),
        builder: (context, snapshot) {
          return Form(
            key: _formKey,
            onWillPop: _onWillPop,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  nameController,
                  descriptionTextField,
                  filePickerButton,
                  if (_file != null) showRoomImage(context),
                  submitButton,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  TextFormField get descriptionTextField {
    return TextFormField(
      controller: _descriptionController,
      decoration: const InputDecoration(hintText: 'Deskripsi Ruangan'),
      minLines: 1,
      maxLines: 3,
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
      decoration: const InputDecoration(hintText: 'Nama Ruangan'),
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

  ElevatedButton get submitButton {
    return ElevatedButton(
      onPressed: _onSubmit,
      child: const Text('Simpan'),
    );
  }

  Widget showRoomImage(BuildContext context) {
    return Card(
      elevation: 4.0,
      child: Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(8.0),
        child: Image.file(
          _file!,
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
