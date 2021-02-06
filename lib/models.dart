/* Contains classes of all the data models
 */

import 'dart:async';
import 'package:sqflite/sqflite.dart';

class Category {
  final int categoryId;
  final String catName; // Name of the category
  final String catColor; // Color of the category

  const Category(this.categoryId, this.catName, this.catColor);
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
  final List<Note> notes; // List of messages tied to this thread

  const NoteThread(this.threadId, this.notes);
}

// A single message of a thread
class Note {
  final int noteId; // Unique identifier
  final String message; // The actual contents of the message
  final double chapter; // The chapter number or position indicator

  const Note(this.noteId, this.message, this.chapter);
}

Future<bool> errorAndRollback() async {
  // TODO: Do something to rollback changes after an error in updating
  return false;
}

// Retrieve the list of all categories
Future<List<Category>> getCategories(Database db) async {
  final List<Map<String, dynamic>> result =
      await db.query('categories', columns: [
    'categoryId',
    'catName',
    'catColor',
  ]);

  return List<Category>.generate(
      result.length,
      (int index) => Category(
            result[index]['categoryId'],
            result[index]['catName'],
            result[index]['catColor'],
          ));
}

// Retrieve a specific node from the 'nodes' table
Future<Node> getNode(Database db, int nodeId) async {
  final List<Map<String, dynamic>> result = await db.query(
    'nodes',
    columns: ['nodeId', 'name', 'categoryId'],
    where: 'nodeId = ?',
    whereArgs: [nodeId],
  );
  if (result.length != 1) return null;
  return Node(
    result[0]['nodeId'],
    result[0]['name'],
    result[0]['categoryId'],
  );
}

// Retrieve the list of nicknames attached to a specific node
Future<List<Nickname>> getNicknames(Database db, int nodeId) async {
  final List<Map<String, dynamic>> result = await db.query(
    'nicknames',
    columns: ['nicknameId', 'nickname'],
    where: 'nodeId = ?',
    whereArgs: [nodeId],
  );
  return List<Nickname>.generate(
      result.length,
      (int index) => Nickname(
            result[index]['nicknameId'],
            result[index]['nickname'],
          ));
}

// Retrieve the list of parent nodes of a specific node
Future<List<Node>> getParents(Database db, int nodeId) async {
  final List<Map<String, dynamic>> result = await db.rawQuery(
      "SELECT n.nodeId as id, n.name as name, n.categoryId as catId"
      "FROM nodes_nodes r"
      "INNER JOIN nodes n ON n.nodeId = r.parentId"
      "WHERE r.childId = ?"
      "ORDER BY n.nodeId ASC", // Ordering by this for no specific reason
      [nodeId]);
  // Non-root nodes need at least one parent
  if (nodeId != 1 && result.length < 1) return List<Node>();
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
    "SELECT n.nodeId as id, n.name as name, n.categoryId as catId"
    "FROM nodes_nodes r"
    "INNER JOIN nodes n ON n.nodeId = r.childId"
    "WHERE r.parentId = ?"
    "ORDER BY r.sequence ASC", // Order by the children sequence
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
Future<Category> addCategory(Database db, String catName, String color) async {
  // TODO: Verify that 'color' is a valid color string
  final int catId = await db.insert(
    'categories',
    {'catName': catName, 'catColor': color},
  );
  return Category(catId, catName, color);
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
    {String newName, String newColor}) async {
  // TODO: Verify newColor is valid
  final values = {
    'catName': newName ?? cat.catName,
    'catColor': newColor ?? cat.catColor
  };

  final int count = await db.update('categories', values,
      where: 'categoryId = ?', whereArgs: [cat.categoryId]);
  if (count != 1) {
    errorAndRollback();
    return cat;
  }
  return Category(cat.categoryId, values['catName'], values['catColor']);
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
  // create link to parent
  final int _linkId = await db.insert(
    'nodes_nodes',
    {'parentId': parentNode.nodeId, 'childId': nodeId, 'sequence': 1},
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
  return Node(nodeId, name, cat.categoryId);
}

// Add a nickname for a node
Future<Nickname> addNickname(Database db, Node node, String nickname) async {
  final int nicknameId = await db.insert('nicknames', {'name': nickname});
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
  final int _linkId = await db.insert(
    'nodes_nodes',
    {
      'parentId': parentNode.nodeId,
      'childId': childNode.nodeId,
      'sequence': children.length + 1,
    },
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
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

  // Delete node
  final int count = await db.delete('nodes');
  if (count != 1) {
    errorAndRollback();
    return false;
  }

  // Delete relations to parent nodes
  final int _countLinks = await db.delete(
    'nodes_nodes',
    where: 'childId = ?',
    whereArgs: [node.nodeId],
  );

  return true;
}

// Fetch a thread of messages
Future<NoteThread> getNoteThread(Database db, int threadId) async {
  final List<Map<String, dynamic>> result = await db.query(
    'notes',
    columns: ['noteId', 'message', 'chapter'],
    where: 'threadId = ?',
    whereArgs: [threadId],
    orderBy: 'chapter',
  );
  if (result.length < 1) {
    // TODO: Delete the empty thread
    return null;
  }
  // TODO: Verify that all the threads are in sequence and no sequence numbers are missing

  return NoteThread(
    threadId,
    List<Note>.generate(
        result.length,
        (index) => Note(
              result[index]['nodeId'],
              result[index]['message'],
              result[index]['chapter'],
            )),
  );
}

// Fetch message threads of node
Future<List<NoteThread>> getThreadsInNode(Database db, int nodeId) async {
  final List<Map<String, dynamic>> result = await db.query('threads',
      columns: ['threadId', 'sequence'],
      where: 'nodeId = ?',
      whereArgs: [nodeId],
      orderBy: 'sequence');
  final threads = <NoteThread>[];
  result.forEach((Map<String, dynamic> e) async {
    threads.add(await getNoteThread(db, e['threadId']));
  });

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
  Node node,
  double chapterNum, {
  String message = "", // Message to put in the first note of the thread
  int sequence = 9999, // Sequence number, 1 is at the top
  List<NoteThread> threads, // Existing threads of the target node
}) async {
  // TODO: verify the sequence number, rearrange other threads' sequence numbers if necessary
  final int threadId = await db.insert(
    'threads',
    {'nodeId': node.nodeId, 'sequence': sequence},
  );
  final thread = NoteThread(threadId, []);
  thread.notes.add(await addNoteToThread(db, thread, chapterNum));
  return thread;
}

// Edit an existing message
Future<Note> editNote(Database db, Note note,
    {String newMessage, double chapter}) async {
  final values = {
    'message': newMessage ?? note.message,
    'chapter': chapter ?? note.chapter
  };
  final int count = await db
      .update('notes', values, where: 'noteId = ?', whereArgs: [note.noteId]);
  if (count > 1) {
    errorAndRollback();
    return note;
  }
  return Note(note.noteId, values['message'], values['chapter']);
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
  final int _countNotes = await db
      .delete('notes', where: 'threadId = ?', whereArgs: [thread.threadId]);

  // Delete the thread itself
  final int count = await db
      .delete('threads', where: 'threadId = ?', whereArgs: [thread.threadId]);
  if (count != 1) {
    errorAndRollback();
    return false;
  }
  return true;
}
