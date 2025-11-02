import 'package:flutter/cupertino.dart';
import '../../models/config_models.dart';
import '../../events/action_dispatcher.dart';
import '../../utils/parsing_utils.dart';
import 'common.dart';
import '../component_factory.dart';

class ButtonComponent {
  static Widget build(EnhancedComponentConfig config) {
    return Builder(
      builder: (context) {
        return CupertinoButton(
          onPressed:
              ((config.enabled ?? true) && config.onTap != null)
                  ? () =>
                      EnhancedActionDispatcher.execute(context, config.onTap!)
                  : null,
          color: ParsingUtils.parseColorOrNull(config.style?.backgroundColor),
          borderRadius: BorderRadius.circular(
            config.style?.borderRadius ?? 8.0,
          ),
          padding:
              config.style?.padding?.toEdgeInsets() ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            config.text ?? 'Button',
            style: (() {
              // Base style uses standard style tokens (font size/weight/color)
              final base = ComponentStyleUtils.buildTextStyle(config.style);

              // Determine text color precedence:
              // 1) style.color (primary text color across components)
              // 2) style.foregroundColor (legacy explicit text color for filled buttons)
              // 3) If background is `${theme.primary}`, try `${theme.onPrimary}` token
              //    else if background is `${theme.surface}`, try `${theme.onSurface}`
              // 4) Otherwise, let CupertinoButton choose a contrasting default
              String? desiredColorStr = config.style?.color;
              if (desiredColorStr == null) {
                desiredColorStr = config.style?.foregroundColor;
              }
              if (desiredColorStr == null) {
                final bg = config.style?.backgroundColor;
                if (bg != null) {
                  if (bg.contains(r'${theme.primary}')) {
                    desiredColorStr = r'${theme.onPrimary}';
                  } else if (bg.contains(r'${theme.surface}')) {
                    desiredColorStr = r'${theme.onSurface}';
                  }
                }
              }

              final resolvedStr =
                  EnhancedComponentFactory.resolveToken(desiredColorStr) ??
                  desiredColorStr;
              final resolvedColor =
                  ParsingUtils.parseColorOrNull(resolvedStr);

              // Apply resolved color if available; otherwise keep base color
              return base.copyWith(color: resolvedColor);
            })(),
          ),
        );
      },
    );
  }
}
