class ComponentMetadata {
  final List<String> requiredProps;
  final Map<String, dynamic> defaults;
  const ComponentMetadata({
    this.requiredProps = const [],
    this.defaults = const {},
  });
}

class ComponentRegistry {
  static final Map<String, ComponentMetadata> _registry = {
    'text': ComponentMetadata(
      requiredProps: [],
      defaults: {'style.fontSize': 16},
    ),
    'button': ComponentMetadata(requiredProps: ['text']),
    'textButton': ComponentMetadata(requiredProps: ['text']),
    'icon': ComponentMetadata(requiredProps: ['icon']),
    'iconButton': ComponentMetadata(requiredProps: ['icon']),
    'image': ComponentMetadata(requiredProps: ['src']),
    'card': ComponentMetadata(requiredProps: ['children']),
    'list': ComponentMetadata(requiredProps: ['dataSource', 'itemBuilder']),
    'grid': ComponentMetadata(requiredProps: ['children', 'columns']),
    'row': ComponentMetadata(requiredProps: ['children']),
    'column': ComponentMetadata(requiredProps: ['children']),
    'center': ComponentMetadata(requiredProps: ['children']),
    'hero': ComponentMetadata(requiredProps: ['children']),
    'form': ComponentMetadata(requiredProps: ['children']),
    'searchBar': ComponentMetadata(requiredProps: []),
    'chip': ComponentMetadata(requiredProps: ['text']),
    'progressIndicator': ComponentMetadata(),
    'switch': ComponentMetadata(requiredProps: ['binding']),
    'slider': ComponentMetadata(requiredProps: ['binding']),
    'audio': ComponentMetadata(requiredProps: ['src']),
    'video': ComponentMetadata(requiredProps: ['src']),
    'webview': ComponentMetadata(requiredProps: ['src']),
  };

  static ComponentMetadata? get(String type) => _registry[type];

  static List<String> validate(String type, Map<String, dynamic> config) {
    final meta = _registry[type];
    if (meta == null) return ['Unknown component type: $type'];
    final issues = <String>[];
    for (final prop in meta.requiredProps) {
      if (!config.containsKey(prop)) {
        issues.add('Missing required prop `$prop` for `$type`');
      }
    }
    return issues;
  }
}
