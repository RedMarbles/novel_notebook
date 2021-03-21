/* Screen where the user selects the novel/database
   1. List of novels/databases available
   2. Add and remove novels
   3. Drawer to access settings of the whole app
 */

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:novelnotebook/database.dart';
import 'package:novelnotebook/dialog_utils.dart';
import 'package:novelnotebook/screen_tree.dart';
import 'package:sqflite/sqflite.dart';

class NovelScreen extends StatefulWidget {
  @override
  _NovelScreenState createState() => _NovelScreenState();
}

class _NovelScreenState extends State<NovelScreen> {
  Database database;
  bool loadingDb = false;
  List<String> databaseNames = [];

  @override
  void initState() {
    super.initState();

    reloadState();
  }

  void reloadState() {
    setState(() {
      loadingDb = true;
    });

    getNovelDatabasesList().then((List<String> result) {
      developer.log('Databases located: ${result.toString()}',
          name: 'screen_novel._NovelScreenState.initState()');

      setState(() {
        databaseNames = result;
        loadingDb = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Novel Selection'),
      ),
      backgroundColor: Colors.blueGrey,
      body: Stack(
        children: [
          Column(
            children: databaseNames
                .map((String dbName) => _databaseButton(dbName))
                .toList(),
          ),
          Center(
            child: (loadingDb) ? CircularProgressIndicator() : null,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Row(
          children: [
            Icon(Icons.add),
            Text('Add Novel'),
          ],
        ),
        onPressed: () async {
          // Add a new novel after asking for the novel name
          String novelName = await showTextEditDialog(context,
              value: '', title: 'Create new database:', hintText: 'Novel name');
          if (novelName != null) {
            setState(() {
              loadingDb = true;
            });
            final newDb = await initializeNovelDatabase(novelName);
            newDb.close();
            reloadState();
          }
        },
      ),
    );
  }

  Widget _databaseButton(String dbName) {
    return MaterialButton(
      child: Container(
        child: Text(dbName),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        color: Colors.white,
      ),
      onPressed: () {
        setState(() {
          // TODO: cache the database in the future
          database = null;
          loadingDb = true;
        });
        initializeNovelDatabase(dbName).then((db) {
          setState(() {
            database = db;
            loadingDb = false;
          });
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TreeScreen(database),
              ));
        });
      },
      onLongPress: () {
        _longPressCallback(dbName);
      },
    );
  }

  void _longPressCallback(String dbName) async {
    const optionsStrings = <String>[
      'Rename Database',
      'Reset Database',
      'Delete Database'
    ];
    final int choiceIdx = await showOptionsDialog(context, optionsStrings);

    if (choiceIdx == null) {
      // Do nothing
      return;
    } else if (choiceIdx == 0) {
      // Rename database
      final String newDbName = await showTextEditDialog(context,
          value: dbName, title: 'Rename database', hintText: 'Novel name');
      if (newDbName != null) {
        await renameNovelDatabase(dbName, newDbName);
        reloadState();
      }
    } else if (choiceIdx == 1) {
      // Reset the database
      final bool check = await showConfirmationDialog(context,
          title: 'Reset Database',
          message: 'Are you sure you want to reset the $dbName database?');
      if (check) {
        await initializeNovelDatabase(dbName, reset: true);
        reloadState();
        showMessageDialog(context,
            title: 'Reset Database',
            message:
                'Database $dbName has been completely reset to default data');
      }
    } else if (choiceIdx == 2) {
      // Delete the database
      final bool check = await showConfirmationDialog(context,
          title: 'Delete database',
          message: 'Are you sure you want to delete the $dbName database?');
      if (check) {
        await deleteNovelDatabase(dbName);
        reloadState();
        showMessageDialog(context,
            title: 'Delete database',
            message: 'Database $dbName has been deleted');
      }
    }
  }
}
