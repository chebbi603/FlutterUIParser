import 'package:flutter/cupertino.dart';
import '../../models/config_models.dart';
import '../../utils/parsing_utils.dart';

class ComponentStyleUtils {
  static TextStyle buildTextStyle(StyleConfig? style) {
    return TextStyle(
      fontSize: style?.fontSize ?? 16.0,
      fontWeight: _parseFontWeight(style?.fontWeight),
      color: _parseColor(style?.color),
    );
  }

  static Widget withStyle(EnhancedComponentConfig config, Widget child) {
    final style = config.style;
    if (style == null) return child;

    return Container(
      width: style.width,
      height: style.height,
      constraints:
          style.maxWidth != null
              ? BoxConstraints(maxWidth: style.maxWidth!)
              : null,
      margin: style.margin?.toEdgeInsets(),
      child: child,
    );
  }

  static Color? _parseColor(String? colorString) {
    return ParsingUtils.parseColor(colorString);
  }

  static FontWeight _parseFontWeight(String? weight) {
    switch (weight) {
      case 'bold':
        return FontWeight.bold;
      case 'semibold':
        return FontWeight.w600;
      case 'medium':
        return FontWeight.w500;
      default:
        return FontWeight.normal;
    }
  }

  static TextAlign parseTextAlign(String? align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'justify':
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  static TextOverflow parseTextOverflow(String? overflow) {
    switch (overflow) {
      case 'ellipsis':
        return TextOverflow.ellipsis;
      case 'fade':
        return TextOverflow.fade;
      case 'clip':
        return TextOverflow.clip;
      default:
        return TextOverflow.visible;
    }
  }
}

class ComponentBindingUtils {
  static String? resolveStateKey(EnhancedComponentConfig config) {
    if (config.binding != null) {
      final b = config.binding!;
      if (b.startsWith('\${state.') && b.endsWith('}')) {
        return b.substring(8, b.length - 1);
      }
      return b;
    }
    if (config.onChanged?.params != null) {
      final p = config.onChanged!.params!;
      final k = p['key'] ?? p['stateKey'] ?? p['binding'];
      return k?.toString();
    }
    return null;
  }

  static String componentIdFor(
    EnhancedComponentConfig config,
    String prefix, [
    String? stateKey,
  ]) {
    return config.id ?? '${prefix}_${stateKey ?? 'unknown'}';
  }
}
