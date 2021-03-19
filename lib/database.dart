import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// TABLE metadata
//   dataId    INTEGER PRIMARY KEY
//   dataValue TEXT
const CREATE_TABLE_METADATA = 'CREATE TABLE IF NOT EXISTS metadata ( '
    'dataId INTEGER PRIMARY KEY, '
    'dataValue TEXT '
    ');';

class MetaDataId {
  static const int novelName = 1; // String
  static const int lastChapter = 2; // Float
  static const int authorName = 3; // String
  static const int sourceType =
      4; // String - one of Webnovel / LN / VN / Manga / Anime
  static const int novelNameOrig =
      5; // String - name of the novel in the original language
  static const int novelNameTrans =
      6; // String - name of the novel in english or the reader's language
  static const int translatorName = 7; // String - name of the main translator
  static const int rating = 8; // Float - rating given to the novel (out of 5?)
}

const int DEFAULT_CATEGORY_ID = 1;

// TABLE categories
//   categoryId INTEGER PRIMARY KEY
//   catName    TEXT
//   catColor   INT
const CREATE_TABLE_CATEGORIES = 'CREATE TABLE IF NOT EXISTS categories ( '
    'categoryId INTEGER PRIMARY KEY, '
    'catName TEXT, '
    'catColor INT '
    ');';

const int ROOT_NODE_ID = 1;

// TABLE nodes
//   nodeId     INTEGER PRIMARY KEY
//   categoryId INTEGER FOREIGN KEY
//   name       TEXT
const CREATE_TABLE_NODES = 'CREATE TABLE IF NOT EXISTS nodes ( '
    'nodeId INTEGER PRIMARY KEY, '
    'categoryId INTEGER, '
    'name TEXT NON NULL, '
    'FOREIGN KEY (categoryId) '
    '  REFERENCES categories (categoryId) '
    '    ON DELETE RESTRICT ' // Disallow deletions
    '    ON UPDATE CASCADE ' // Update with new changes
    '); ';

// TABLE nodes_nodes
//   parentId INTEGER FOREIGN KEY  // link to nodes
//   childId  INTEGER FOREIGN KEY  // link to nodes
//   sequence INTEGER              // Where this child is in the parent's tree
const CREATE_TABLE_NODES_NODES = 'CREATE TABLE IF NOT EXISTS nodes_nodes ( '
    'parentId INTEGER, '
    'childId INTEGER, '
    'sequence INTEGER, '
    'PRIMARY KEY (parentId, childId), '
    'FOREIGN KEY (parentId) '
    '  REFERENCES nodes (nodeId) '
    '    ON DELETE RESTRICT ' // Disallow deletions
    '    ON UPDATE CASCADE, ' // Update with new changes
    'FOREIGN KEY (childId) '
    '  REFERENCES nodes (nodeId) '
    '    ON DELETE RESTRICT ' // Disallow deletions
    '    ON UPDATE CASCADE ' // Update with new changes
    '); ';

// TABLE nicknames
//   nicknameId INTEGER PRIMARY KEY
//   nodeId     INTEGER FOREIGN KEY // link to nodes
//   nickname TEXT
const CREATE_TABLE_NICKNAMES = 'CREATE TABLE IF NOT EXISTS nicknames ( '
    'nicknameId INTEGER PRIMARY KEY, '
    'nodeId INTEGER, '
    'nickname TEXT NON NULL, '
    'FOREIGN KEY (nodeId) '
    '  REFERENCES nodes (nodeId) '
    '    ON DELETE CASCADE ' // Delete as well if parent is deleted
    '    ON UPDATE CASCADE ' // Update if parent is updated
    '); ';

// TABLE threads
//   threadId    INTEGER PRIMARY KEY
//   nodeId      INTEGER FOREIGN KEY  // link to nodes
//   description STRING    // Description of the contents of the thread
//   sequence    INTEGER   // ordering of message thread among all threads
const CREATE_TABLE_THREADS = 'CREATE TABLE IF NOT EXISTS threads ( '
    'threadId INTEGER PRIMARY KEY, '
    'nodeId INTEGER, '
    'description STRING, '
    'sequence INTEGER, '
    'FOREIGN KEY (nodeId) '
    '  REFERENCES nodes (nodeId) '
    '    ON DELETE CASCADE ' // Delete as well if parent is deleted
    '    ON UPDATE CASCADE ' // Update if parent is updated
    '); ';

