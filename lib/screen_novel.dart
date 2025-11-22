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
import 'package:novelnotebook/themes.dart' as myThemes;
import 'package:sqflite/sqflite.dart';

class NovelScreen extends StatefulWidget {
  final Function(ThemeData) themeCallback;

  NovelScreen(this.themeCallback);

  @override
  _NovelScreenState createState() => _NovelScreenState();
}

class _NovelScreenState extends State<NovelScreen> {
  Database? database;
  bool loadingDb = false;
  bool useDarkTheme = true;
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
        actions: [
          Switch(
              value: useDarkTheme,
              onChanged: (value) {
                setState(() {
                  useDarkTheme = value;
                });
                widget.themeCallback(
                    (useDarkTheme) ? myThemes.darkTheme : myThemes.lightTheme);
              })
        ],
      ),
      body: Stack(
        children: [
          ListView(
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
          String? novelName = await showTextEditDialog(context,
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
        color: Theme.of(context).colorScheme.surface,
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
                builder: (context) => TreeScreen(database!),
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
      'Export Database',
      'Reset Database',
      'Delete Database'
    ];
    final int? choiceIdx = await showOptionsDialog(context, optionsStrings);

    if (choiceIdx == null) {
      // Do nothing
      return;
    } else if (choiceIdx == 0) {
      // Rename database
      final String? newDbName = await showTextEditDialog(context,
          value: dbName, title: 'Rename database', hintText: 'Novel name');
      if (newDbName != null) {
        await renameNovelDatabase(dbName, newDbName);
        reloadState();
      }
    } else if (choiceIdx == 1) {
      // Export the database
      final bool check = await showConfirmationDialog(context,
          title: 'Export Database',
          message: 'Are you sure you want to export the $dbName database?');
      if (check) {
        final file = await exportNovelDatabase(dbName);
        await showMessageDialog(context,
            message: 'Database exported to ${file.path}',
            title: 'Export complete');
        reloadState(); // Probably unnecessary
      }
    } else if (choiceIdx == 2) {
      // Reset the database
      final bool check = await showConfirmationDialog(context,
          title: 'Reset Database',
          message: 'Are you sure you want to reset the $dbName database?');
      if (check) {
        await initializeNovelDatabase(dbName, reset: true);
        reloadState();
      }
    } else if (choiceIdx == 3) {
      // Delete the database
      final bool check = await showConfirmationDialog(context,
          title: 'Delete database',
          message: 'Are you sure you want to delete the $dbName database?');
      if (check) {
        await deleteNovelDatabase(dbName);
        reloadState();
      }
    }
  }
}
