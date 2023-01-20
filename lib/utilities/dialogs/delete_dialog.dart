import 'package:flutter/material.dart';
import 'package:silab/utilities/dialogs/generic_dialog.dart';

Future<bool> showDeleteDialog(BuildContext context) async {
  return showGenericDialog<bool>(
    context: context,
    title: 'Perhatian',
    content: 'Apakah anda yakin ingin menghapus data ini ?',
    optionsBuilder: () => {
      'Iya': true,
      'Tidak': false,
    },
  ).then((value) => value ?? false);
}
