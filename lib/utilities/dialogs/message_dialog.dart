import 'package:flutter/material.dart';
import 'package:silab/extensions/buildcontext/loc.dart';
import 'package:silab/utilities/dialogs/generic_dialog.dart';

Future<void> showMessageDialog(
  BuildContext context,
  String message,
) {
  return showGenericDialog<void>(
    context: context,
    title: 'Pesan',
    content: message,
    optionsBuilder: () => {
      context.loc.ok: true,
    },
  );
}
