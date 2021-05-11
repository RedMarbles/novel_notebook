import 'package:flutter/material.dart';
import 'package:novelnotebook/database.dart';
import 'package:novelnotebook/models.dart' as models;
import 'package:sqflite/sqflite.dart';
import 'widget_utils.dart';

// Screen to add, edit and delete categories and edit their colors
class CategoriesScreen extends StatefulWidget {
  final Database database;

  CategoriesScreen(this.database);

  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  Map<int, models.Category> categories;

  @override
  void initState() {
    super.initState();

    categories = {
      DEFAULT_CATEGORY_ID:
          models.Category(DEFAULT_CATEGORY_ID, "Loading...", Colors.white.value)
    };

    // Async task to load the actual tree from the database
    reloadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categories'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: ListView(
          children: categories.keys.map((catId) {
            return NodeListElement.fromCategory(
                categories[catId].catName, categories[catId]);
          }).toList(growable: false),
        ),
      ),
    );
  }

  Future<void> reloadCategories() async {
    final categoriesTemp = await models.getCategories(widget.database);
    setState(() {
      categories = categoriesTemp;
    });
  }
}
