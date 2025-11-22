import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
// import 'package:flutter_file_manager/flutter_file_manager.dart';
// import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as PathUtils;
import 'package:path_provider/path_provider.dart'
    as PathProvider; // TODO: Optional store or copy in external storage directory
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:novelnotebook/models.dart' show Metadata;

// TABLE metadata
//   dataId    STRING PRIMARY KEY
//   dataValue TEXT
const CREATE_TABLE_METADATA = 'CREATE TABLE IF NOT EXISTS metadata ( '
    'dataId TEXT PRIMARY KEY, '
    'dataValue TEXT '
    ');';

const int DEFAULT_CATEGORY_ID = 1;

// TABLE categories
//   categoryId INTEGER PRIMARY KEY
//   catName      TEXT
//   catColor     INT
//   catTextColor INT
const CREATE_TABLE_CATEGORIES = 'CREATE TABLE IF NOT EXISTS categories ( '
    'categoryId INTEGER PRIMARY KEY, '
    'catName TEXT, '
    'catColor INT, '
    'catTextColor INT '
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
    'description TEXT, '
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

// Suffix to use for database names
const String _DB_NAME_EXTENSION = '_notebook.db';

Future<bool> requestAndroidStorageWritePermission() async {
  final status = await Permission.storage.status;
  if (status.isGranted)
    return true;
  else if (status.isPermanentlyDenied)
    return false;
  else if (status.isDenied) {
    // We didn't ask for permission yet or the permission has been denied but not permanently
    final requestStatus = await Permission.storage.request();
    return requestStatus.isGranted;
  } else {
    return false;
  }
}

// Exports a novel to the default destination directory
Future<File> exportNovelDatabase(String novelName) async {
  final writePerm = await requestAndroidStorageWritePermission();
  if (!writePerm) {
    developer.log('Write access to storage denied.',
        name: 'database.exportNovelDatabase()');
  }

  final srcPath =
      PathUtils.join(await getDatabasesPath(), novelName + _DB_NAME_EXTENSION);

  // TODO: make the iOS version of this later
  final Directory? dstDir = await PathProvider.getExternalStorageDirectory();
  if (dstDir == null) {
    throw Exception('Could not get external storage directory');
  }
  final dstPath = PathUtils.join(dstDir.path, novelName + _DB_NAME_EXTENSION);

  developer.log('Source database location: $srcPath',
      name: 'database.exportNovelDatabase()');
  developer.log('Target export location:   $dstPath',
      name: 'database.exportNovelDatabase()');

  final File srcFile = File(srcPath);
  final File dstFile = await srcFile.copy(dstPath);

  return dstFile;
}

// Search for any database files that might have been left open
// This happens if the app was closed forcefully by clearing the RAM
Future<void> closeOpenedDatabases(Directory dir) async {
  // final unclosedFiles = await FileManager(
  //   root: dir,
  //   filter: SimpleFileFilter(allowedExtensions: [
  //     'db-wal',
  //     // 'db-shm', // Only search for one of the two temp file types
  //   ], fileOnly: true),
  // ).walk().map((e) => e.path).toList();

  final unclosedFiles = dir.listSync().where((file) {
    final String filename = PathUtils.basename(file.path);
    return filename.endsWith('db-wal');
  }).map((file) => file.path).toList();

  unclosedFiles.forEach((unclosedFile) {
    // The filename of the unclosed file is without the '-wal' extension
    final String databasePath =
        unclosedFile.substring(0, unclosedFile.length - 4);
    developer.log('Closing unclosed database $databasePath',
        name: 'databases.closeOpenedDatabases()');
    openDatabase(databasePath).then((db) {
      db.close();
    });
  });
}

