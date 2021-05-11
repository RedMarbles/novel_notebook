import 'package:flutter/material.dart';
import 'package:novelnotebook/models.dart' as models;

class NodeListElement extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color textColor;

  NodeListElement(this.title,
      {this.textColor = Colors.black, this.backgroundColor = Colors.white});

  factory NodeListElement.fromCategory(String title, models.Category category) {
    return NodeListElement(
      title,
      textColor: Color(category.catTextColor),
      backgroundColor: Color(category.catColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
        ),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        color: backgroundColor,
      ),
    );
  }
}
