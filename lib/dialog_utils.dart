import 'package:flutter/material.dart';

// Dialog to accept a string as input from the user
Future<String> showTextEditDialog(BuildContext context,
    {String value = "", String title = 'Edit:', String hintText = ''}) async {
  final controller = TextEditingController(text: value);
  String res = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        decoration:
            InputDecoration(hintText: hintText, border: OutlineInputBorder()),
      ),
      actions: [
        FlatButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.pop(context, null);
          },
        ),
        FlatButton(
            child: Text('Accept'),
            onPressed: () {
              Navigator.pop(context, controller.value.text);
            }),
      ],
    ),
  );

  return res;
}

// Dialog to ask the user a yes/no question
Future<bool> showConfirmationDialog(
  BuildContext context, {
  @required String message,
  String title = 'Confirmation',
  String okButtonText = 'Yes',
  String cancelButtonText = 'No',
  bool defaultValue = false,
}) async {
  bool res = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          child: Text(cancelButtonText),
          onPressed: () {
            Navigator.pop(context, false);
          },
        ),
        TextButton(
          child: Text(okButtonText),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
      ],
    ),
  );

  return res ?? defaultValue;
}

Future<void> showMessageDialog(
  BuildContext context, {
  @required String message,
  String title = 'Alert!',
  String okButtonText = 'OK',
}) async {
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          child: Text(okButtonText),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    ),
  );
}
