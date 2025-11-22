/* Contains classes of all the data models
 */

import 'dart:async';
import 'dart:developer' as developer; // for logging
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:sqflite/sqflite.dart';

// TODO: Add logging for every function here

class Category {
  final int categoryId;
  final String catName; // Name of the category
  final int catColor; // Color of the category
  final int catTextColor; // Color of the text for the category

  const Category(
      this.categoryId, this.catName, this.catColor, this.catTextColor);
}

class Node {
  final int nodeId;
  final String name;
  final int categoryId;

  const Node(this.nodeId, this.name, this.categoryId);
}

class Nickname {
  final int nicknameId;
  final String name;

  const Nickname(this.nicknameId, this.name);
}

// An entire thread of messages
class NoteThread {
  final int threadId; // Unique identifier
  final int? nodeId; // Id of the node to which this belongs
  final String description; // Description/title of the thread
  final int sequence; // Which order in the sequence of threads this belongs to
  final List<Note> notes; // List of messages tied to this thread

  const NoteThread(this.threadId,
      {required this.notes,
      this.description = '',
      this.nodeId,
      this.sequence = 0});
}

// A single message of a thread
class Note {
  final int noteId; // Unique identifier
  final String message; // The actual contents of the message
  final double chapter; // The chapter number or position indicator // TODO: Change the chapter number to a decimal type instead of double

  const Note(this.noteId, this.message, this.chapter);
}

class Metadata {
  static const Map<String, String> defaults = {
    "novelName": "Untitled", // String
    "lastChapter": "1.0", // Double
    "authorName": "Unknown", // String
    "novelNameOrig": "Unknown", // String
    "novelNameTrans": "Unknown", // String
    "translatorName": "Unknown", // String
    "rating": "0.0", // Double
    "sourceTypeIdx": "0", // Int, index in the list
    "languageOrigIdx": "0", // Int, index in the list
  };

  // Enum idx - one of Webnovel / LN / VN / Manga / Anime
  static const List<String> sourceTypeList = [
    'Unknown',
    'Webnovel',
    'Light Novel',
    'Visual Novel',
    'Manga',
    'Anime',
  ];

  // Enum idx - The original language of the story
  static const List<String> languageOrigList = [
    'Unknown',
    'English',
    'Japanese',
    'Chinese',
    'Korean',
    'French',
    'German',
    'Spanish',
    'Indonesian',
  ];

  final Map<String, String> values;

  factory Metadata.fromMap(Map<String, String> input) {
    final temp = Map<String, String>.from(
        defaults); // Initialized as a copy of the default map
    input.keys.forEach((key) {
      // Overwrite only the metadata entries that are in defaults
      if (defaults.containsKey(key)) temp[key] = input[key]!;
    });

    // Check that the index ranges are valid
    final sourceTypeIdx = int.parse(temp['sourceTypeIdx']!);
    if (sourceTypeIdx < 0 || sourceTypeIdx >= sourceTypeList.length) {
      temp['sourceTypeIdx'] = defaults['sourceTypeIdx']!;
    }
    final languageOriIdx = int.parse(temp['languageOrigIdx']!);
    if (languageOriIdx < 0 || languageOriIdx >= languageOrigList.length) {
      temp['languageOrigIdx'] = defaults['languageOrigIdx']!;
    }

    return Metadata._safeInit(temp);
  }

  factory Metadata.uninitialized() {
    return Metadata._safeInit(defaults);
  }

  const Metadata._safeInit(this.values);
}

Future<bool> errorAndRollback() async {
  // TODO: Do something to rollback changes after an error in updating
  return false;
}

// Retrieve the metadata of the novel
Future<Metadata> getMetadata(Database db) async {
  developer.log('Attempting to fetch novel metadata',
      name: 'models.getMetadata()');
  final List<Map<String, dynamic>> result =
      await db.query('metadata', columns: ['dataId', 'dataValue']);

  final values = Map<String, String>();
  result.forEach((Map<String, dynamic> element) {
    values[element['dataId']] = element['dataValue'];
  });

  developer.log('Extracted Metadata: ${values.toString()}',
      name: 'models.getMetadata()');

  return Metadata.fromMap(values);
}

