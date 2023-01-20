import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' show basename;
import 'package:silab/services/cloud/firebase_cloud_storage.dart';
import 'package:silab/utilities/dialogs/confirmation_dialog.dart';
import 'package:silab/utilities/generics/get_arguments.dart';

import '../../helpers/loading/loading_screen.dart';
import '../../services/cloud/room.dart';
import '../../services/cloud/tool.dart';
import '../../utilities/dialogs/error_dialog.dart';
import '../../utilities/dialogs/message_dialog.dart';

class CreateToolPage extends StatefulWidget {
  const CreateToolPage({Key? key}) : super(key: key);

  @override
  State<CreateToolPage> createState() => _CreateToolPageState();
}

class _CreateToolPageState extends State<CreateToolPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DocumentReference<Tool>? _tool;
  File? _file;
  DateTime purchasedDate = DateTime.now();
  String? status = 'Tersedia';

  late FirebaseCloudStorage _cloudStorage;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _purchasedDateController;

  Future<Room> fetchRoom(BuildContext context) async {
    final reference = context.getArgument<DocumentReference<Room>>();
    if (reference == null) {
      return Future.error('Reference not provided');
    }

    final document = await reference.get();

    return document.data()!;
  }

  Future<DocumentReference<Tool>> createTool(BuildContext context) async {
    final roomReference = context.getArgument<DocumentReference<Room>>();

    if (roomReference == null) {
      return Future.error('Room reference not provided');
    }

    final existingTool = _tool;
    if (existingTool != null) {
      return existingTool;
    }

    final newTool = await _cloudStorage.addTool(roomReference.id);

    _tool = newTool;
    return newTool;
  }

  Future<bool> _onWillPop() async {
    if (_nameController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _file != null) {
      final shouldBack = await showConfirmationDialog(
        context,
        'Data belum tersimpan',
        'Apakah anda yakin ingin kembali ?',
      );

      if (shouldBack) {
        await _tool?.delete();
        return shouldBack;
      }

      return shouldBack;
    }

    await _tool?.delete();

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
    final quantity = int.tryParse(_quantityController.text);
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
      await _tool?.update({
        'nama': name,
        'keterangan': description,
        'kuantitas': quantity ?? 0,
        'foto': downloadUrl,
        'tanggalBeli': Timestamp.fromDate(purchasedDate),
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
    _quantityController = TextEditingController();
    _purchasedDateController = TextEditingController(
        text: DateFormat('dd-MM-yyyy').format(purchasedDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<Room>(
          future: fetchRoom(context),
          builder: (context, snapshot) {
            return Text('Form Alat ${snapshot.data?.name}');
          },
        ),
      ),
      body: FutureBuilder<DocumentReference<Tool>>(
        future: createTool(context),
        builder: (context, snapshot) {
          return Form(
            key: _formKey,
            onWillPop: _onWillPop,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  nameTextField,
                  descriptionTextField,
                  quantityTextField,
                  DropdownButton<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(
                        value: 'Tersedia',
                        child: Text('Tersedia'),
                      ),
                      DropdownMenuItem(
                        value: 'Tidak Tersedia',
                        child: Text('Tidak Tersedia'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        status = value;
                      });
                    },
                  ),
                  TextFormField(
                    controller: _purchasedDateController,
                    keyboardType: TextInputType.datetime,
                    onTap: () async {
                      final dateTime = await showDatePicker(
                        context: context,
                        initialDate: purchasedDate,
                        firstDate: DateTime(2010),
                        lastDate: DateTime.now(),
                      );

                      if (dateTime != null) {
                        setState(() {
                          purchasedDate = dateTime;
                          _purchasedDateController.text =
                              DateFormat('dd-MM-yyyy').format(dateTime);
                        });
                      }
                    },
                    decoration: const InputDecoration(
                      hintText: 'Tanggal Beli',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Tanggal beli alat tidak boleh kosong';
                      }

                      return null;
                    },
                  ),
                  filePickerButton,
                  if (_file != null) _showToolImage(context),
                  submitButton,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  ElevatedButton get submitButton {
    return ElevatedButton(
      onPressed: _onSubmit,
      child: const Text('Simpan'),
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

  TextFormField get quantityTextField {
    return TextFormField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        hintText: 'Jumlah unit',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Jumlah unit alat tidak boleh kosong';
        }

        return null;
      },
    );
  }

  TextFormField get descriptionTextField {
    return TextFormField(
      controller: _descriptionController,
      minLines: 3,
      maxLines: 5,
      decoration: const InputDecoration(
        hintText: 'Masukkan deskripsi alat',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Deskripsi tidak boleh kosong';
        }

        return null;
      },
    );
  }

  TextFormField get nameTextField {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        hintText: 'Masukkan nama alat',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Nama Alat tidak boleh kosong';
        }

        return null;
      },
    );
  }

  Widget _showToolImage(BuildContext context) {
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
