import 'package:flutter/material.dart';

final darkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  fontFamily: 'Georgia',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'IBM Plex Sans',
      fontWeight: FontWeight.w500,
      fontSize: 48,
      letterSpacing: -1,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white70),
    bodySmall: TextStyle(color: Colors.white60),
    labelSmall: TextStyle(color: Colors.white38),
  ),
  hintColor: Colors.white30,
  iconTheme: IconThemeData(color: Colors.white54),
  dividerColor: Colors.white12,
);

final lightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  fontFamily: 'Georgia',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontFamily: 'IBM Plex Sans',
      fontWeight: FontWeight.w500,
      fontSize: 48,
      letterSpacing: -1,
      color: Colors.black,
    ),
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black87),
    bodySmall: TextStyle(color: Colors.black54),
    labelSmall: TextStyle(color: Colors.black38),
  ),
  hintColor: Colors.black26,
  iconTheme: IconThemeData(color: Colors.black45),
  dividerColor: Colors.black12,
);
