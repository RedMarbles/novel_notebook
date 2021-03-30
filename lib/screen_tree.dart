/* Screen where all the items are listed out in a tree
   1. Scrollable tree of all the items in the database
   2. Buttons to add and remove items
   2. Needs a drawer to add and remove categories
 */

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:novelnotebook/models.dart' as models;
import 'package:novelnotebook/screen_details.dart';
import 'package:novelnotebook/database.dart';
import 'package:sqflite/sqflite.dart';

// TODO: Keep track of current chapter number, allow easy editing of current chapter number
// TODO: Allow changing order of children of each TreeNode
// TODO: Metadeta editor
// TODO: Create, edit and delete categories
// TODO: Scroll bar / slider for viewing more of the tree

class _TreeNode {
  final Key key;
  final models.Node node;
  List<_TreeNode> children; // if null, then it's uninitialized
  bool expand; // Whether this tree's children are expanded or not

  _TreeNode(this.node, {this.key, this.children, this.expand = false});

  void loadChildren(Map<int, models.Node> nodes, Map<int, List<int>> childIds) {
    if (children != null) return;

    children = childIds[node.nodeId]
        ?.map((childId) => _TreeNode(
              nodes[childId],
              key: ValueKey('$key.$childId'),
              expand: false,
            ))
        ?.toList();
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
  Map<int, models.Category> categories;
  Map<int, List<int>> children;
  Map<int, models.Node> nodes;
  int numLoadingNodes = 0;

  @override
  void initState() {
    super.initState();

    // Default value of root
    root = _TreeNode(
        models.Node(ROOT_NODE_ID, 'Loading...', DEFAULT_CATEGORY_ID),
        key: ValueKey('$ROOT_NODE_ID'),
        children: [],
        expand: true);
    root.children = [];

    categories = {
      DEFAULT_CATEGORY_ID:
          models.Category(DEFAULT_CATEGORY_ID, "Loading...", Colors.white.value)
    };

    // Async task to load the actual tree from the database
    reloadTree();
  }

  @override
  void dispose() {
    widget.database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: Text('Database'), // TODO: give better name
        actions: [
          InkWell(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.search),
            ),
            onTap: () async {
              // TODO: Load the search bar and execute the search action
            },
          ),
          InkWell(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.group),
            ),
            onTap: () async {
              // TODO: Switch to screen to add, edit and delete categories and edit their colors
            },
          ),
          SizedBox(width: 8.0),
        ],
      ),
      body: Stack(children: [
        ListView(
          children: _generateTreeStructure(reversed: true),
        ),
        Center(
          child: (numLoadingNodes < 1 && root != null)
              ? null
              : CircularProgressIndicator(),
        ),
      ]),
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

  // Reload the tree from the database, while retaining the expanded status of each branch
  Future<void> reloadTree() async {
    developer.log('Reloading database tree...',
        name: 'screen_tree.TreeScreen.reloadTree()');
    await reloadData();
    final stack = <_TreeNodePair>[];
    final _TreeNode rootCopy =
        _TreeNode(nodes[root.node.nodeId], key: root.key, expand: root.expand);
    stack.add(_TreeNodePair(root, rootCopy));

    while (stack.isNotEmpty) {
      final origTreeNode = stack.last.original;
      final copyTreeNode = stack.last.copy;
      stack.removeLast();

      // Load the children of this node, keeping their 'expand' values as false
      copyTreeNode.loadChildren(nodes, children);

      // If this copy was not present in the original tree, then stop processing here
      if (origTreeNode == null) {
        continue;
      }

      copyTreeNode.children.forEach((copyChildTreeNode) {
        // Find a matching node among the original's children, else is null
        final origChildTreeNode = origTreeNode.children?.firstWhere(
            (element) => element.node.nodeId == copyChildTreeNode.node.nodeId,
            orElse: () => null);
        copyChildTreeNode.expand = origChildTreeNode?.expand ?? false;

        // Add both the orig and child to the stack for processing in the next iteration
        stack.add(_TreeNodePair(origChildTreeNode, copyChildTreeNode));
      });
    }

    setState(() {
      root = rootCopy;
    });

    developer.log('Reloading database tree complete!',
        name: 'screen_tree.TreeScreen.reloadTree()');
  }

  Future<void> reloadData() async {
    setLoadingState();

    final futures = await Future.wait([
      models.getCategories(widget.database),
      models.getNodes(widget.database),
      models.getAllChildIds(widget.database),
    ]);
    setState(() {
      categories = futures[0];
      nodes = futures[1];
      children = futures[2];
    });

    unsetLoadingState();
  }

  // Constructs each row element of the ListView, spaced away from the edge by the nest level
  Widget _rowElement(_TreeNode treeNode, int nestLevel) {
    return Container(
      key: treeNode.key,
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
              color: (treeNode.children == null || treeNode.children.isEmpty)
                  ? Colors.grey
                  : Colors.black,
            ),
            onTap: (treeNode.children == null || treeNode.children.isEmpty)
                ? null
                : () {
                    treeNode.children.forEach((element) {
                      element.loadChildren(nodes, children);
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
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8)),
                    color: Color(categories[treeNode.node.categoryId].catColor),
                  ),
                  alignment: Alignment.centerLeft,
                  child: Text(treeNode.node.name)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetailsScreen(widget.database, treeNode.node.nodeId),
                  ),
                ).then((_) {
                  // Reload the tree when navigating back to this screen
                  reloadTree();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _generateTreeStructure({bool reversed = false}) {
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
        final it =
            (reversed) ? currTreeNode.children.reversed : currTreeNode.children;
        it.forEach((element) {
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
