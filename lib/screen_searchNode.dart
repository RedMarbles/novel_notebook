import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:novelnotebook/models.dart';
import 'package:sqflite/sqflite.dart';

class SearchNodeScreen extends StatefulWidget {
  final Database db;
  final List<Node> excludedNodes;

  SearchNodeScreen(this.db, this.excludedNodes);

  @override
  _SearchNodeScreenState createState() => _SearchNodeScreenState();
}

class _SearchNodeScreenState extends State<SearchNodeScreen> {
  List<Node> searchResultNodes = [];
  final controller = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();

    controller.addListener(queryTextInDatabase);
    queryTextInDatabase(); // Load the initial results
  }

  void queryTextInDatabase() async {
    final List<Node> result = await queryNodes(widget.db, controller.text);
    setState(() {
      // Keep only the nodes that have not been excluded
      searchResultNodes = result
          .where((Node node) =>
              widget.excludedNodes
                  .firstWhere((Node exclNode) => exclNode.nodeId == node.nodeId,
                      orElse: () => Node(-1, 'dummy', -1))
                  .nodeId ==
              -1)
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
                    child: ListTile(title: Text(searchResultNodes[index].name)),
                    onTap: () {
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
