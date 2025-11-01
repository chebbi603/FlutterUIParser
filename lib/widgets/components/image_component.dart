import 'package:flutter/cupertino.dart';
import '../../models/config_models.dart';
import '../../state/state_manager.dart';
import '../graph_subscriber.dart';
import '../media_widgets.dart';

/// Image component with template resolution for `${state.*}` and `${item.*}` in `src`.
class ImageComponent {
  static final EnhancedStateManager _stateManager = EnhancedStateManager();

  static Widget build(EnhancedComponentConfig config) {
    final List<String> stateKeyPaths = _extractStateKeyPaths(config);
    final List<String> rootDeps = stateKeyPaths.map((p) => p.split('.').first).toSet().toList();

    // If no state tokens, render statically using current snapshot
    if (rootDeps.isEmpty) {
      final src = _resolveSrc(config);
      return NetworkOrAssetImage(
        src: src,
        width: config.style?.width,
        height: config.style?.height,
        fit: BoxFit.cover,
      );
    }

    final componentId = config.id ?? 'image_${rootDeps.join('|')}_${config.src ?? config.binding ?? config.text ?? ''}';
    return GraphSubscriber(
      componentId: componentId,
      dependencies: rootDeps,
      builder: (context) {
        final src = _resolveSrc(config);
        return NetworkOrAssetImage(
          src: src,
          width: config.style?.width,
          height: config.style?.height,
          fit: BoxFit.cover,
        );
      },
    );
  }

  /// Resolve final image `src` supporting:
  /// 1) `binding` to bound item data
  /// 2) `binding` referencing `${state.*}`
  /// 3) `src` templates `${item.key}` and `${state.path}`
  /// 4) fallback to `text` (deprecated)
  static String _resolveSrc(EnhancedComponentConfig config) {
    // Prefer binding if provided
    if (config.binding != null) {
      final b = config.binding!;
      if (b.startsWith(r'${state.') && b.endsWith('}')) {
        final path = b.substring(8, b.length - 1);
        final v = _stateManager.getState(path);
        if (v != null) return v.toString();
      } else if (config.boundData != null) {
        final v = config.boundData![b];
        if (v != null) return v.toString();
      }
    }

    String template = config.src ?? config.text ?? '';
    if (config.src == null && config.text != null) {
      debugPrint('[image] "text" is deprecated; use "src" instead.');
    }

    if (template.isEmpty) return template;

    final RegExp re = RegExp(r'\$\{([^}]+)\}');
    final matches = re.allMatches(template).toList();
    if (matches.isEmpty) return template;

    String result = template;
    for (final m in matches) {
      final token = m.group(1)!;
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

  /// Extract any `${state.*}` references from src or binding for subscription.
  static List<String> _extractStateKeyPaths(EnhancedComponentConfig config) {
    final List<String> paths = [];
    final String src = config.src ?? config.text ?? '';
    final RegExp re = RegExp(r'\$\{state\.([^}]+)\}');
    for (final m in re.allMatches(src)) {
      final p = m.group(1);
      if (p != null && p.isNotEmpty) paths.add(p);
    }
    if (config.binding != null && config.binding!.startsWith(r'${state.') && config.binding!.endsWith('}')) {
      final p = config.binding!.substring(8, config.binding!.length - 1);
      if (p.isNotEmpty) paths.add(p);
    }
    return paths;
  }
}