// TABLE notes
//   noteId   INTEGER PRIMARY KEY
//   threadId INTEGER FOREIGN KEY // link to threads
//   message TEXT
//   chapter REAL // ordering of notes or chapters
const CREATE_TABLE_NOTES = 'CREATE TABLE IF NOT EXISTS notes ( '
    'noteId INTEGER PRIMARY KEY, '
    'threadId INTEGER, '
    'message TEXT, '
    'chapter REAL, ' // The chapter number the note is attached to
    'FOREIGN KEY (threadId) '
    '  REFERENCES threads (threadId) '
    '    ON DELETE CASCADE ' // Delete as well if parent is deleted
    '    ON UPDATE CASCADE ' // Update if parent is updated
    '); ';

// Get the relevant database from the filesystem
Future<Database> initializeDatabases(String novelName) async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Path to the database
  final databasePath =
      join(await getDatabasesPath(), '${novelName}_notebook.db');

  developer.log('Opening database located at : $databasePath',
      name: 'database.initializeDatabases()');

  // Open the database
  final Future<Database> database = openDatabase(
    databasePath,
    // When the database is first created, create the tables in the database
    onCreate: (db, version) async {
      developer.log(
          'Database not found. Creating new database at : $databasePath',
          name: 'database.initializeDatabases()');

      await setupDatabaseV1(db);
      await setupSampleDataV1(db);
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

Future<void> setupDatabaseV1(Database db) async {
  // Create the 7 databases
  await db.execute(CREATE_TABLE_METADATA);
  await db.execute(CREATE_TABLE_CATEGORIES);
  await db.execute(CREATE_TABLE_NODES);
  await db.execute(CREATE_TABLE_NODES_NODES);
  await db.execute(CREATE_TABLE_NICKNAMES);
  await db.execute(CREATE_TABLE_THREADS);
  await db.execute(CREATE_TABLE_NOTES);

  // Add the default metadata
  await db.execute('INSERT INTO metadata (dataId, dataValue) '
      'VALUES '
      '(${MetaDataId.novelName}, "unknown"), '
      '(${MetaDataId.lastChapter}, "0.0"), '
      '(${MetaDataId.authorName}, "unknown"), '
      '(${MetaDataId.sourceType}, "unknown"), '
      '(${MetaDataId.novelNameOrig}, "unknown"), '
      '(${MetaDataId.novelNameTrans}, "unknown"), '
      '(${MetaDataId.translatorName}, "unknown"), '
      '(${MetaDataId.rating}, "0.0"); ');

  // Add the default categories
  await db.execute('INSERT INTO categories (categoryId, catName, catColor) '
      'VALUES '
      '(1, "Default", ${Colors.white.value}), '
      '(2, "World", ${Colors.green.value}), '
      '(3, "Person", ${Colors.blue.value}), '
      '(4, "Organization", ${Colors.yellow.value}), '
      '(5, "Family", ${Colors.orange.value}), '
      '(6, "Species", ${Colors.purpleAccent.value}), '
      '(7, "Item", ${Colors.pinkAccent.value}), '
      '(8, "Skill", ${Colors.redAccent.value});');

  // Add the root node into the tree at position 1
  await db.execute('INSERT INTO nodes (nodeId, name, categoryId) '
      'VALUES '
      '(1, "root", 1); ');
}

Future<void> setupSampleDataV1(Database db) async {
  // Insert sample data
  await db.execute('INSERT INTO nodes (nodeId, name, categoryId) '
      'VALUES '
      '(2, "Hero", 3), '
      '(3, "Villain", 3), '
      '(4, "Excalibur", 7);');
  await db.execute('INSERT INTO nodes_nodes (parentId, childId, sequence) '
      'VALUES '
      '(1, 2, 1), ' // Hero under Root at pos 1
      '(1, 3, 2), ' // Villain under Root at pos 2
      '(2, 4, 1), ' // Excalibur under Hero at pos 1
      '(1, 4, 3);'); // Excalibur under Root at pos 3
  await db.execute('INSERT INTO nicknames (nodeId, nickname) '
      'VALUES '
      '(2, "Yuusha"), '
      '(2, "Link"), '
      '(4, "Holy Sword"), '
      '(3, "Maou");');
  await db
      .execute('INSERT INTO threads (threadId, nodeId, sequence, description)'
          'VALUES '
          '(1, 1, 1, "World"), ' // Thread in root node
          '(2, 4, 1, "Existence"), ' // Thread 1 in excalibur node
          '(3, 4, 2, "Construction");'); // Thread 2 in excalibur node
  await db.execute('INSERT INTO notes (threadId, message, chapter)'
      'VALUES '
      '(1, "summary of the world", 1), '
      '(2, "does it even exist?", 1), '
      '(2, "it\'s hidden in the forbidden forest", 2), '
      '(3, "it\'s made of meteorite steel and plastic", 1);');
}
