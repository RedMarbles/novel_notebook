import 'package:flutter/material.dart';

final defaultTheme = ThemeData(
  // This is the theme of your application.
  //
  // Try running your application with "flutter run". You'll see the
  // application has a blue toolbar. Then, without quitting the app, try
  // changing the primarySwatch below to Colors.green and then invoke
  // "hot reload" (press "r" in the console where you ran "flutter run",
  // or simply save your changes to "hot reload" in a Flutter IDE).
  // Notice that the counter didn't reset back to zero; the application
  // is not restarted.
  primarySwatch: Colors.blue,
  // This makes the visual density adapt to the platform that you run
  // the app on. For desktop platforms, the controls will be smaller and
  // closer together (more dense) than on mobile platforms.
  visualDensity: VisualDensity.adaptivePlatformDensity,
);

final _darkColorScheme = ColorScheme.fromSwatch(
  brightness: Brightness.dark,
  primarySwatch: Colors.blueGrey,
  accentColor: Colors.tealAccent[200],
  cardColor: Colors.grey[800],
  backgroundColor: Colors.grey[700],
);

final _lightColorScheme = ColorScheme.fromSwatch(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  accentColor: Colors.blue,
  cardColor: Colors.grey[500],
  backgroundColor: Colors.grey[300],
);

final darkTheme = ThemeData.dark().copyWith(colorScheme: _darkColorScheme);
final lightTheme = ThemeData.light().copyWith(colorScheme: _lightColorScheme);
