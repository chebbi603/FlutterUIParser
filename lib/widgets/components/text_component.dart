import 'package:flutter/cupertino.dart';
import '../../models/config_models.dart';
import '../../state/state_manager.dart';
import '../graph_subscriber.dart';
import 'common.dart';

class TextComponent {
  static final EnhancedStateManager _stateManager = EnhancedStateManager();


  static Widget build(EnhancedComponentConfig config) {
    String displayText = config.text ?? 'Text';

    String? stateKeyPath;
    if (config.binding != null && config.boundData != null) {
      final boundValue = config.boundData![config.binding!];
      if (boundValue != null) displayText = boundValue.toString();
    }

    if (config.binding != null && config.binding!.startsWith('\${state.')) {
      stateKeyPath = config.binding!.substring(8, config.binding!.length - 1);
      final stateValue = _stateManager.getState(stateKeyPath);
      if (stateValue != null) displayText = stateValue.toString();
    }

    // Memoize pure text (no binding)
    if (stateKeyPath == null && config.binding == null) {
      // We deliberately avoid sharing the factory cache; this component can be cached locally if needed.
      final textWidget = Text(
        displayText,
        style: ComponentStyleUtils.buildTextStyle(config.style),
        textAlign: ComponentStyleUtils.parseTextAlign(config.style?.textAlign),
        maxLines: config.maxLines,
        overflow: ComponentStyleUtils.parseTextOverflow(config.overflow),
      );
      return ComponentStyleUtils.withStyle(config, textWidget);
    }

    final text = Text(
      displayText,
      style: ComponentStyleUtils.buildTextStyle(config.style),
      textAlign: ComponentStyleUtils.parseTextAlign(config.style?.textAlign),
      maxLines: config.maxLines,
      overflow: ComponentStyleUtils.parseTextOverflow(config.overflow),
    );

    final componentId = config.id ?? 'text_${stateKeyPath ?? ''}_${config.text ?? ''}';
    return GraphSubscriber(
      componentId: componentId,
      dependencies: stateKeyPath != null ? [stateKeyPath] : const <String>[],
      builder: (context) => ComponentStyleUtils.withStyle(config, text),
    );
  }
}