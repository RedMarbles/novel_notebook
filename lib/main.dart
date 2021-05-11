import 'package:flutter/material.dart';
import 'package:novelnotebook/screen_novel.dart';
import 'package:novelnotebook/themes.dart' as MyThemes;

void main() {
  runApp(MyApp());
}

// TODO: Create a digital certificate for the app

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeData themeData = MyThemes.darkTheme;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novel Notebook',
      theme: themeData,
      home: NovelScreen(themeCallback),
    );
  }

  void themeCallback(ThemeData newThemeData) {
    setState(() {
      themeData = newThemeData;
    });
  }
}
