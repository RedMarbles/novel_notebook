import 'dart:collection';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:novelnotebook/models.dart';
import 'package:novelnotebook/widget_utils.dart';
import 'package:sqflite/sqflite.dart';

class SearchNodeScreen extends StatefulWidget {
  final Database db;
  final List<Node> excludedNodes;
  final Map<int, Category> categories;

  SearchNodeScreen(this.db, this.excludedNodes, this.categories);

  @override
  _SearchNodeScreenState createState() => _SearchNodeScreenState();
}

class _SearchNodeScreenState extends State<SearchNodeScreen> {
  List<Node> searchResultNodes = [];
  HashSet<int> excludedIds = HashSet<int>();
  final controller = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();

    widget.excludedNodes.forEach((Node node) {
      excludedIds.add(node.nodeId);
    });

    controller.addListener(queryTextInDatabase);
    queryTextInDatabase(); // Load the initial results
  }

  void queryTextInDatabase() async {
    final List<Node> result = await queryNodes(widget.db, controller.text);
    developer.log("Calling queryText with value ${controller.text}",
        name: "screen_searchNode.queryTextInDatabase()");
    setState(() {
      // Keep only the nodes that have not been excluded
      searchResultNodes = result
          .where((Node node) => !excludedIds.contains(node.nodeId))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Node Search')),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                  suffixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                    borderSide: BorderSide(color: Colors.grey),
                  )),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                itemCount: searchResultNodes.length,
                itemBuilder: (_, index) => InkWell(
                    child: NodeListElement.fromCategory(
                        searchResultNodes[index].name,
                        widget.categories[searchResultNodes[index].categoryId]),
                    onTap: () {
                      // Need to manually do this, because otherwise it continues
                      // to call the callback even after the widget state has been
                      // destroyed
                      controller.removeListener(queryTextInDatabase);

                      Navigator.pop(context, searchResultNodes[index]);
                    }),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
