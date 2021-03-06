import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:novelnotebook/database.dart';
import 'package:novelnotebook/dialog_utils.dart' as dialogs;
import 'package:novelnotebook/models.dart' as models;
import 'package:novelnotebook/screen_details.dart';
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
      DEFAULT_CATEGORY_ID: models.Category(DEFAULT_CATEGORY_ID, "Loading...",
          Colors.white.value, Colors.black.value)
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
            return GestureDetector(
              child: NodeListElement.fromCategory(
                  categories[catId].catName, categories[catId]),
              onTap: () {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                CategoryEditScreen(widget.database, catId)))
                    .then((_) {
                  reloadCategories();
                });
              },
            );
          }).toList(growable: false),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.add),
        label: Text('Add Category'),
        onPressed: () async {
          final String newCatName = await dialogs.showTextEditDialog(
            context,
            title: 'New Category Name:',
            hintText: 'category name...',
          );
          if (newCatName != null && newCatName.length > 1) {
            await models.addCategory(widget.database, newCatName,
                Colors.white.value, Colors.black.value);
            reloadCategories();
          }
        },
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

class CategoryEditScreen extends StatefulWidget {
  final Database database;
  final int catId;

  CategoryEditScreen(this.database, this.catId);

  factory CategoryEditScreen.fromCategory(Database db, models.Category cat) {
    return CategoryEditScreen(db, cat.categoryId);
  }

  @override
  _CategoryEditScreenState createState() => _CategoryEditScreenState();
}

class _CategoryEditScreenState extends State<CategoryEditScreen> {
  models.Category category;
  List<models.Node> nodesInCategory;

  // TODO: Add ability to delete category if it has no registered nodes?

  @override
  void initState() {
    super.initState();

    category = models.Category(DEFAULT_CATEGORY_ID, 'Loading...',
        Colors.white.value, Colors.black.value);
    nodesInCategory = [];

    reloadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: GestureDetector(
            child: NodeListElement.fromCategory(category.catName, category),
            onTap: _editCategoryNameDialog,
          ),
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListView(
            children: [
              backgroundColorPicker(),
              SizedBox(height: 12),
              textColorPicker(),
              SizedBox(height: 12),
              Divider(),
              Text('Category Elements:'),
              SizedBox(height: 12),
              ...nodesInCategory.map((node) => GestureDetector(
                    child: NodeListElement.fromCategory(node.name, category),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailsScreen(widget.database, node.nodeId),
                        ),
                      ).then((_) {
                        // Reload the tree when navigating back to this screen
                        reloadData();
                      });
                    },
                  ))
            ],
          ),
        ));
  }

  Future<void> reloadData() async {
    final categories = await models.getCategories(widget.database);
    final nodes = await models.getNodesOfCategory(
        widget.database, categories[widget.catId]);

    setState(() {
      category = categories[widget.catId];
      nodesInCategory = nodes;
    });
  }

  Widget backgroundColorPicker() {
    return Row(
      children: [
        Expanded(child: Text('Background Color:')),
        GestureDetector(
          child:
              NodeListElement(' ', backgroundColor: Color(category.catColor)),
          onTap: () async {
            final newBgColor = await dialogs.showColorPickerDialog(
                context, Color(category.catColor),
                title: 'Category Background Color');
            developer.log('Selected color: $newBgColor',
                name: 'CategoryEditScreen.backgroundColorPicker()');

            if (newBgColor != null) {
              await models.editCategory(widget.database, category,
                  newColor: newBgColor);
              reloadData();
            }
          },
        ),
        SizedBox(width: 24.0),
      ],
    );
  }

  Widget textColorPicker() {
    return Row(
      children: [
        Expanded(child: Text('Text Color:')),
        GestureDetector(
          child: NodeListElement(' ',
              backgroundColor: Color(category.catTextColor)),
          onTap: () async {
            final newTextColor = await dialogs.showColorPickerDialog(
                context, Color(category.catTextColor),
                title: 'Category Text Color');
            if (newTextColor != null) {
              await models.editCategory(widget.database, category,
                  newTextColor: newTextColor);
              reloadData();
            }
          },
        ),
        SizedBox(width: 24.0),
      ],
    );
  }

  void _editCategoryNameDialog() async {
    // Dialog to edit the name of the current category
    final String newCatName = await dialogs.showTextEditDialog(
      context,
      value: category.catName,
      title: 'Edit Category Name:',
      hintText: 'category name...',
    );

    if (newCatName != null) {
      await models.editCategory(widget.database, category, newName: newCatName);
      reloadData();
    }
  }
}
