import 'package:flutter/cupertino.dart';
import '../../models/config_models.dart';
import '../../events/action_dispatcher.dart';
import '../../state/state_manager.dart';
import '../graph_subscriber.dart';

class SwitchComponent {
  static final EnhancedStateManager _stateManager = EnhancedStateManager();

  static Widget build(EnhancedComponentConfig config) {
    String? stateKey;
    if (config.binding != null) {
      if (config.binding!.startsWith('\${state.')) {
        stateKey = config.binding!.substring(8, config.binding!.length - 1);
      } else {
        stateKey = config.binding;
      }
    } else if (config.onChanged?.params != null) {
      stateKey = config.onChanged!.params!['key']?.toString();
    }

    final componentId = config.id ?? 'switch_${stateKey ?? 'unknown'}';
    return GraphSubscriber(
      componentId: componentId,
      dependencies: stateKey != null ? [stateKey] : const <String>[],
      builder: (context) {
        bool value = false;
        if (stateKey != null) {
          final current = _stateManager.getState(stateKey);
          if (current is bool) {
            value = current;
          } else if (current is num) {
            value = current != 0;
          } else if (current is String) {
            final s = current.trim().toLowerCase();
            value = (s == 'true' || s == '1' || s == 'yes' || s == 'on');
          }
        }
        return CupertinoSwitch(
          value: value,
          onChanged: (newValue) {
            if (config.onChanged != null) {
              EnhancedActionDispatcher.execute(context, config.onChanged!, {
                'value': newValue,
              });
            }
            if (stateKey != null) {
              _stateManager.setState(stateKey, newValue);
            }
          },
        );
      },
    );
  }
}