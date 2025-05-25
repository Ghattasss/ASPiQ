import 'package:flutter/material.dart';

class ApplicitionThemeManager {
  static const Color primaryGreenColor = Color(0xFF2C73D9);
  static const Color primaryBlueColor = Color(0xFF5D9CEC);
  static const Color primaryBlueDarkColor = Color(0xFF060E1E);

  //#141922

  static ThemeData lightTheme = ThemeData(
      primaryColor: primaryGreenColor,
      primaryColorLight: primaryBlueColor,
      //scaffoldBackgroundColor: primaryGreenColor,
      appBarTheme: const AppBarTheme(
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: "Cairo",
            color: Colors.white,
          )),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            fontFamily: "Cairo",
            color: Colors.white),
        bodyLarge: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          fontFamily: "Cairo",
          color: Colors.black,
        ),
        bodyMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          fontFamily: "Cairo",
          color: Colors.black,
        ),
        bodySmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w400,
          fontFamily: "Cairo",
          color: Colors.black54,
        ),
        displaySmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          fontFamily: "Cairo",
          color: Colors.black,
        ),
        displayMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          fontFamily: "Cairo",
          color: Colors.black,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        // backgroundColor: Colors.black
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedLabelStyle: TextStyle(
          color: primaryBlueColor,
          fontSize: 18,
          fontFamily: "Poppins",
        ),
        selectedIconTheme: IconThemeData(
          size: 35,
          color: primaryBlueColor,
        ),
        unselectedIconTheme: IconThemeData(
          size: 30,
          color: Color(0xffc8c9cb),
        ),
      ));
}
