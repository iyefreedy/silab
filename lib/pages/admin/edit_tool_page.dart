import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' show basename;
import 'package:silab/constants/app_constants.dart';
import 'package:silab/utilities/generics/get_arguments.dart';

import '../../helpers/loading/loading_screen.dart';
import '../../services/cloud/firebase_cloud_storage.dart';
import '../../services/cloud/tool.dart';
import '../../utilities/dialogs/confirmation_dialog.dart';
import '../../utilities/dialogs/error_dialog.dart';
import '../../utilities/dialogs/message_dialog.dart';

class EditToolPage extends StatelessWidget {
  const EditToolPage({Key? key}) : super(key: key);

  Future<DocumentReference<Tool>> _getExistingTool(BuildContext context) async {
    final widgetTool = context.getArgument<DocumentReference<Tool>>();

    if (widgetTool != null) {
      return widgetTool;
    }

    return Future.error('Document doesn\t exist');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Ubah Data Alat'),
      ),
      body: FutureBuilder<DocumentReference<Tool>>(
        future: _getExistingTool(context),
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
          return _ToolForm(
            reference: reference,
          );
        },
      ),
    );
  }
}

class _ToolForm extends StatefulWidget {
  const _ToolForm({
    Key? key,
    required this.reference,
  }) : super(key: key);

  final DocumentReference<Tool> reference;

  @override
  State<_ToolForm> createState() => _ToolFormState();
}

class _ToolFormState extends State<_ToolForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? _file;
  String? downloadUrl;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _purchasedDateController;
  DateTime purchasedDate = DateTime.now();
  String? status = 'Tersedia';

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
    final quantity = int.parse(_quantityController.text);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      TaskSnapshot? taskSnapshot;

      if (_file != null) {
        taskSnapshot = await FirebaseCloudStorage()
            .imagesRef
            .child('tool')
            .child(basename(_file!.path))
            .putFile(File(_file!.path));
        // taskSnapshot.
        downloadUrl = await taskSnapshot.ref.getDownloadURL();
      }
      await widget.reference.update({
        'nama': name,
        'keterangan': description,
        'foto': downloadUrl,
        'kuantitas': quantity,
        'status': status,
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

  Future<Tool> _setupListener() async {
    final currentReference = widget.reference;

    final roomSnapshot = await currentReference.get();
    final tool = roomSnapshot.data();

    if (tool != null) {
      _nameController.text = tool.name;
      _descriptionController.text = tool.description;
      _quantityController.text = tool.quantity.toString();
      downloadUrl = tool.image;
      return tool;
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
    _quantityController = TextEditingController();
    _purchasedDateController = TextEditingController(
        text: DateFormat('dd-MM-yyyy').format(purchasedDate));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Tool>(
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
                quantityController,
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
                                room.image ?? noImageAvailable,
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
      maxLines: 5,
      minLines: 3,
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

  TextFormField get quantityController {
    return TextFormField(
      controller: _quantityController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
