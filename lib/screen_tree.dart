/* Screen where all the items are listed out in a tree
   1. Scrollable tree of all the items in the database
   2. Buttons to add and remove items
   2. Needs a drawer to add and remove categories
 */

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:novelnotebook/models.dart';
import 'package:novelnotebook/screen_details.dart';
import 'package:sqflite/sqflite.dart';

const _ROOT_NODE_ID = 1;

class _TreeNode {
  final Database db;
  bool expand;
  Node node;
  List<_TreeNode> children; // if null, then it's uninitialized

  _TreeNode(this.db, this.node, {this.expand = false}) {}

  Future<void> loadChildren({@required _TreeScreenState widget}) async {
    if (children != null) return;
    if (widget == null) return;

    widget.setLoadingState();
    final childNodes = await getChildren(db, node.nodeId);
    children = List<_TreeNode>.generate(
      childNodes.length,
      (index) => _TreeNode(db, childNodes[index], expand: false),
    );
    widget.unsetLoadingState();
  }
}

class TreeScreen extends StatefulWidget {
  final Database database;

  const TreeScreen(this.database);

  @override
  _TreeScreenState createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  _TreeNode root;
  int numLoadingNodes = 0;

  @override
  void initState() {
    super.initState();

    setState(() {
      numLoadingNodes++;
    });

    getNode(widget.database, _ROOT_NODE_ID).then((rootNode) async {
      _TreeNode _root = _TreeNode(widget.database, rootNode, expand: true);
      await _root.loadChildren(widget: this);

      // Load the children for one level
      _root.children.forEach((_treeNode) {
        _treeNode.loadChildren(widget: this);
      });

      setState(() {
        root = _root;
        numLoadingNodes--;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Text('Database'), // TODO: give better name
        // TODO: Add options menu
      ),
      body: Stack(children: [
        ListView(
          children: _generateTreeStructure(),
        ),
        Center(
          child: (numLoadingNodes < 1 && root != null)
              ? null
              : CircularProgressIndicator(),
        ),
      ]),
    );
  }

  Widget _nodeElement(Node node) {
    return GestureDetector(
      // Replace this with the tree structure selector
      child: Container(
        color: Colors.white,
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Text(node.name),
      ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsScreen(widget.database, node.nodeId),
            ));
      },
    );
  }

  // Enable the loading progress bar
  void setLoadingState() {
    // Only trigger the rebuild if we're switching from 0 to 1 loading nodes
    if (numLoadingNodes == 0) {
      setState(() {
        numLoadingNodes++;
      });
    } else
      numLoadingNodes++;
  }

  // Disable the loading progress bar
  void unsetLoadingState() {
    // Only trigger the rebuild if we're switching from 1 to 0 loading nodes
    if (numLoadingNodes == 1) {
      setState(() {
        numLoadingNodes--;
      });
    } else
      numLoadingNodes--;
  }

  Future<void> reloadTree() async {
    final stack = <_TreeNodePair>[];
    final _TreeNode rootCopy = _TreeNode(
        widget.database, await getNode(widget.database, root.node.nodeId),
        expand: root.expand);
    stack.add(_TreeNodePair(root, rootCopy));

    while (stack.isNotEmpty) {
      final origTreeNode = stack.last.original;
      final copyTreeNode = stack.last.copy;
      stack.removeLast();

      if (origTreeNode == null) {
        copyTreeNode.loadChildren(widget: this);
        continue;
      }

      copyTreeNode.children = <_TreeNode>[];

      final copyChildNodes =
          await getChildren(widget.database, copyTreeNode.node.nodeId);
      copyChildNodes.forEach((copyChild) {
        // Finds a matching node among the original's children, else is null
        final origChildTreeNode = origTreeNode.children.firstWhere(
            (element) => element.node.nodeId == copyChild.nodeId,
            orElse: () => null);
        final copyChildTreeNode = _TreeNode(widget.database, copyChild,
            expand: origChildTreeNode?.expand ?? false);
        copyTreeNode.children.add(copyChildTreeNode);
        stack.add(_TreeNodePair(origChildTreeNode, copyChildTreeNode));
      });
    }
  }

  // Constructs each row element of the ListView, spaced away from the edge by the nest level
  Widget _rowElement(_TreeNode treeNode, int nestLevel) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 16.0 * nestLevel,
          ),
          GestureDetector(
            child: Icon(
              (treeNode.expand) ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 32.0,
              color: (treeNode.children.isEmpty) ? Colors.grey : Colors.black,
            ),
            onTap: (treeNode.children.isEmpty)
                ? null
                : () {
                    treeNode.children.forEach((element) {
                      element.loadChildren(widget: this);
                    });
                    setState(() {
                      treeNode.expand = !treeNode.expand;
                    });
                  },
          ),
          Expanded(
            child: InkWell(
              child: Container(
                  width: double.infinity,
                  height: 32.0,
                  alignment: Alignment.centerLeft,
                  child: Text(treeNode.node.name)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetailsScreen(widget.database, treeNode.node.nodeId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _generateTreeStructure() {
    final rowList = <Widget>[];
    if (root == null) return rowList;

    final treeNodeStack = <_TreeNode>[];
    final nestedLvStack = <int>[];
    treeNodeStack.add(root);
    nestedLvStack.add(0);

    while (treeNodeStack.isNotEmpty) {
      final currTreeNode = treeNodeStack.last;
      final currNestedLv = nestedLvStack.last;
      treeNodeStack.removeLast();
      nestedLvStack.removeLast();

      rowList.add(_rowElement(currTreeNode, currNestedLv));
      rowList.add(Divider(height: 1, thickness: 1, color: Colors.black));
      if (currTreeNode.expand) {
        currTreeNode.children.reversed.forEach((element) {
          treeNodeStack.add(element);
          nestedLvStack.add(currNestedLv + 1);
        });
      }
    }

    return rowList;
  }
}

// Helper class to create a stack of pairs of _TreeNodes
class _TreeNodePair {
  final _TreeNode original;
  final _TreeNode copy;

  _TreeNodePair(this.original, this.copy);
}
