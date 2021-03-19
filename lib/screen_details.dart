import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:novelnotebook/database.dart';
import 'package:novelnotebook/dialog_utils.dart';
import 'package:novelnotebook/models.dart' as models;
import 'package:novelnotebook/screen_searchNode.dart';
import 'package:sqflite/sqflite.dart';

/* Screen where the individual details of each item are shown
   1. Show item name
   2. Show parents of item, and allow adding and removing parents
   3. Show and edit alternate names of the item
   4. Show description text of the item, and add or remove description text
 */

class DetailsScreen extends StatefulWidget {
  final Database database;
  final int nodeId;

  const DetailsScreen(this.database, this.nodeId);

  @override
  _DetailsScreenState createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  models.Node node = models.Node(0, "Loading...", 0);
  List<models.Node> parents = [];
  List<models.Nickname> nicknames = [];
  List<models.NoteThread> noteThreads = [];
  Map<int, models.Category> categories = {};

  @override
  void initState() {
    super.initState();

    reloadState();
  }

  void reloadState() {
    Future.wait([
      models.getNode(widget.database, widget.nodeId),
      models.getParents(widget.database, widget.nodeId),
      models.getNicknames(widget.database, widget.nodeId),
      models.getThreadsInNode(widget.database, widget.nodeId),
      models.getCategories(widget.database),
    ]).then((futures) {
      setState(() {
        node = futures[0];
        parents = futures[1];
        nicknames = futures[2];
        noteThreads = futures[3];
        categories = futures[4];
      });
      developer.log(
          "Extracted node ${widget.nodeId} - ${node.name} under category ${node.categoryId}",
          name: 'screen_details._DetailsScreenState.initState()');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(node.name),
        actions: [
          InkWell(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.edit),
            ),
            onTap: _editNodeNameDialog,
          ),
          InkWell(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.add),
            ),
            onTap: _addChildNodeDialog,
          ),
          InkWell(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.delete),
            ),
            onTap: _deleteCurrentNodeDialog,
          ),
          SizedBox(width: 8.0),
        ],
      ),
      body: ListView(
        children: [
          _WrapListViewer(
            parents.map((p) => _parentView(p)).toList(),
            title: 'Parents:',
            addCallback:
                (node.nodeId == ROOT_NODE_ID) ? null : _addParentDialog,
          ),
          _WrapListViewer(
            nicknames.map((n) => _nicknameView(n)).toList(),
            title: 'Alternate names:',
            addCallback: _addNicknameDialog,
          ),
          _categoryViewer(),
          Center(
            child: Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ..._noteThreadList(),
        ],
      ),
    );
  }

  // Dialog box for adding a new child node
  void _addChildNodeDialog() async {
    // Get the ID of the created node
    final newNodeName = await showTextEditDialog(context, title: 'New Node: ');

    if (newNodeName != null) {
      // Create the new node and navigate to it in the editor
      models.Node newNode = await models.addNode(
          widget.database, node, categories[node.categoryId], newNodeName);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailsScreen(widget.database, newNode.nodeId),
        ),
      );
    }
  }

  // Dialog box for deleting the node
  void _deleteCurrentNodeDialog() async {
    final deleted = await showConfirmationDialog(
      context,
      title: 'Deleting Node...',
      message:
          'Are you sure you want to delete the data entry on ${node.name} ?',
      okButtonText: 'Delete',
      cancelButtonText: 'Cancel',
      defaultValue: false,
    );
    // TODO : If node is successfully deleted, pop the navigation stack
  }

  // View a dialog to edit the name of the node
  void _editNodeNameDialog() async {
    final String newName = await showTextEditDialog(context);
    if (newName != null) {
      await models.editNodeName(widget.database, node, newName);
      reloadState();
    }
  }

  Widget _categoryViewer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
      child: Row(
        children: [
          Text('Category: '),
          SizedBox(width: 8.0),
          DropdownButton(
            value: node.categoryId,
            items: categories.keys
                .map((catId) => DropdownMenuItem(
                    value: catId,
                    child: Container(
                      color: Color(categories[catId].catColor),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Text(categories[catId].catName),
                    )))
                .toList(),
            onChanged: (catId) async {
              await models.editNodeCategory(
                widget.database,
                node,
                categories[catId],
              );
              reloadState();
            },
          ),
        ],
      ),
    );
  }

  Widget _parentView(models.Node parent) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1.0),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(parent.name),
          GestureDetector(
            child: Icon(Icons.cancel),
            onTap: () async {
              // Delete parent from list if it has more than 2 parents
              if (parents.length < 2) {
                showMessageDialog(
                  context,
                  title: 'Error!',
                  message: 'Cannot delete the last parent of a node',
                  okButtonText: 'OK',
                );
              } else {
                bool check = await showConfirmationDialog(
                  context,
                  message:
                      'Are you sure you want to remove ${parent.name} as a parent of ${node.name} ?',
                  title: 'Removing parent link...',
                  okButtonText: 'Yes',
                  cancelButtonText: 'No',
                  defaultValue: false,
                );
                if (check) {
                  models.deleteParentRelation(widget.database, parent, node);
                  reloadState();
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _nicknameView(models.Nickname nickname) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            child: Text(nickname.name),
            onTap: () async {
              // Popup to edit nickname
              String res = await showTextEditDialog(context,
                  value: nickname.name,
                  title: 'Edit Nickname:',
                  hintText: 'New nickname...');
              await models.editNickname(widget.database, nickname, res);
              reloadState();
            },
          ),
          InkWell(
            child: Icon(Icons.cancel),
            onTap: () async {
              // Delete nickname from list
              developer.log('Deleting nickname ${nickname.name}');
              bool check = await showConfirmationDialog(context,
                  title: 'Deleting nickname...',
                  message:
                      'Are you sure you want to delete the nickname \'${nickname.name}\'?');
              if (check) {
                await models.deleteNickname(widget.database, nickname);
                reloadState();
              }
            },
          ),
        ],
      ),
    );
  }

  void _addNicknameDialog() async {
    // Dialog to add a new nickname to the node
    String newNickname =
        await showTextEditDialog(context, title: 'Add Nickname: ');
    developer.log('Value returned from Nickname dialog: $newNickname',
        name: 'screen_details._DetailsScreenState._addNicknameDialog()');
    if (newNickname != null) {
      await models.addNickname(widget.database, node, newNickname);
      reloadState();
    }
  }

  void _addParentDialog() async {
    // Dialog to add a new parent to the node
    final models.Node newParent = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SearchNodeScreen(widget.database, [node, ...parents])));
    developer.log('Value returned from Nickname dialog: ${newParent?.name}',
        name: 'screen_details._DetailsScreenState._addNicknameDialog()');
    if (newParent != null) {
      // Add the node as a parent
      await models.addParent(widget.database, node, newParent);
      reloadState();
    }
  }

  List<Widget> _noteThreadList() {
    final result = <Widget>[];
    result.add(_addThreadButton(1));
    for (int idx = 0; idx < noteThreads.length; ++idx) {
      result.add(_NoteThreadViewer(noteThreads[idx], _addNoteButton,
          _editNoteCallback, _deleteNoteCallback));
      result.add(_addThreadButton(idx + 2));
    }
    return result;
  }

  // Button to add a new widget
  Widget _addThreadButton(int idxForNewThread) {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
          margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
          decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.all(
                Radius.circular(8.0),
              )),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.white),
