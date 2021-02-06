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
      // Add the default data and root node into the tree at position 1
      await db.execute("INSERT INTO categories (categoryId, catName, catColor) "
          "VALUES "
          "(1, World, green), "
          "(2, Person, blue), "
          "(3, Organization, yellow), "
          "(4, Family, orange), "
          "(5, Species, magenta), "
          "(6, Item, pink), "
          "(7, Skill, red) ");
      await db.execute("INSERT INTO nodes (nodeId, name, categoryId) "
          "VALUES "
          "(1, root, 1), "
          "(2, Hero, 2), "
          "(3, Villain, 2), "
          "(4, Excalibur, 6)");
      await db.execute("INSERT INTO nodes_nodes (parentId, childId, sequence) "
          "VALUES "
          "(1, 2, 1), " // Hero under Root at pos 1
          "(1, 3, 2), " // Villain under Root at pos 2
          "(2, 4, 1), " // Excalibur under Hero at pos 1
          "(1, 4, 3)"); // Excalibur under Root at pos 3
      await db.execute("INSERT INTO nicknames (nodeId, nickname) "
          "VALUES "
          "(2, Yuusha), "
          "(2, Link), "
          "(4, Holy Sword), "
          "(3, Maou)");
      await db.execute("INSERT INTO threads (threadId, nodeId, sequence)"
          "VALUES "
          "(1, 1, 1), " // Thread in root node
          "(2, 4, 1), " // Thread 1 in excalibur node
          "(3, 4, 2)"); // Thread 2 in excalibur node
      await db.execute("INSERT INTO notes (threadId, message, chapter)"
          "VALUES "
          "(1, summary of the world, 1), "
          "(2, does it even exist?, 1), "
          "(2, it's hidden in the forbidden forest, 2), "
          "(3, it's made of meteorite steel and plastic, 1)");
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
