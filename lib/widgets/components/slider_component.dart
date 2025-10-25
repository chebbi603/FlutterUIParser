import 'package:flutter/cupertino.dart';
import '../../models/config_models.dart';
import '../../events/action_dispatcher.dart';
import '../../state/state_manager.dart';
import '../graph_subscriber.dart';
import 'common.dart';

class SliderComponent {
  static final EnhancedStateManager _stateManager = EnhancedStateManager();

  static Widget build(EnhancedComponentConfig config) {
    final stateKey = ComponentBindingUtils.resolveStateKey(config);
    final componentId = ComponentBindingUtils.componentIdFor(
      config,
      'slider',
      stateKey,
    );

    return GraphSubscriber(
      componentId: componentId,
      dependencies: stateKey != null ? [stateKey] : const <String>[],
      builder: (context) {
        double value = 0.5;
        if (stateKey != null) {
          final current = _stateManager.getState(stateKey);
          if (current is num) {
            value = current.toDouble();
          } else if (current is String) {
            final parsed = double.tryParse(current);
            if (parsed != null) value = parsed;
          }
        }
        value = value.clamp(0.0, 1.0);

        final enabled = config.enabled ?? true;
        final onChanged =
            (enabled && (config.onChanged != null || stateKey != null))
                ? (double newValue) {
                  if (config.onChanged != null) {
                    EnhancedActionDispatcher.execute(
                      context,
                      config.onChanged!,
                      {'value': newValue},
                    );
                  }
                  if (stateKey != null) {
                    _stateManager.setState(stateKey, newValue);
                  }
                }
                : null;

        return CupertinoSlider(value: value, onChanged: onChanged);
      },
    );
  }
}