//            SizedBox(width: 8.0),
              Text('Add note thread',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(width: 4.0)
            ],
          ),
        ),
        onTap: () {
          // TODO : Shift all the note threads of the same or lower sequence number than idxForNewThread down
          // TODO : Add the new note thread with the new sequence number
        },
      ),
    );
  }

  Widget _addNoteButton(models.NoteThread noteThread) {
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(),
          ),
          child: Text('Add Note'),
        ),
        onTap: () async {
          // TODO: Suggest the chapter number from the metadata
          final models.Note note = await showNoteEditDialog(
            context,
            title: 'Create new note',
            okButtonText: 'Create',
            cancelButtonText: 'Cancel',
          );

          if (note != null) {
            await models.addNoteToThread(
                widget.database, noteThread, note.chapter,
                message: note.message);
            reloadState();
          }
        },
      ),
    );
  }

  void _editNoteCallback(models.Note note) async {
    developer.log(
        'Starting EditNoteDialog for note ${note.noteId} with original message "${note.message}" and chapter number ${note.chapter}',
        name: 'screen_details._editNoteCallback()');
    final models.Note newNote = await showNoteEditDialog(
      context,
      title: 'Edit note',
      note: note,
      okButtonText: 'Save edits',
      cancelButtonText: 'Cancel',
    );

    if (newNote != null) {
      await models.editNote(
        widget.database,
        note,
        newMessage: newNote.message,
        chapter: newNote.chapter,
      );
      reloadState();
    }
  }

  void _deleteNoteCallback(models.Note note) async {
    final bool check = await showConfirmationDialog(context,
        message:
            'Are you sure you want to delete this note for chapter ${note.chapter} ?');
    if (check) {
      await models.deleteNote(widget.database, note);
      reloadState();
    }
  }
}

class _WrapListViewer extends StatelessWidget {
  // Title of the WrapListViewer widget
  final String title;

  // The widgets to show in the WrapList
  final List<Widget> items;

  // The callback function to call when the + button is pressed
  final Function() addCallback;

  _WrapListViewer(this.items, {this.title, this.addCallback});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
          border: Border.all(width: 2, color: Colors.grey),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
            child: Text(title),
          ),
          Wrap(
            direction: Axis.horizontal,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...items,
              (addCallback == null)
                  ? SizedBox()
                  : InkWell(
                      child: Icon(Icons.add),
                      onTap: addCallback,
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoteThreadViewer extends StatelessWidget {
  final models.NoteThread noteThread;
  final Function(models.NoteThread) addNoteButton;
  final Function(models.Note) editNoteCallback;
  final Function(models.Note) deleteNoteCallback;

  _NoteThreadViewer(this.noteThread, this.addNoteButton, this.editNoteCallback,
      this.deleteNoteCallback);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellow.shade300,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _noteThreadChildren,
      ),
    );
  }

  List<Widget> get _noteThreadChildren {
    final result = <Widget>[
      Divider(height: 0, thickness: 1, color: Colors.grey.shade800),
      Text(noteThread.description),
      addNoteButton(noteThread),
    ];
    noteThread.notes.reversed.forEach((note) {
      result.add(_NoteViewer(note, editNoteCallback, deleteNoteCallback));
      result.add(Divider(height: 0, thickness: 1, color: Colors.grey.shade800));
    });

    return result;
  }
}

class _NoteViewer extends StatelessWidget {
  final models.Note note;
  final Function(models.Note) editNoteCallback;
  final Function(models.Note) deleteNoteCallback;

  _NoteViewer(this.note, this.editNoteCallback, this.deleteNoteCallback);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: GestureDetector(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chapter ${note.chapter}',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                  Text(note.message),
                ],
              ),
            ),
            onTap: () {
              editNoteCallback(note);
            },
          ),
        ),
        GestureDetector(
          child: Icon(
            Icons.delete,
            color: Colors.grey,
          ),
          onTap: () {
            deleteNoteCallback(note);
          },
        )
      ],
    );
  }
}
