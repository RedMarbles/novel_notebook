import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// TABLE categories
//   categoryId INTEGER PRIMARY KEY
//   catName    TEXT
//   catColor   TEXT
const CREATE_TABLE_CATEGORIES = "CREATE TABLE categories ("
    "categoryId INTEGER PRIMARY KEY,"
    "catName TEXT"
    "catColor TEXT"
    ");";

// TABLE nodes
//   nodeId     INTEGER PRIMARY KEY
//   categoryId INTEGER FOREIGN KEY
//   name       TEXT
const CREATE_TABLE_NODES = "CREATE TABLE nodes ("
    "nodeId INTEGER PRIMARY KEY,"
    "categoryId INTEGER,"
    "name TEXT NON NULL,"
    "FOREIGN KEY (categoryId)"
    "  REFERENCES categories (categoryId)"
    "    ON DELETE RESTRICT" // Disallow deletions
    "    ON UPDATE CASCADE" // Update with new changes
    ");";

// TABLE nodes_nodes
//   parentId INTEGER FOREIGN KEY  // link to nodes
//   childId  INTEGER FOREIGN KEY  // link to nodes
//   sequence INTEGER              // Where this child is in the parent's tree
const CREATE_TABLE_NODES_NODES = "CREATE TABLE nodes_nodes ("
    "parentId INTEGER,"
    "childId INTEGER,"
    "sequence INTEGER,"
    "PRIMARY KEY (parentId, childId),"
    "FOREIGN KEY (parentId)"
    "  REFERENCES nodes (nodeId)"
    "    ON DELETE RESTRICT" // Disallow deletions
    "    ON UPDATE CASCADE," // Update with new changes
    "FOREIGN KEY (childId)"
    "  REFERENCES nodes (nodeId)"
    "    ON DELETE RESTRICT" // Disallow deletions
    "    ON UPDATE CASCADE" // Update with new changes
    ");";

// TABLE nicknames
//   nicknameId INTEGER PRIMARY KEY
//   nodeId     INTEGER FOREIGN KEY // link to nodes
//   nickname TEXT
const CREATE_TABLE_NICKNAMES = "CREATE TABLE nicknames ("
    "nicknameId INTEGER PRIMARY KEY,"
    "nodeId INTEGER,"
    "nickname TEXT NON NULL,"
    "FOREIGN KEY (nodeId)"
    "  REFERENCES nodes (nodeId)"
    "    ON DELETE CASCADE" // Delete as well if parent is deleted
    "    ON UPDATE CASCADE" // Update if parent is updated
    ");";

// TABLE threads
//   threadId INTEGER PRIMARY KEY
//   nodeId   INTEGER FOREIGN KEY  // link to nodes
//   sequence INTEGER   // ordering of message thread among all threads
const CREATE_TABLE_THREADS = "CREATE TABLE threads ("
    "threadId INTEGER PRIMARY KEY,"
    "nodeId INTEGER,"
    "sequence INTEGER,"
    "FOREIGN KEY (nodeId)"
    "  REFERENCES nodes (nodeId)"
    "    ON DELETE CASCADE" // Delete as well if parent is deleted
    "    ON UPDATE CASCADE" // Update if parent is updated
    ");";

// TABLE notes
//   noteId   INTEGER PRIMARY KEY
//   threadId INTEGER FOREIGN KEY // link to threads
//   message TEXT
//   chapter REAL // ordering of notes or chapters
const CREATE_TABLE_NOTES = "CREATE TABLE notes ("
    "noteId INTEGER PRIMARY KEY,"
    "threadId INTEGER,"
    "message TEXT,"
    "chapter REAL," // The chapter number the note is attached to
    "FOREIGN KEY (threadId)"
    "  REFERENCES threads (threadId)"
    "    ON DELETE CASCADE" // Delete as well if parent is deleted
    "    ON UPDATE CASCADE" // Update if parent is updated
    ");";

// Get the relevant database from the filesystem
Future<Database> initializeDatabases(String novelName) async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Path to the database
  final databasePath =
      join(await getDatabasesPath(), '${novelName}_notebook.db');

  developer.log("Opening database located at : $databasePath",
      name: 'database.initializeDatabases()');

  // Open the database
  final Future<Database> database = openDatabase(
    databasePath,
    // When the database is first created, create the tables in the database
    onCreate: (db, version) async {
      developer.log(
          "Database not found. Creating new database at : $databasePath",
          name: 'database.initializeDatabases()');

      // Create the 6 databases
      await db.execute(CREATE_TABLE_CATEGORIES);
      await db.execute(CREATE_TABLE_NODES);
      await db.execute(CREATE_TABLE_NODES_NODES);
      await db.execute(CREATE_TABLE_NICKNAMES);
      await db.execute(CREATE_TABLE_THREADS);
      await db.execute(CREATE_TABLE_NOTES);
      // Add the root node into the tree at position 1
      await db.execute("INSERT INTO nodes (nodeId, name) VALUES (1, root)");
    },
    // Set the version number, used for database upgrades and downgrades
    version: 1,
    // Set the functions to run when upgrading or downgrading the database
    onUpgrade: (db, oldVersion, newVersion) {
      // TODO
    },
    onDowngrade: (db, oldVersion, newVersion) {
      // TODO
    },
  );

  return database;
}
