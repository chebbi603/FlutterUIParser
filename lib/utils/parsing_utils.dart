import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Utility class for parsing configuration values
class ParsingUtils {
  /// Parse font weight from string
  static FontWeight parseFontWeight(String? fontWeight) {
    switch (fontWeight?.toLowerCase()) {
      case 'bold':
        return FontWeight.bold;
      case 'w100':
        return FontWeight.w100;
      case 'w200':
        return FontWeight.w200;
      case 'w300':
        return FontWeight.w300;
      case 'w400':
        return FontWeight.w400;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      case 'w800':
        return FontWeight.w800;
      case 'w900':
        return FontWeight.w900;
      default:
        return FontWeight.normal;
    }
  }

  /// Parse text alignment from string
  static TextAlign parseTextAlign(String? textAlign) {
    switch (textAlign?.toLowerCase()) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      case 'start':
        return TextAlign.start;
      case 'end':
        return TextAlign.end;
      default:
        return TextAlign.left;
    }
  }

  /// Parse keyboard type from string
  static TextInputType parseKeyboardType(String? keyboardType) {
    switch (keyboardType?.toLowerCase()) {
      case 'number':
        return TextInputType.number;
      case 'email':
        return TextInputType.emailAddress;
      case 'phone':
        return TextInputType.phone;
      case 'url':
        return TextInputType.url;
      case 'multiline':
        return TextInputType.multiline;
      case 'datetime':
        return TextInputType.datetime;
      default:
        return TextInputType.text;
    }
  }

  /// Parse color from string
  static Color parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return CupertinoColors.systemBlue;
    }

    // Handle named colors
    switch (colorString.toLowerCase()) {
      case 'red':
        return CupertinoColors.systemRed;
      case 'blue':
        return CupertinoColors.systemBlue;
      case 'green':
        return CupertinoColors.systemGreen;
      case 'orange':
        return CupertinoColors.systemOrange;
      case 'yellow':
        return CupertinoColors.systemYellow;
      case 'purple':
        return CupertinoColors.systemPurple;
      case 'pink':
        return CupertinoColors.systemPink;
      case 'teal':
        return CupertinoColors.systemTeal;
      case 'indigo':
        return CupertinoColors.systemIndigo;
      case 'gray':
      case 'grey':
        return CupertinoColors.systemGrey;
      case 'black':
        return CupertinoColors.black;
      case 'white':
        return CupertinoColors.white;
      case 'transparent':
        return Colors.transparent;
    }

    // Handle hex colors
    if (colorString.startsWith('#')) {
      try {
        String hexColor = colorString.substring(1);
        
        // Handle 3-digit hex (e.g., #RGB)
        if (hexColor.length == 3) {
          hexColor = hexColor.split('').map((char) => char + char).join();
        }
        
        // Handle 6-digit hex (e.g., #RRGGBB)
        if (hexColor.length == 6) {
          hexColor = 'FF$hexColor'; // Add alpha channel
        }
        
        // Handle 8-digit hex (e.g., #AARRGGBB)
        if (hexColor.length == 8) {
          return Color(int.parse(hexColor, radix: 16));
        }
      } catch (e) {
        // If parsing fails, return default color
        return CupertinoColors.systemBlue;
      }
    }

    // Handle RGB/RGBA format
    if (colorString.startsWith('rgb')) {
      try {
        final RegExp rgbRegex = RegExp(r'rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)');
        final Match? match = rgbRegex.firstMatch(colorString);
        
        if (match != null) {
          final int r = int.parse(match.group(1)!);
          final int g = int.parse(match.group(2)!);
          final int b = int.parse(match.group(3)!);
          final double a = match.group(4) != null ? double.parse(match.group(4)!) : 1.0;
          
          return Color.fromRGBO(r, g, b, a);
        }
      } catch (e) {
        // If parsing fails, return default color
        return CupertinoColors.systemBlue;
      }
    }

    // Default fallback
    return CupertinoColors.systemBlue;
  }

  /// Parse button style from string
  static Widget styleButton(Widget button, String? style) {
    if (style == null) return button;
    
    switch (style.toLowerCase()) {
      case 'filled':
        return button; // Default CupertinoButton is filled
      case 'outlined':
        // For outlined style, we can wrap with a border
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemBlue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: button,
        );
      case 'text':
        // For text style, we can make it more minimal
        return button;
      default:
        return button;
    }
  }

  /// Validate and clamp numeric values
  static double clampDouble(double? value, double min, double max, double defaultValue) {
    if (value == null) return defaultValue;
    return value.clamp(min, max);
  }

  /// Validate and provide default for nullable values
  static T withDefault<T>(T? value, T defaultValue) {
    return value ?? defaultValue;
  }

  /// Safely convert dynamic value to double
  static double? safeToDouble(dynamic value) {
    if (value == null) return null;
    
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  /// Safely convert dynamic value to int
  static int? safeToInt(dynamic value) {
    if (value == null) return null;
    
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }

  /// Safe conversion to bool with error handling
  static bool? safeToBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true') return true;
      if (lower == 'false') return false;
    }
    if (value is num) {
      return value != 0;
    }
    return null;
  }

  /// Parse EdgeInsets from PaddingConfig
  static EdgeInsets? parseEdgeInsets(dynamic padding) {
    if (padding == null) return null;
    if (padding is double) return EdgeInsets.all(padding);
    if (padding is int) return EdgeInsets.all(padding.toDouble());
    // Handle PaddingConfig objects by importing the model
    if (padding.runtimeType.toString().contains('PaddingConfig')) {
      // Use reflection-like approach to call toEdgeInsets
      try {
        return (padding as dynamic).toEdgeInsets();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Parse MainAxisAlignment from string
  static MainAxisAlignment? parseMainAxisAlignment(String? alignment) {
    switch (alignment?.toLowerCase()) {
      case 'start':
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spacebetween':
      case 'space_between':
        return MainAxisAlignment.spaceBetween;
      case 'spacearound':
      case 'space_around':
        return MainAxisAlignment.spaceAround;
      case 'spaceevenly':
      case 'space_evenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return null;
    }
  }

  /// Parse CrossAxisAlignment from string
  static CrossAxisAlignment? parseCrossAxisAlignment(String? alignment) {
    switch (alignment?.toLowerCase()) {
      case 'start':
        return CrossAxisAlignment.start;
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return null;
    }
  }

  /// Parse IconData from string (simplified version)
  static IconData parseIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'chevron_right':
        return CupertinoIcons.chevron_right;
      case 'chevron_left':
        return CupertinoIcons.chevron_left;
      case 'chevron_down':
        return CupertinoIcons.chevron_down;
      case 'chevron_up':
        return CupertinoIcons.chevron_up;
      case 'add':
        return CupertinoIcons.add;
      case 'delete':
        return CupertinoIcons.delete;
      case 'edit':
        return CupertinoIcons.pencil;
      case 'settings':
        return CupertinoIcons.settings;
      case 'home':
        return CupertinoIcons.home;
      case 'person':
        return CupertinoIcons.person;
      case 'mail':
        return CupertinoIcons.mail;
      case 'phone':
        return CupertinoIcons.phone;
      case 'search':
        return CupertinoIcons.search;
      default:
        return CupertinoIcons.circle;
    }
  }
}