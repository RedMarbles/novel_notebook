import 'package:flutter/material.dart';
import 'package:novelnotebook/models.dart' as models;
import 'package:flex_color_picker/flex_color_picker.dart' as flex;

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
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.pop(context, null);
          },
        ),
        TextButton(
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
  bool markDangerous = false,
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
          style: (markDangerous)
              ? ButtonStyle(
                  foregroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.error),
                )
              : null,
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

Future<models.Note> showNoteEditDialog(
  BuildContext context, {
  models.Note note,
  @required String title,
  String okButtonText = 'OK',
  String cancelButtonText = 'Cancel',
}) async {
  final double chapterNum = note?.chapter ?? 1;
  final String message = note?.message ?? '';

  final cnController = TextEditingController(text: chapterNum.toString());
  final msgController = TextEditingController(text: message);

  final resultNote = await showDialog<models.Note>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text('Chapter: '),
              Expanded(
                child: TextField(
                  controller: cnController,
                  keyboardType: TextInputType.numberWithOptions(
                      signed: false, decimal: true),
                  decoration: InputDecoration(border: OutlineInputBorder()),
                ),
              ),
              // TODO: Show a button for quickly adding one to the chapter number
            ],
          ),
          SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: Text('Note: ')),
          Expanded(
            child: TextField(
              controller: msgController,
              decoration: InputDecoration(
                  hintText: 'Note', border: OutlineInputBorder()),
              keyboardType: TextInputType.multiline,
              maxLines: null,
            ),
          )
        ],
      ),
      actions: [
        TextButton(
          child: Text(cancelButtonText),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(okButtonText),
          onPressed: () {
            Navigator.pop(
                context,
                models.Note(
                  note?.noteId ?? -1,
                  msgController.text,
                  double.parse(
                      cnController.text), // TODO: Handle validation of number
                ));
          },
        ),
      ],
    ),
  );

  return resultNote;
}

Future<int> showOptionsDialog(BuildContext context, List<String> optionsStrings,
    {String title = 'Options'}) async {
  final int resultIdx = await showDialog<int>(
    context: context,
    builder: (_) => SimpleDialog(
      title: Text(title),
      children: List<Widget>.generate(
        optionsStrings.length,
        (index) => SimpleDialogOption(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          child: Text(optionsStrings[index]),
          onPressed: () {
            Navigator.pop(context, index);
          },
        ),
      ),
    ),
  );

  return resultIdx;
}

Future<int> showColorPickerDialog(BuildContext context, Color origColor,
    {String title = 'Select Color:'}) async {
  final Color resultColor = await flex.showColorPickerDialog(
    context,
    origColor,
    pickersEnabled: {
      flex.ColorPickerType.both: false,
      flex.ColorPickerType.primary: true,
      flex.ColorPickerType.accent: true,
      flex.ColorPickerType.bw: false,
      flex.ColorPickerType.custom: false,
      flex.ColorPickerType.wheel: true,
    },
    heading: Text(title, style: Theme.of(context).textTheme.headline5),
    subheading: Text('Select Color Shade'),
    showColorCode: true,
  );

  return resultColor?.value;
}