// Retrieve the list of databases in the internal storage
Future<List<String>> getNovelDatabasesList() async {
  final dir = Directory(await getDatabasesPath());
  await closeOpenedDatabases(dir);

  // final files = await FileManager(
  //         root: dir,
  //         filter: SimpleFileFilter(allowedExtensions: ['db'], fileOnly: true))
  //     .walk()
  //     .map((FileSystemEntity file) => file.path)
  //     .map((String fullFileName) => PathUtils.basename(fullFileName))
  //     .map((String filename) =>
  //         filename.substring(0, filename.length - _DB_NAME_EXTENSION.length))
  //     .toList();
  
  final files = dir.listSync().where((file) {
    final String filename = PathUtils.basename(file.path);
    return filename.endsWith('.db');
  }).map((file) => PathUtils.basename(file.path))
    .map((String filename) =>
        filename.substring(0, filename.length - _DB_NAME_EXTENSION.length))
    .toList();

  return files;
}

Future<bool> renameNovelDatabase(String oldName, String newName) async {
  final oldPath =
      PathUtils.join(await getDatabasesPath(), oldName + _DB_NAME_EXTENSION);
  final newPath =
      PathUtils.join(await getDatabasesPath(), newName + _DB_NAME_EXTENSION);
  final File _ = await File(oldPath).rename(newPath);
  developer.log('Renamed $oldName database to $newName',
      name: 'database.renameNovelDatabase()');
  return true;
}

Future<bool> deleteNovelDatabase(String dbName) async {
  final databasePath =
      PathUtils.join(await getDatabasesPath(), dbName + _DB_NAME_EXTENSION);
  deleteDatabase(databasePath);
  developer.log('Deleted database $dbName',
      name: 'database.deleteNovelDatabase()');
  return true;
}

// Get the relevant database from the filesystem
Future<Database> initializeNovelDatabase(String novelName,
    {bool reset = false}) async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Path to the database
  final databasePath =
      PathUtils.join(await getDatabasesPath(), novelName + _DB_NAME_EXTENSION);

  developer.log('Opening database located at : $databasePath',
      name: 'database.initializeNovelDatabase()');

  // Open the database
  final Future<Database> database = openDatabase(
    databasePath,
    // When the database is first created, create the tables in the database
    onCreate: (db, version) async {
      developer.log(
          'Database not found. Creating new database at : $databasePath',
          name: 'database.initializeNovelDatabase()');

      await setupDatabaseV1(db);
      await setupSampleDataV1(db);
    },
    onOpen: (db) async {
      if (reset) {
        // Reset the database - delete all tables, then recreate the db with default data
        await deleteAllTablesDatabase(db);
        await setupDatabaseV1(db);
        await setupSampleDataV1(db);
        developer.log('Database reset complete',
            name: 'database.initializeDatabases.onOpen()');
      }
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

Future<void> deleteAllTablesDatabase(Database db) async {
  await db.execute('DROP TABLE IF EXISTS notes;');
  await db.execute('DROP TABLE IF EXISTS threads;');
  await db.execute('DROP TABLE IF EXISTS nicknames;');
  await db.execute('DROP TABLE IF EXISTS nodes_nodes;');
  await db.execute('DROP TABLE IF EXISTS nodes;');
  await db.execute('DROP TABLE IF EXISTS categories;');
  await db.execute('DROP TABLE IF EXISTS metadata;');
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
  for (String key in Metadata.defaults.keys) {
    await db.insert(
        'metadata', {'dataId': key, 'dataValue': Metadata.defaults[key]});
  }

  // Add the default categories
  await db.execute(
      'INSERT INTO categories (categoryId, catName, catColor, catTextColor) '
      'VALUES '
      '(1, "Default", ${Colors.white.value}, ${Colors.black.value}), '
      '(2, "World", ${Colors.green.value}, ${Colors.black.value}), '
      '(3, "Person", ${Colors.blue.value}, ${Colors.black.value}), '
      '(4, "Organization", ${Colors.yellow.value}, ${Colors.black.value}), '
      '(5, "Family", ${Colors.orange.value}, ${Colors.black.value}), '
      '(6, "Species", ${Colors.purpleAccent.value}, ${Colors.black.value}), '
      '(7, "Item", ${Colors.pinkAccent.value}, ${Colors.black.value}), '
      '(8, "Skill", ${Colors.redAccent.value}, ${Colors.black.value});');

  // Add the root node into the tree at position 1
  await db.execute('INSERT INTO nodes (nodeId, name, categoryId) '
      'VALUES '
      '($ROOT_NODE_ID, "root", 1); ');
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
