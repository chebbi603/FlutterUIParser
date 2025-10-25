import 'package:flutter/cupertino.dart';
import '../../models/config_models.dart';
import '../../events/action_dispatcher.dart';
import '../../utils/parsing_utils.dart';
import 'common.dart';

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
          color: ParsingUtils.parseColor(config.style?.backgroundColor),
          borderRadius: BorderRadius.circular(
            config.style?.borderRadius ?? 8.0,
          ),
          padding:
              config.style?.padding?.toEdgeInsets() ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            config.text ?? 'Button',
            style: TextStyle(
              color: ParsingUtils.parseColor(config.style?.foregroundColor),
              fontSize: config.style?.fontSize ?? 16.0,
              fontWeight:
                  ComponentStyleUtils.buildTextStyle(config.style).fontWeight,
            ),
          ),
        );
      },
    );
  }
}
