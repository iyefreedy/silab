import 'package:flutter/material.dart';
import 'package:silab/constants/color_constants.dart';

final darkTheme = ThemeData(
  scaffoldBackgroundColor: primaryColor,
  colorScheme: const ColorScheme.dark(
    primary: primaryColor,
    onPrimary: whiteColor,
    secondary: yellowColor,
    onSecondary: secondaryColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(yellowColor),
      foregroundColor: MaterialStateProperty.all(secondaryColor),
    ),
  ),
);

final lightTheme = ThemeData(
  scaffoldBackgroundColor: whiteColor,
  colorScheme: const ColorScheme.light(
    primary: whiteColor,
    onPrimary: primaryColor,
    secondary: secondaryColor,
    onSecondary: yellowColor,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(primaryColor),
      foregroundColor: MaterialStateProperty.all(whiteColor),
    ),
  ),
);
