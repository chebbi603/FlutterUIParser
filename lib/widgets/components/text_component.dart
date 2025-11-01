import 'package:flutter/cupertino.dart';
import '../../models/config_models.dart';
import '../../state/state_manager.dart';
import '../graph_subscriber.dart';
import 'common.dart';

/// Text component with template resolution for `${state.*}` and `${item.*}`.
class TextComponent {
  static final EnhancedStateManager _stateManager = EnhancedStateManager();

  static Widget build(EnhancedComponentConfig config) {
    // Extract state dependencies from either binding or text template
    final List<String> stateKeyPaths = _extractStateKeyPaths(config);
    // Subscribe to root keys (first segment) so updates propagate
    final List<String> rootDeps = stateKeyPaths
        .map((p) => p.split('.').first)
        .toSet()
        .toList();

    // If no binding or template tokens, render static text
    if (stateKeyPaths.isEmpty && (config.binding == null)) {
      final textVal = _resolveText(config);
      final textWidget = Text(
        textVal,
        style: ComponentStyleUtils.buildTextStyle(config.style),
        textAlign: ComponentStyleUtils.parseTextAlign(config.style?.textAlign),
        maxLines: config.maxLines,
        overflow: ComponentStyleUtils.parseTextOverflow(config.overflow),
      );
      return ComponentStyleUtils.withStyle(config, textWidget);
    }

    final componentId = config.id ?? 'text_${(stateKeyPaths.isNotEmpty ? stateKeyPaths.join('|') : 'static')}_${config.text ?? ''}';
    return GraphSubscriber(
      componentId: componentId,
      dependencies: rootDeps,
      builder: (context) {
        final textVal = _resolveText(config);
        final text = Text(
          textVal,
          style: ComponentStyleUtils.buildTextStyle(config.style),
          textAlign: ComponentStyleUtils.parseTextAlign(config.style?.textAlign),
          maxLines: config.maxLines,
          overflow: ComponentStyleUtils.parseTextOverflow(config.overflow),
        );
        return ComponentStyleUtils.withStyle(config, text);
      },
    );
  }

  /// Resolve the final display text by applying binding and template substitutions.
  static String _resolveText(EnhancedComponentConfig config) {
    String displayText = config.text ?? 'Text';

    // 1) Direct binding to bound item data (legacy binding field)
    if (config.binding != null && config.boundData != null &&
        !config.binding!.startsWith(r'${state.')) {
      final key = config.binding!;
      final boundValue = config.boundData![key];
      if (boundValue != null) {
        displayText = boundValue.toString();
      }
    }

    // 2) Template substitutions: ${item.key} and ${state.path}
    final RegExp re = RegExp(r'\$\{([^}]+)\}');
    final matches = re.allMatches(displayText).toList();
    if (matches.isEmpty) {
      // Also support binding that explicitly references state
      if (config.binding != null && config.binding!.startsWith(r'${state.')) {
        final stateKeyPath = config.binding!.substring(8, config.binding!.length - 1);
        final stateValue = _stateManager.getState(stateKeyPath);
        if (stateValue != null) {
          displayText = stateValue.toString();
        }
      }
      return displayText;
    }

    String result = displayText;
    // Replace in a loop using current snapshot values
    for (final m in matches) {
      final token = m.group(1)!; // e.g., state.user.username or item.title
      String replacement = '';
      if (token.startsWith('state.')) {
        final path = token.substring('state.'.length);
        final val = _stateManager.getState(path);
        if (val != null) replacement = val.toString();
      } else if (token.startsWith('item.')) {
        final key = token.substring('item.'.length);
        final val = config.boundData != null ? config.boundData![key] : null;
        if (val != null) replacement = val.toString();
      } else {
        // Unknown token type; leave as-is
        continue;
      }
      result = result.replaceRange(m.start, m.end, replacement);
    }
    return result;
  }

  /// Extract any `${state.*}` references from text or binding.
  static List<String> _extractStateKeyPaths(EnhancedComponentConfig config) {
    final List<String> paths = [];
    final String text = config.text ?? '';
    final RegExp re = RegExp(r'\$\{state\.([^}]+)\}');
    for (final m in re.allMatches(text)) {
      final p = m.group(1);
      if (p != null && p.isNotEmpty) paths.add(p);
    }
    if (config.binding != null && config.binding!.startsWith(r'${state.')) {
      final p = config.binding!.substring(8, config.binding!.length - 1);
      if (p.isNotEmpty) paths.add(p);
    }
    return paths;
  }
}
