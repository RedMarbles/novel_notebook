import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:novelnotebook/models.dart';
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
  Node node = Node(0, "Loading...", 0);
  List<Node> parents = [];
  List<Nickname> nicknames = [];
  List<NoteThread> noteThreads = [];
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();

    reloadState();
  }

  void reloadState() {
    Future.wait([
      getNode(widget.database, widget.nodeId).whenComplete(() => developer.log(
          'getNodeComplete',
          name: 'screen_details._DetailsScreenState.initState()')),
      getParents(widget.database, widget.nodeId),
      getNicknames(widget.database, widget.nodeId),
      getThreadsInNode(widget.database, widget.nodeId),
      getCategories(widget.database),
    ]).then((futures) {
      setState(() {
        node = futures[0];
        parents = futures[1];
        nicknames = futures[2];
        noteThreads = futures[3];
        categories = futures[4];
        developer.log(
            "Extracted node ${widget.nodeId} - ${node.name} under category ${node.categoryId}",
            name: 'screen_details._DetailsScreenState.initState()');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(node.name),
      ),
      body: Column(
        children: [
          _WrapListViewer(
            title: 'Parents:',
            items: parents.map((e) => e.name).toList(),
            generator: (s) => _Parent(s),
          ),
          _WrapListViewer(
            title: 'Alternate names:',
            items: nicknames.map((e) => e.name).toList(),
            generator: (s) => _Nickname(s),
          ),
          _categoryViewer(),
          Text('Notes: '),
          ...List<Widget>.generate(noteThreads.length,
              (index) => _NoteThreadViewer(noteThreads[index])),
  Widget _categoryViewer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
      child: Row(
        children: [
          Text('Category: '),
          SizedBox(width: 8.0),
          DropdownButton(
            value: node.categoryId,
            items: categories
                .map((cat) => DropdownMenuItem(
                      value: cat.categoryId,
                      child: Text(cat.catName),
                    ))
                .toList(),
            onChanged: (catId) async {
              await editNodeCategory(
                widget.database,
                node,
                categories.firstWhere((element) => element.categoryId == catId),
              );
              reloadState();
            },
          ),
        ],
      ),
    );
  }
}

class _WrapListViewer extends StatelessWidget {
  // Todo: just accept the widgets directly, instead of asking for a separate generator
  final String title;
  final List<String> items;
  final Widget Function(String) generator;

  _WrapListViewer({this.title, this.items, this.generator});

  List<Widget> _generateChildren() {
    final children = <Widget>[];
    for (final item in items) {
      children.add(generator(item));
    }
    return children;
  }

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
              ..._generateChildren(),
              GestureDetector(
                child: Icon(Icons.add),
                onTap: () {
                  //TODO: Add callback for adding parent
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Parent extends StatelessWidget {
  final String text;

  _Parent(this.text);

  @override
  Widget build(BuildContext context) {
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
          Text(text),
          GestureDetector(
            child: Icon(Icons.cancel),
            onTap: () {
              //TODO: Delete parent from list
            },
          ),
        ],
      ),
    );
  }
}

class _Nickname extends StatelessWidget {
  final String text;

  _Nickname(this.text);

  @override
  Widget build(BuildContext context) {
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
          GestureDetector(
            child: Text(text),
            onTap: () {
              //TODO: Popup to edit nickname
            },
          ),
          GestureDetector(
            child: Icon(Icons.cancel),
            onTap: () {
              //TODO: Delete nickname from list
            },
          ),
        ],
      ),
    );
  }
}

class _NoteThreadViewer extends StatelessWidget {
  final NoteThread noteThread;

  _NoteThreadViewer(this.noteThread);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.yellow.shade300,
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(height: 0, thickness: 1, color: Colors.grey.shade800),
          Text('thread'), // TODO: Remove this placeholder
          ...List<Widget>.generate(
              noteThread.notes.length,
              (index) => _NoteViewer(
                  noteThread.notes[noteThread.notes.length - index - 1])),
        ],
      ),
    );
  }
}

class _NoteViewer extends StatelessWidget {
  final Note note;

  _NoteViewer(this.note);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chapter ${note.chapter}',
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        Text(note.message),
        Divider(height: 8, thickness: 1, color: Colors.grey.shade800),
      ],
    );
  }
}
