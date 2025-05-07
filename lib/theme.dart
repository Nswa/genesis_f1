import 'package:flutter/material.dart';

final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.white,
  fontFamily: 'IBM Plex Sans',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 48,
      letterSpacing: -1,
      color: Colors.black,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 20,
      height: 1.55,
      color: Colors.black,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.deepPurple,
      textStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  fontFamily: 'IBM Plex Sans',
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 48,
      letterSpacing: -1,
      color: Colors.white,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Georgia',
      fontSize: 20,
      height: 1.55,
      color: Colors.white,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.deepPurple,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.deepPurpleAccent,
      textStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
  ),
);