Future<bool> updateMetadata(Database db, Map<String, String> newValues) async {
  developer.log('Attempting to update metadata',
      name: 'models.updateMetadata()');

  // Make sure all the keys are valid
  final String? firstInvalidKey = newValues.keys.firstWhereOrNull(
      (key) => !Metadata.defaults.containsKey(key));
  if (firstInvalidKey != null) {
    developer.log('Error: Invalid key found : \"$firstInvalidKey\"');
    return false;
  }

  final keys = newValues.keys.toList();
  for (int i = 0; i < keys.length; ++i) {
    final String key = keys[i];
    await db.update(
      'metadata',
      {'dataValue': newValues[key]},
      where: 'dataId = ?',
      whereArgs: [key],
    );
  }

  return true;
}

// Retrieve the list of all categories
Future<Map<int, Category>> getCategories(Database db) async {
  developer.log('Attempting to fetch information about categories',
      name: 'models.getCategories()');
  final List<Map<String, dynamic>> result =
      await db.query('categories', columns: [
    'categoryId',
    'catName',
    'catColor',
    'catTextColor',
  ]);
  developer.log(
      'Fetched information about ${result.length} categories in the database',
      name: 'models.getCategories()');

  final categoriesMap = Map<int, Category>();
  result.forEach((Map<String, dynamic> element) {
    categoriesMap[element['categoryId']] = Category(
      element['categoryId'],
      element['catName'],
      element['catColor'],
      element['catTextColor'],
    );
  });

  return categoriesMap;
}

// Retrieve a specific node from the 'nodes' table
Future<Node?> getNode(Database db, int nodeId) async {
  developer.log('Attempting to get node with id $nodeId',
      name: 'models.getNode()');
  final List<Map<String, dynamic>> result = await db.query(
    'nodes',
    columns: ['nodeId', 'name', 'categoryId'],
    where: 'nodeId = ?',
    whereArgs: [nodeId],
  );
  if (result.length != 1) return null;
  developer.log('Successfully retrieved node with node id $nodeId',
      name: 'models.getNode()');
  return Node(
    result[0]['nodeId'],
    result[0]['name'],
    result[0]['categoryId'],
  );
}

Future<Map<int, Node>?> getNodes(Database db) async {
  developer.log('Attempting to get all nodes in the database',
      name: 'models.getNodes()');
  final List<Map<String, dynamic>> result = await db.query(
    'nodes',
    columns: ['nodeId', 'name', 'categoryId'],
  );
  if (result.length < 1) return null;
  developer.log('Successfully retrieved all nodes in the database',
      name: 'models.getNodes()');
  return Map<int, Node>.fromIterable(
    result,
    key: (elem) => elem['nodeId'],
    value: (elem) => Node(elem['nodeId'], elem['name'], elem['categoryId']),
  );
}

Future<Map<int, List<int>>> getAllChildIds(Database db) async {
  developer.log('Attempting to get all ids of child nodes in the database',
      name: 'models.getAllChildIds()');
  final List<Map<String, dynamic>> result = await db.query(
    'nodes_nodes',
    columns: ['parentId', 'childId', 'sequence'],
    orderBy: 'parentId ASC, sequence ASC',
  );

  developer.log('Completed polling for all child ids of all nodes',
      name: 'models.getAllChildIds()');
  final output = Map<int, List<int>>();
  result.forEach((Map<String, dynamic> elem) {
    if (output.containsKey(elem['parentId'])) {
      output[elem['parentId']]!.add(elem['childId']);
    } else {
      output[elem['parentId']] = <int>[elem['childId']];
    }
  });
  return output;
}

