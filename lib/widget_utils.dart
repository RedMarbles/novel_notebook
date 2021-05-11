import 'package:flutter/material.dart';
import 'package:novelnotebook/models.dart' as models;

class NodeListElement extends StatelessWidget {
  final String title;
  final Color backgroundColor;
  final Color textColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;

  NodeListElement(
    this.title, {
    this.textColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.padding,
    this.margin,
    this.borderRadius,
  });

  factory NodeListElement.fromCategory(
    String title,
    models.Category category, {
    EdgeInsetsGeometry padding,
    EdgeInsetsGeometry margin,
    double borderRadius,
  }) {
    return NodeListElement(
      title,
      textColor: Color(category.catTextColor),
      backgroundColor: Color(category.catColor),
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      margin: margin ?? EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
      child: Text(
        title,
        style: TextStyle(
          color: textColor,
        ),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius ?? 16),
          bottomRight: Radius.circular(borderRadius ?? 16),
        ),
        color: backgroundColor,
      ),
    );
  }
}
