import 'package:flutter/cupertino.dart';
import '../../models/config_models.dart';
import '../../events/action_dispatcher.dart';
import '../../utils/parsing_utils.dart';

class IconComponent {
  static Widget buildIcon(EnhancedComponentConfig config) {
    return Icon(
      ParsingUtils.parseIcon(config.icon ?? config.name ?? 'circle'),
      size: ParsingUtils.safeToDouble(config.size) ?? 24.0,
      color: ParsingUtils.parseColor(config.style?.color),
    );
  }

  static Widget buildIconButton(EnhancedComponentConfig config) {
    return Builder(
      builder:
          (context) => CupertinoButton(
            onPressed:
                ((config.enabled ?? true) && config.onTap != null)
                    ? () =>
                        EnhancedActionDispatcher.execute(context, config.onTap!)
                    : null,
            padding: EdgeInsets.zero,
            child: Icon(
              ParsingUtils.parseIcon(config.icon ?? config.name ?? 'circle'),
              size: ParsingUtils.safeToDouble(config.size) ?? 24.0,
              color: ParsingUtils.parseColor(config.style?.color),
            ),
          ),
    );
  }
}