Future<List<Node>> queryNodes(Database db, String queryString) async {
  developer.log('Running a query for the term \"$queryString\"',
      name: 'models.queryNodes()');
  final List<Map<String, dynamic>> result = await db.query(
    'nodes',
    columns: ['nodeId', 'name', 'categoryId'],
    where: 'name LIKE ?',
    whereArgs: ['%$queryString%'],
  );

  // TODO: Add a search for looking through the nicknames

  developer.log('Found ${result.length} results matching query',
      name: 'models.queryNodes()');

  return result
      .map((Map<String, dynamic> elem) => Node(
            elem['nodeId'],
            elem['name'],
            elem['categoryId'],
          ))
      .toList(growable: false);
}

// Retrieve the list of nicknames attached to a specific node
Future<List<Nickname>> getNicknames(Database db, int nodeId) async {
  developer.log('Attempting to fetch nicknames of node id $nodeId',
      name: 'models.getNicknames()');
  final List<Map<String, dynamic>> result = await db.query(
    'nicknames',
    columns: ['nicknameId', 'nickname'],
    where: 'nodeId = ?',
    whereArgs: [nodeId],
  );
  developer.log('Successfully retrieved nicknames of node id $nodeId',
      name: 'models.getNicknames()');
  return List<Nickname>.generate(
      result.length,
      (int index) => Nickname(
            result[index]['nicknameId'],
            result[index]['nickname'],
          ));
}

// Retrieve the list of parent nodes of a specific node
Future<List<Node>> getParents(Database db, int nodeId) async {
  developer.log('Attempting to fetch parents of node id $nodeId',
      name: 'models.getParents()');
  final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT n.nodeId as id, n.name as name, n.categoryId as catId '
      'FROM nodes_nodes r '
      'INNER JOIN nodes n ON n.nodeId = r.parentId '
      'WHERE r.childId = ? '
      'ORDER BY n.nodeId ASC; ', // Ordering by this for no specific reason
      [nodeId]);
  // Non-root nodes need at least one parent
  if (nodeId != 1 && result.length < 1) return List<Node>.empty();
  developer.log('Successfully retrieved parents of node id $nodeId',
      name: 'models.getParents()');
  return List<Node>.generate(
      result.length,
      (int index) => Node(
            result[index]['id'],
            result[index]['name'],
            result[index]['catId'],
          ));
}

// Retrieve the list of child nodes of a specific node
Future<List<Node>> getChildren(Database db, int nodeId) async {
  final List<Map<String, dynamic>> result = await db.rawQuery(
    'SELECT n.nodeId as id, n.name as name, n.categoryId as catId '
    'FROM nodes_nodes r '
    'INNER JOIN nodes n ON n.nodeId = r.childId '
    'WHERE r.parentId = ? '
    'ORDER BY r.sequence ASC; ', // Order by the children sequence
    [nodeId],
  );
  return List<Node>.generate(
      result.length,
      (int index) => Node(
            result[index]['id'],
            result[index]['name'],
            result[index]['catId'],
          ));
}

// Add a new category
Future<Category> addCategory(
    Database db, String catName, int colorVal, int textColorVal) async {
  final int catId = await db.insert(
    'categories',
    {'catName': catName, 'catColor': colorVal, 'catTextColor': textColorVal},
  );
  return Category(catId, catName, colorVal, textColorVal);
}

// Get nodes belonging to a category
Future<List<Node>> getNodesOfCategory(Database db, Category cat) async {
  final List<Map<String, dynamic>> result = await db.query('nodes',
      columns: ['nodeId', 'name', 'categoryId'],
      where: 'categoryId = ?',
      whereArgs: [cat.categoryId]);
  return List<Node>.generate(
      result.length,
      (index) => Node(
            result[index]['nodeId'],
            result[index]['name'],
            result[index]['categoryId'],
          ));
}

