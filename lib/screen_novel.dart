/* Screen where the user selects the novel/database
   1. List of novels/databases available
   2. Add and remove novels
   3. Drawer to access settings of the whole app
 */

import 'package:flutter/material.dart';
import 'package:novelnotebook/database.dart';
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

    // TODO : Allow creating, renaming, resetting and deleting databases
    databaseNames = ["sample"]; // TODO: Change this into a folder lookup later
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
            children: List.generate(databaseNames.length,
                (index) => _databaseButton(databaseNames[index])),
          ),
          Center(
            child: (loadingDb) ? CircularProgressIndicator() : null,
          ),
        ],
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
        initializeDatabases(dbName).then((db) {
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
    );
  }
}
