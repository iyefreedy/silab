import 'package:flutter/material.dart';
import 'package:silab/extensions/buildcontext/loc.dart';
import 'package:silab/utilities/dialogs/generic_dialog.dart';

Future<bool> showConfirmationDialog(
  BuildContext context,
  String title,
  String content,
) {
  return showGenericDialog<bool>(
    context: context,
    title: title,
    content: content,
    optionsBuilder: () => {
      context.loc.cancel: false,
      context.loc.ok: true,
    },
  ).then((value) => value ?? false);
}