// Edit existing category
Future<Category> editCategory(Database db, Category cat,
    {String? newName, int? newColor, int? newTextColor}) async {
  final values = {
    'catName': newName ?? cat.catName,
    'catColor': newColor ?? cat.catColor,
    'catTextColor': newTextColor ?? cat.catTextColor,
  };

  final int count = await db.update('categories', values,
      where: 'categoryId = ?', whereArgs: [cat.categoryId]);
  if (count != 1) {
    errorAndRollback();
    return cat;
  }
  return Category(cat.categoryId, 
      values['catName'] as String, 
      values['catColor'] as int,
      values['catTextColor'] as int);
}

// Delete existing category
Future<bool> deleteCategory(Database db, Category cat) async {
  // TODO: Identify categories that must not be deleted
  final int count = await db.delete(
    'categories',
    where: 'categoryId = ?',
    whereArgs: [cat.categoryId],
  );
  if (count > 1) {
    errorAndRollback();
    return false;
  }
  return true;
}

// Add a new node under a parent node with a specified category
Future<Node> addNode(
    Database db, Node parentNode, Category cat, String name) async {
  // create node
  final int nodeId = await db.insert(
    'nodes',
    {'name': name, 'categoryId': cat.categoryId},
  );

  final children = await getChildren(db, parentNode.nodeId);

  // create link to parent
  final int linkId = await db.insert(
    'nodes_nodes',
    {
      'parentId': parentNode.nodeId,
      'childId': nodeId,
      'sequence': children.length + 1,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  developer.log(
      'Created link $linkId between nodes ${parentNode.nodeId} and $nodeId',
      name: 'models.addNode()');

  return Node(nodeId, name, cat.categoryId);
}

// Add a nickname for a node
Future<Nickname> addNickname(Database db, Node node, String nickname) async {
  final int nicknameId = await db
      .insert('nicknames', {'nickname': nickname, 'nodeId': node.nodeId});
  return Nickname(
    nicknameId,
    nickname,
  );
}

// Add a parent node for a node
Future<void> addParent(Database db, Node childNode, Node parentNode) async {
  if (childNode.nodeId == parentNode.nodeId) return; // Ensure no 0 length loops
  if (childNode.nodeId == 1) return; // Do not add parents for the root node
  final children = await getChildren(db, parentNode.nodeId);
  final int linkId = await db.insert(
    'nodes_nodes',
    {
      'parentId': parentNode.nodeId,
      'childId': childNode.nodeId,
      'sequence': children.length + 1, // TODO: check this sequence id better
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
  developer.log(
      'Created link $linkId between nodes ${parentNode.nodeId} and ${childNode.nodeId}',
      name: 'models.addParent()');
}

// Edit an existing node's name
Future<Node> editNodeName(Database db, Node node, String newName) async {
  final int count = await db.update('nodes', {'name': newName},
      where: 'nodeId = ?', whereArgs: [node.nodeId]);
  if (count != 1) {
    errorAndRollback();
    return node;
  }
  return Node(node.nodeId, newName, node.categoryId);
}

Future<Node> editNodeCategory(Database db, Node node, Category newCat) async {
  final int count = await db.update('nodes', {'categoryId': newCat.categoryId},
      where: 'nodeId = ?', whereArgs: [node.nodeId]);
  if (count != 1) {
    errorAndRollback();
    return node;
  }
  return Node(node.nodeId, node.name, newCat.categoryId);
}

// Edit an existing nickname
Future<Nickname> editNickname(
    Database db, Nickname nickname, String newNickname) async {
  final int count = await db.update('nicknames', {'nickname': newNickname},
      where: 'nicknameId = ?', whereArgs: [nickname.nicknameId]);
  if (count != 1) {
    errorAndRollback();
    return nickname;
  }
  return Nickname(nickname.nicknameId, newNickname);
}

// Delete an existing nickname, return false if it fails
Future<bool> deleteNickname(Database db, Nickname nickname) async {
  final int count = await db.delete('nicknames',
      where: 'nicknameId = ?', whereArgs: [nickname.nicknameId]);
  if (count != 1) {
    errorAndRollback();
    return false;
  }
  return true;
}

// Delete an existing node, returns false if it failed
Future<bool> deleteNode(Database db, Node node) async {
  // Do not allow the root node to be deleted
  if (node.nodeId == 1) return false;

  // Do not delete nodes that still have children
  final children = await getChildren(db, node.nodeId);
  if (children.length > 0) return false;

  // Delete relations to parent nodes
  final int countLinks = await db.delete(
    'nodes_nodes',
    where: 'childId = ?',
    whereArgs: [node.nodeId],
  );
  developer.log(
      'Deleted $countLinks links to parents of node ${node.nodeId} - ${node.name}',
      name: 'models.deleteNode()');

  // Delete nicknames linked to node
  final nicknames = await getNicknames(db, node.nodeId);
  nicknames.forEach((nickname) async {
    await deleteNickname(db, nickname);
  });

  // Delete threads linked to node
  final threads = await getThreadsInNode(db, node.nodeId);
  threads.forEach((thread) async {
    await deleteNoteThread(db, thread);
  });

  // Delete node
  final int count =
      await db.delete('nodes', where: 'nodeId = ?', whereArgs: [node.nodeId]);
  if (count != 1) {
    errorAndRollback();
    return false;
  }

  return true;
}

Future<bool> deleteParentRelation(Database db, Node parent, Node child) async {
  final int count = await db.delete('nodes_nodes',
      where: 'parentId = ? AND childId = ?',
      whereArgs: [parent.nodeId, child.nodeId]);
  if (count != 1) {
    errorAndRollback();
    return false;
  }

  return true;
}

// Fetch a thread of messages
Future<List<Note>> getNotesInThread(Database db, int threadId) async {
  developer.log('Attempting to fetch notes in thread id $threadId',
      name: 'models.getNoteThread()');
  final List<Map<String, dynamic>> result = await db.query(
    'notes',
    columns: ['noteId', 'message', 'chapter'],
    where: 'threadId = ?',
    whereArgs: [threadId],
    orderBy: 'chapter',
  );
  developer.log(
      'Successfully retrieved ${result.length} fetch notes in thread id $threadId',
      name: 'models.getNoteThread()');

  // TODO: Verify that all the threads are in sequence and no sequence numbers are missing

  return List<Note>.generate(
      result.length,
      (index) => Note(
            result[index]['noteId'],
            result[index]['message'],
            result[index]['chapter'],
          ));
}

// Fetch message threads of node
Future<List<NoteThread>> getThreadsInNode(Database db, int nodeId) async {
  developer.log('Attempting to fetch threads in node id $nodeId',
      name: 'models.getThreadsInNode()');
  final List<Map<String, dynamic>> result = await db.query('threads',
      columns: ['threadId', 'description', 'sequence'],
      where: 'nodeId = ?',
      whereArgs: [nodeId],
      orderBy: 'sequence');
  final threads = <NoteThread>[];
  for (Map<String, dynamic> e in result) {
    threads.add(NoteThread(
      e['threadId'],
      nodeId: nodeId,
      description: e['description']
          .toString(), // TODO: Remove this toString() conversion after updating all the databases
      sequence: e['sequence'],
      notes: await getNotesInThread(db, e['threadId']),
    ));
  }

  developer.log(
      'Successfully retrieved ${threads.length} threads in node id $nodeId',
      name: 'models.getThreadsInNode()');
  return threads;
}

// Add a new message to an existing thread
Future<Note> addNoteToThread(
  Database db,
  NoteThread thread,
  double chapterNum, {
  String message = "",
}) async {
  int noteId = await db.insert('notes', {
    'threadId': thread.threadId,
    'message': message,
    'chapter': chapterNum,
  });
  return Note(noteId, message, chapterNum);
}

// Add a new message thread to an existing node
Future<NoteThread> addThreadToNode(
  Database db,
  Node node, {
  String description = "", // A short description or title of the thread
  int sequence = 999999, // Sequence number, 1 is at the top
  required List<NoteThread> threads, // Existing threads of the target node
}) async {
  // Verify the sequence number, rearrange other threads' sequence numbers if necessary
  if (sequence < 1) sequence = 1;
  final int maxSequenceNumber =
      threads.fold(1, (prevValue, thread) => max(prevValue, thread.sequence));
  if (sequence > maxSequenceNumber)
    sequence = maxSequenceNumber + 1;
  else {
    // Shift the sequence number of threads with a higher sequence number
    threads.forEach((NoteThread thread) async {
      if (thread.sequence >= sequence) {
        // Shift the sequence number of the thread by 1
        final int count = await db.update(
            'threads', {'sequence': thread.sequence + 1},
            where: 'threadId = ?', whereArgs: [thread.threadId]);
        if (count != 1) {
          developer.log(
              'Error in shifting sequence of thread ${thread.threadId} by 1. Made $count updates instead.',
              name: 'models.addThreadToNode()');
        }
      }
    });
  }

  // Insert the new thread into the database
  final int threadId = await db.insert(
    'threads',
    {'nodeId': node.nodeId, 'description': description, 'sequence': sequence},
  );
  final thread = NoteThread(
    threadId,
    nodeId: node.nodeId,
    description: description,
    sequence: sequence,
    notes: [],
  );
  return thread;
}

Future<NoteThread> editNoteThread(Database db, NoteThread noteThread,
    {String? newDescription, int? newSequence}) async {
  developer.log(
      'Attempting to edit note thread #${noteThread.threadId}\'s description to "$newDescription" and sequence number to "$newSequence"',
      name: 'models.editNoteThread()');
  // TODO : Verify and allow changes in sequence number
  final values = {
    'description': newDescription ?? noteThread.description,
    'sequence': newSequence ?? noteThread.sequence
  };

  final int count = await db.update('threads', values,
      where: 'threadId = ?', whereArgs: [noteThread.threadId]);
  if (count > 1) {
    errorAndRollback();
    return noteThread;
  }

  developer.log('Successfully edited note thread description and/or sequence',
      name: 'models.editNoteThread()');
  return NoteThread(
    noteThread.threadId,
    notes: noteThread.notes,
    description: values['description'] as String,
    nodeId: noteThread.nodeId,
    sequence: values['sequence'] as int,
  );
}

// Edit an existing message
Future<Note> editNote(Database db, Note note,
    {String? newMessage, double? chapter}) async {
  final values = {
    'message': newMessage ?? note.message,
    'chapter': chapter ?? note.chapter
  };

  developer.log(
      'Attempting to edit note ${note.noteId} with new message "${values['message']}" and chapter number ${values['chapter']}',
      name: 'models.editNote()');

  final int count = await db
      .update('notes', values, where: 'noteId = ?', whereArgs: [note.noteId]);
  if (count > 1) {
    errorAndRollback();
    return note;
  }

  developer.log('Successfully edited note ${note.noteId}',
      name: 'models.editNote()');
  return Note(note.noteId, values['message'] as String, values['chapter'] as double);
}

// Delete an existing message
Future<bool> deleteNote(Database db, Note note) async {
  final int count =
      await db.delete('notes', where: 'noteId = ?', whereArgs: [note.noteId]);
  if (count != 1) {
    errorAndRollback();
    return false;
  }
  return true;
}

// Delete an entire message thread
Future<bool> deleteNoteThread(Database db, NoteThread thread) async {
  // Delete all the notes in the thread
  final int countNotes = await db
      .delete('notes', where: 'threadId = ?', whereArgs: [thread.threadId]);
  developer.log('Deleted $countNotes notes under thread ${thread.threadId}',
      name: 'models.deleteNoteThread()');

  // Delete the thread itself
  final int count = await db
      .delete('threads', where: 'threadId = ?', whereArgs: [thread.threadId]);
  if (count != 1) {
    errorAndRollback();
    return false;
  }
  return true;
}
