import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/config_models.dart';
import '../services/api_service.dart';
import '../utils/parsing_utils.dart';
import '../widgets/media_widgets.dart';
import '../events/action_dispatcher.dart';
import '../state/state_manager.dart';
import '../permissions/permission_manager.dart';
import '../engine/graph_engine.dart';
// Removed diagnostic scanner import; factory should not emit dev-only overlays
import 'components/switch_component.dart';
import 'components/slider_component.dart';
import 'components/text_field_component.dart';
import 'components/button_component.dart';
import 'components/icon_component.dart';
import 'components/text_component.dart';
import 'components/image_component.dart';

/// Enhanced component factory with theming, validation, permissions, and state management
class EnhancedComponentFactory {
  static final ContractApiService _apiService = ContractApiService();
  static final EnhancedStateManager _stateManager = EnhancedStateManager();
  static final PermissionManager _permissionManager = PermissionManager();
  static final Map<int, Widget> _componentCache = {};

  static CanonicalContract? _contract;
  static Map<String, String>? _currentTheme;

  static void initialize(CanonicalContract contract) {
    _contract = contract;
    _apiService.initialize(contract);
    // StateManager is initialized in app.dart; avoid double initialization
    // _validator.initialize(contract.validations);
    _permissionManager.initialize(contract.permissionsFlags);
    _updateTheme();
  }

  static void _updateTheme() {
    if (_contract != null) {
      final themeMode = _stateManager.getGlobalState('theme') ?? 'system';
      String selectedTheme = 'light';

      if (themeMode == 'dark') {
        selectedTheme = 'dark';
      } else if (themeMode == 'system') {
        // In a real app, you'd check system theme
        selectedTheme = 'light';
      }

      _currentTheme = _contract!.themingAccessibility.tokens[selectedTheme];
    }
  }

  /// Create widget from enhanced component configuration
  static Widget createComponent(EnhancedComponentConfig config) {
    // Check permissions first
    if (config.permissions != null && config.permissions!.isNotEmpty) {
      if (!_permissionManager.hasAnyPermission(config.permissions!)) {
        return const SizedBox.shrink(); // Hide component if no permission
      }
    }

    // Resolve theme tokens in style
    final resolvedConfig = _resolveThemeTokens(config);

    // Diagnostics: component creation and binding presence
    try {
      final idInfo = resolvedConfig.id ?? '-';
      debugPrint('[diag][component] Create type=${resolvedConfig.type} id=$idInfo');
      final bindingFields = <String, String?>{
        'text': resolvedConfig.text,
        'binding': resolvedConfig.binding,
        'style.color': resolvedConfig.style?.color,
        'style.backgroundColor': resolvedConfig.style?.backgroundColor,
        'style.foregroundColor': resolvedConfig.style?.foregroundColor,
        'placeholder': resolvedConfig.placeholder,
        'label': resolvedConfig.label,
      };
      bindingFields.forEach((k, v) {
        if (v != null && v.contains(r'${')) {
          debugPrint('[diag][binding] ${resolvedConfig.type} id=$idInfo field="$k" value="$v"');
        }
      });
    } catch (_) {}

    switch (resolvedConfig.type) {
      case 'text':
        return _createText(resolvedConfig);
      case 'textField':
      case 'text_field':
        return _createTextField(resolvedConfig);
      case 'button':
        return _createButton(resolvedConfig);
      case 'textButton':
        return _createTextButton(resolvedConfig);
      case 'iconButton':
        return _createIconButton(resolvedConfig);
      case 'icon':
        return _createIcon(resolvedConfig);
      case 'image':
        return _createImage(resolvedConfig);
      case 'card':
        return _createCard(resolvedConfig);
      case 'list':
        return _createList(resolvedConfig);
      case 'grid':
        return _createGrid(resolvedConfig);
      case 'row':
        return _createRow(resolvedConfig);
      case 'column':
        return _createColumn(resolvedConfig);
      case 'center':
        return _createCenter(resolvedConfig);
      case 'spacer':
        return _createSpacer(resolvedConfig);
      case 'constrained':
        return _createConstrained(resolvedConfig);
      case 'aligned':
        return _createAligned(resolvedConfig);
      case 'aspectRatio':
        return _createAspectRatio(resolvedConfig);
      case 'hero':
        return _createHero(resolvedConfig);
      case 'form':
        return _createForm(resolvedConfig);
      case 'searchBar':
        return _createSearchBar(resolvedConfig);
      case 'filterChips':
        return _createFilterChips(resolvedConfig);
      case 'chip':
        return _createChip(resolvedConfig);
      case 'progressIndicator':
        return _createProgressIndicator(resolvedConfig);
      case 'switch':
        return _createSwitch(resolvedConfig);
      case 'slider':
        return _createSlider(resolvedConfig);
      case 'audio':
        return _createAudio(resolvedConfig);
      case 'video':
        return _createVideo(resolvedConfig);
      case 'webview':
        return _createWebView(resolvedConfig);
      default:
        // Contract-first: do not render unknown components
        debugPrint('[factory] Unknown component type="${resolvedConfig.type}" id=${resolvedConfig.id ?? '-'}');
        return const SizedBox.shrink();
    }
  }

  static EnhancedComponentConfig _resolveThemeTokens(
    EnhancedComponentConfig config,
  ) {
    // If no theme is available, return as-is
    if (_currentTheme == null) return config;

    // Always work with a style instance (create empty if null)
    final style = config.style ?? StyleConfig();
    // Resolve typography token values first, then apply explicit overrides.
    double? resolvedFontSize = style.fontSize;
    String? resolvedFontWeight = style.fontWeight;
    if (style.use != null && _contract != null) {
      final token = style.use!;
      final typography = _contract!.themingAccessibility.typography[token];
      if (typography != null) {
        resolvedFontSize = resolvedFontSize ?? typography.fontSize;
        resolvedFontWeight = resolvedFontWeight ?? typography.fontWeight;
      } else {
        debugPrint('[style] Unknown typography token "$token"');
      }
    }
    // Apply component-specific defaults using theme tokens
    String? defaultBackground = style.backgroundColor;
    String? defaultForeground = style.foregroundColor;
    String? defaultColor = style.color;

    // Default filled button background to theme.primary when not provided
    if (config.type == 'button' && defaultBackground == null) {
      defaultBackground = r'${theme.primary}';
    }

    // Default text button color to theme.primary when not provided
    if (config.type == 'textButton' && defaultColor == null) {
      defaultColor = r'${theme.primary}';
    }

    final resolvedStyle = StyleConfig(
      fontSize: resolvedFontSize,
      fontWeight: resolvedFontWeight,
      color: _resolveToken(defaultColor),
      backgroundColor: _resolveToken(defaultBackground),
      foregroundColor: _resolveToken(defaultForeground),
      textAlign: style.textAlign,
      width: style.width,
      height: style.height,
      maxWidth: style.maxWidth,
      borderRadius: style.borderRadius,
      elevation: style.elevation,
      padding: style.padding,
      margin: style.margin,
      use: style.use,
    );

    return EnhancedComponentConfig(
      type: config.type,
      id: config.id,
      text: config.text,
      src: config.src,
      binding: config.binding,
      label: config.label,
      placeholder: config.placeholder,
      icon: config.icon,
      name: config.name,
      size: config.size,
      columns: config.columns,
      flex: config.flex,
      maxLines: config.maxLines,
      overflow: config.overflow,
      obscureText: config.obscureText,
      keyboardType: config.keyboardType,
      permissions: config.permissions,
      children: config.children,
      dataSource: config.dataSource,
      itemBuilder: config.itemBuilder,
      emptyState: config.emptyState,
      loadingState: config.loadingState,
      errorState: config.errorState,
      validation: config.validation,
      style: resolvedStyle,
      onTap: config.onTap,
      onChanged: config.onChanged,
      onSubmit: config.onSubmit,
      mainAxisAlignment: config.mainAxisAlignment,
      crossAxisAlignment: config.crossAxisAlignment,
      spacing: config.spacing,
      boundData: config.boundData,
    );
  }

  static String? _resolveToken(String? value) {
    if (value == null || _currentTheme == null) return value;

    if (value.startsWith(r'${theme.') && value.endsWith('}')) {
      final tokenName = value.substring(8, value.length - 1);
      final resolved = _currentTheme![tokenName];
      if (resolved == null) {
        debugPrint('[diag][theme] MISSING token "$tokenName"; returning null to allow fallbacks');
        return null;
      } else {
        debugPrint('[diag][theme] Resolved token "$tokenName" => "$resolved"');
        return resolved;
      }
    }

    return value;
  }

  // Public wrapper to resolve theme tokens for external callers (e.g., page builder)
  static String? resolveToken(String? value) {
    return _resolveToken(value);
  }

  static Widget _createText(EnhancedComponentConfig config) {
    return TextComponent.build(config);
  }

  static Widget _createTextField(EnhancedComponentConfig config) {
    return TextFieldComponent.build(config);
  }

  static Widget _createButton(EnhancedComponentConfig config) {
    return ButtonComponent.build(config);
  }

  static Widget _createTextButton(EnhancedComponentConfig config) {
    if (config.text == null || (config.text?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }
    return Builder(
      builder: (context) => CupertinoButton(
        onPressed: config.onTap != null
            ? () => EnhancedActionDispatcher.execute(context, config.onTap!)
            : null,
        padding: config.style?.padding?.toEdgeInsets() ?? EdgeInsets.zero,
        child: Text(
          config.text!,
          style: TextStyle(
            color: _parseColor(config.style?.color) ?? _parseColor(_currentTheme?['primary']),
            fontSize: config.style?.fontSize ?? 16.0,
            fontWeight: _parseFontWeight(config.style?.fontWeight),
          ),
          textAlign: _parseTextAlign(config.style?.textAlign),
        ),
      ),
    );
  }

  static Widget _createIconButton(EnhancedComponentConfig config) {
    return IconComponent.buildIconButton(config);
  }

  static Widget _createIcon(EnhancedComponentConfig config) {
    return IconComponent.buildIcon(config);
  }

  static Widget _createChip(EnhancedComponentConfig config) {
    // Memoize pure chip (no binding or actions)
    if (config.binding == null &&
        config.onTap == null &&
        config.onChanged == null) {
      final hash = _hashChipConfig(config);
      final cached = _componentCache[hash];
      if (cached != null) return cached;
      if (config.text == null || (config.text?.isEmpty ?? true)) {
        return const SizedBox.shrink();
      }
      final chip = Container(
        padding: config.style?.padding?.toEdgeInsets() ?? EdgeInsets.zero,
        decoration: BoxDecoration(
          color: _parseColor(config.style?.backgroundColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          config.text!,
          style: TextStyle(
            color: _parseColor(config.style?.foregroundColor),
            fontSize: 12,
          ),
        ),
      );
      _componentCache[hash] = chip;
      return chip;
    }
    if (config.text == null || (config.text?.isEmpty ?? true)) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: config.style?.padding?.toEdgeInsets() ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: _parseColor(config.style?.backgroundColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        config.text!,
        style: TextStyle(
          color: _parseColor(config.style?.foregroundColor),
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _createProgressIndicator(EnhancedComponentConfig config) {
    return const CupertinoActivityIndicator();
  }

  static Widget _createSwitch(EnhancedComponentConfig config) {
    return SwitchComponent.build(config);
  }

  static Widget _createSlider(EnhancedComponentConfig config) {
    return SliderComponent.build(config);
  }

  static Widget _createAudio(EnhancedComponentConfig config) {
    return SimpleAudioPlayer(src: config.text ?? '');
  }

  static Widget _createVideo(EnhancedComponentConfig config) {
    return SimpleVideoPlayer(src: config.text ?? '');
  }

  static Widget _createWebView(EnhancedComponentConfig config) {
    return SizedBox(
      height: config.style?.height ?? 300,
      child: SimpleWebView(url: config.text ?? ''),
    );
  }

  // Helper methods (moved to components/common.dart)

  static List<Widget> _applySpacing(
    List<Widget> children,
    Axis axis,
    double spacing,
  ) {
    if (children.isEmpty || spacing <= 0) return children;

    final spaced = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      spaced.add(children[i]);
      if (i < children.length - 1) {
        spaced.add(
          axis == Axis.horizontal
              ? SizedBox(width: spacing)
              : SizedBox(height: spacing),
        );
      }
    }
    return spaced;
  }

  // Parsing utilities
  static Color? _parseColor(String? colorString) {
    // Do not default to a color when unspecified; allow parent defaults.
    if (colorString == null || colorString.isEmpty) return null;
    // Resolve any theme tokens before parsing.
    final resolved = resolveToken(colorString);
    // Use nullable parsing to avoid unintended blue fallbacks
    return ParsingUtils.parseColorOrNull(resolved);
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

  static TextAlign _parseTextAlign(String? align) {
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

  static MainAxisAlignment _parseMainAxisAlignment(String? alignment) {
    switch (alignment) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spaceBetween':
        return MainAxisAlignment.spaceBetween;
      case 'spaceAround':
        return MainAxisAlignment.spaceAround;
      case 'spaceEvenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  static CrossAxisAlignment _parseCrossAxisAlignment(String? alignment) {
    switch (alignment) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      case 'baseline':
        return CrossAxisAlignment.baseline;
      default:
        return CrossAxisAlignment.start;
    }
  }

  static Alignment _parseAlignment(String? alignment) {
    switch (alignment) {
      case 'center':
        return Alignment.center;
      case 'start':
        return Alignment.topLeft;
      case 'end':
        return Alignment.bottomRight;
      case 'topCenter':
        return Alignment.topCenter;
      case 'bottomCenter':
        return Alignment.bottomCenter;
      default:
        return Alignment.centerLeft;
    }
  }

  static Clip? _parseClipBehavior(String? clip) {
    switch (clip) {
      case 'antiAlias':
      case 'antiAliasWithSaveLayer':
        return Clip.antiAlias;
      case 'hardEdge':
        return Clip.hardEdge;
      case 'none':
        return Clip.none;
      default:
        return null;
    }
  }

  static Gradient? _buildGradient(GradientConfig? gradient) {
    if (gradient == null) return null;
    final start = _parseColor(gradient.startColor);
    final end = _parseColor(gradient.endColor);
    if (start == null || end == null) return null;
    return LinearGradient(colors: [start, end]);
  }

  static int _hashChipConfig(EnhancedComponentConfig config) {
    return Object.hash(
      'chip',
      config.text,
      config.style?.backgroundColor,
      config.style?.foregroundColor,
      12, // font size
    );
  }

  // Builder methods restored inside EnhancedComponentFactory
  static Widget _createImage(EnhancedComponentConfig config) {
    return ImageComponent.build(config);
  }

  static Widget _createCard(EnhancedComponentConfig config) {
    final children =
        config.children
            ?.map(
              (child) =>
                  createComponent(child.copyWith(boundData: config.boundData)),
            )
            .toList() ??
        [];

    return Builder(builder: (context) {
      final variant = (config.variant ?? 'filled').toLowerCase();
      final borderRadius = config.style?.borderRadius ?? 8.0;
      final padding = config.style?.padding?.toEdgeInsets() ?? EdgeInsets.zero;
      final baseColor =
          _parseColor(config.style?.backgroundColor) ??
          _parseColor(_currentTheme?['surface']) ?? CupertinoColors.systemGrey6;
      final gradient = _buildGradient(config.style?.gradient);

      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      );

      if (variant == 'outlined') {
        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gradient == null ? baseColor : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color:
                  _parseColor(config.style?.borderColor) ??
                  _parseColor(_currentTheme?['outline']) ??
                  CupertinoColors.separator,
              width: config.style?.borderWidth ?? 1,
            ),
          ),
          child: content,
        );
      }

      final elevation = config.style?.elevation ?? (variant == 'elevated' ? 4 : 0).toDouble();
      final clip = _parseClipBehavior(config.clipBehavior) ?? Clip.none;
      Widget inner = Container(
        decoration: BoxDecoration(
          color: gradient == null ? baseColor : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: padding,
        child: content,
      );

      // Place InkWell inside Material so it has a Material ancestor
      final contentWithTap = (config.onTap != null)
          ? InkWell(
              onTap: () {
                EnhancedActionDispatcher.execute(context, config.onTap!, {});
              },
              child: inner,
            )
          : inner;

      return Material(
        color: gradient == null ? baseColor : Colors.transparent,
        elevation: elevation,
        borderRadius: BorderRadius.circular(borderRadius),
        clipBehavior: clip,
        child: contentWithTap,
      );
    });
  }

  static Widget _createList(EnhancedComponentConfig config) {
    return EnhancedListWidget(config: config, componentId: config.id);
  }

  static Widget _createGrid(EnhancedComponentConfig config) {
    // Support two modes:
    // 1) Static children grid (existing behavior)
    // 2) Data-driven grid using dataSource.items + itemBuilder (static only)
    List<Widget> children = [];
    final columns = config.columns ?? 2;
    final spacing = config.spacing ?? 8.0;

    final hasItemBuilder = config.itemBuilder != null;
    final isStaticData =
        (config.dataSource?.type?.toLowerCase() == 'static') ||
        (config.dataSource?.items != null);

    if (hasItemBuilder && isStaticData) {
      final items = config.dataSource?.items ?? const <dynamic>[];
      children = items
          .map((item) =>
              createComponent(config.itemBuilder!.copyWith(boundData: item)))
          .toList();
    } else {
      children = config.children
              ?.map((child) =>
                  createComponent(child.copyWith(boundData: config.boundData)))
              .toList() ??
          [];
    }

    // Diagnostics: log grid spacing and columns
    try {
      debugPrint('[diag][grid] columns=${columns} spacing=${spacing} children=${children.length}');
    } catch (_) {}
    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }

  static Widget _createRow(EnhancedComponentConfig config) {
    final children =
        config.children
                ?.map((child) =>
                    createComponent(child.copyWith(boundData: config.boundData)))
                .toList() ??
            [];

    // Diagnostics: log row spacing and children count
    try {
      debugPrint('[diag][row] spacing=${config.spacing ?? 0} children=${children.length}');
    } catch (_) {}
    return Row(
      mainAxisAlignment: _parseMainAxisAlignment(config.mainAxisAlignment),
      crossAxisAlignment: _parseCrossAxisAlignment(config.crossAxisAlignment),
      children: _applySpacing(children, Axis.horizontal, config.spacing ?? 0),
    );
  }

  static Widget _createColumn(EnhancedComponentConfig config) {
    final children =
        config.children
                ?.map((child) =>
                    createComponent(child.copyWith(boundData: config.boundData)))
                .toList() ??
            [];

    return Column(
      mainAxisAlignment: _parseMainAxisAlignment(config.mainAxisAlignment),
      crossAxisAlignment: _parseCrossAxisAlignment(config.crossAxisAlignment),
      children: _applySpacing(children, Axis.vertical, config.spacing ?? 0),
    );
  }

  static Widget _createSpacer(EnhancedComponentConfig config) {
    final flex = config.flex ?? 0;
    if (flex > 0) {
      return Spacer(flex: flex);
    }
    double size = 0;
    switch (config.sizeToken) {
      case 'small':
        size = 8;
        break;
      case 'medium':
        size = 16;
        break;
      case 'large':
        size = 24;
        break;
      default:
        size = 0;
    }
    final width = config.style?.width;
    final height = config.style?.height ?? (size > 0 ? size : null);
    if (width != null || height != null) {
      return SizedBox(width: width, height: height);
    }
    if (size > 0) {
      return SizedBox(height: size);
    }
    return const SizedBox.shrink();
  }

  static Widget _createConstrained(EnhancedComponentConfig config) {
    final children =
        config.children
                ?.map((child) =>
                    createComponent(child.copyWith(boundData: config.boundData)))
                .toList() ??
            [];
    final child = children.length == 1
        ? children.first
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );

    final constraints = BoxConstraints(
      minWidth: config.minWidth ?? 0,
      maxWidth: config.maxWidth ?? double.infinity,
      minHeight: config.minHeight ?? 0,
      maxHeight: config.maxHeight ?? double.infinity,
    );

    Widget content = ConstrainedBox(constraints: constraints, child: child);
    if (config.alignment != null) {
      content = Align(
        alignment: _parseAlignment(config.alignment),
        child: content,
      );
    }

    return Container(
      padding: config.style?.padding?.toEdgeInsets(),
      margin: config.style?.margin?.toEdgeInsets(),
      color: _parseColor(config.style?.backgroundColor),
      child: content,
    );
  }

  static Widget _createAligned(EnhancedComponentConfig config) {
    final children =
        config.children
                ?.map((child) =>
                    createComponent(child.copyWith(boundData: config.boundData)))
                .toList() ??
            [];
    final content = Row(
      mainAxisAlignment: _parseMainAxisAlignment(config.mainAxisAlignment),
      crossAxisAlignment: _parseCrossAxisAlignment(config.crossAxisAlignment),
      children: _applySpacing(children, Axis.horizontal, config.spacing ?? 0),
    );
    return Container(
      padding: config.style?.padding?.toEdgeInsets(),
      margin: config.style?.margin?.toEdgeInsets(),
      color: _parseColor(config.style?.backgroundColor),
      child: content,
    );
  }

  static Widget _createAspectRatio(EnhancedComponentConfig config) {
    final child = config.children?.isNotEmpty == true
        ? createComponent(
            config.children!.first.copyWith(boundData: config.boundData),
          )
        : const SizedBox.shrink();
    final ratio = config.aspectRatio ?? 1.0;
    Widget content = AspectRatio(aspectRatio: ratio, child: child);
    final clip = _parseClipBehavior(config.clipBehavior);
    if (clip != null && clip != Clip.none) {
      content = ClipRect(clipBehavior: clip, child: content);
    }
    return content;
  }

  static Widget _createCenter(EnhancedComponentConfig config) {
    final child =
        config.children?.isNotEmpty == true
            ? createComponent(
                config.children!.first.copyWith(boundData: config.boundData),
              )
            : const SizedBox.shrink();

    return Center(child: child);
  }

  static Widget _createHero(EnhancedComponentConfig config) {
    final children =
        config.children?.map((child) => createComponent(child)).toList() ?? [];

    return Container(
      padding: config.style?.padding?.toEdgeInsets() ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: _parseColor(config.style?.backgroundColor),
        borderRadius: BorderRadius.circular(config.style?.borderRadius ?? 0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  static Widget _createForm(EnhancedComponentConfig config) {
    return EnhancedFormWidget(config: config);
  }

  static Widget _createSearchBar(EnhancedComponentConfig config) {
    return Builder(
      builder: (context) {
        final String debounceKey =
            config.id ?? 'searchBar_${config.placeholder ?? ''}';
        return CupertinoSearchTextField(
          placeholder: config.placeholder ?? '',
          onChanged: (value) {
            if (config.onChanged != null) {
              final debounceMs = config.onChanged!.debounceMs ?? 0;
              if (debounceMs > 0) {
                _debounceAction(
                  debounceKey,
                  Duration(milliseconds: debounceMs),
                  () {
                    EnhancedActionDispatcher.execute(
                      context,
                      config.onChanged!,
                      {'value': value},
                    );
                  },
                );
              } else {
                EnhancedActionDispatcher.execute(context, config.onChanged!, {
                  'value': value,
                });
              }
            }
          },
        );
      },
    );
  }

  static final Map<String, Timer?> _debouncers = {};

  static void _debounceAction(
    String key,
    Duration duration,
    void Function() action,
  ) {
    final existing = _debouncers[key];
    if (existing != null) {
      existing.cancel();
    }
    _debouncers[key] = Timer(duration, () {
      _debouncers[key]?.cancel();
      _debouncers[key] = null;
      action();
    });
  }

  static Widget _createFilterChips(EnhancedComponentConfig config) {
    return const Placeholder(fallbackHeight: 40);
  }
}

/// Enhanced list widget with data source integration
class EnhancedListWidget extends StatefulWidget {
  final EnhancedComponentConfig config;
  final String? componentId;

  const EnhancedListWidget({super.key, required this.config, this.componentId});

  @override
  State<EnhancedListWidget> createState() => _EnhancedListWidgetState();
}

class _EnhancedListWidgetState extends State<EnhancedListWidget> {
  List<dynamic> items = [];
  bool loading = false;
  bool error = false;
  String? errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;
  bool _appendLoading = false;

  @override
  void initState() {
    super.initState();
    // Defer loading until visible to approximate lazy evaluation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final id =
            widget.componentId ??
            'list_${widget.config.dataSource?.service}_${widget.config.dataSource?.endpoint}';
        GraphEngine().setComponentVisible(id, true);
        final ds = widget.config.dataSource;
        final isStatic = ds?.type == 'static' || (ds?.items != null);
        if (isStatic) {
          // Static items: assign and skip API loading
          final staticItems = ds?.items ?? const [];
          setState(() {
            items = List<dynamic>.from(staticItems);
            loading = false;
            error = false;
            _hasMore = false;
          });
          GraphEngine().notifyDataSourceChange(id);
        } else {
          // Initialize pagination footer visibility based on config
          final paginationEnabled = widget.config.dataSource?.pagination?.enabled == true;
          setState(() {
            _hasMore = paginationEnabled;
          });
          _loadPage(reset: true);
        }
      }
    });
  }

  Future<void> _loadPage({bool reset = false}) async {
    if (widget.config.dataSource == null) return;
    final id =
        widget.componentId ??
        'list_${widget.config.dataSource?.service}_${widget.config.dataSource?.endpoint}';

    setState(() {
      if (reset) {
        loading = true;
        error = false;
        _currentPage = 1;
        _hasMore = true;
        items = [];
      } else {
        _appendLoading = true;
      }
    });

    try {
      final dataSource = widget.config.dataSource!;
      final Map<String, dynamic> params = {...?dataSource.params};
      final paginationEnabled = dataSource.pagination?.enabled == true;
      if (paginationEnabled) {
        params['page'] = _currentPage;
      }

      final response = await ContractApiService().fetchList(
        service: dataSource.service ?? '',
        endpoint: dataSource.endpoint ?? '',
        params: params,
        listPath: dataSource.listPath ?? 'data',
        totalPath: dataSource.pagination?.totalPath,
        pagePath: dataSource.pagination?.pagePath,
      );

      setState(() {
        if (reset) {
          items = response.data;
          loading = false;
        } else {
          items = [...items, ...response.data];
          _appendLoading = false;
        }
        _hasMore = paginationEnabled ? response.hasMore : false;
        if (_hasMore && (response.data.isNotEmpty)) {
          _currentPage += 1;
        }
      });
      GraphEngine().notifyDataSourceChange(id);
    } catch (e) {
      setState(() {
        loading = false;
        _appendLoading = false;
        error = true;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading && widget.config.loadingState != null) {
      return EnhancedComponentFactory.createComponent(
        widget.config.loadingState!,
      );
    }

    if (error && widget.config.errorState != null) {
      return EnhancedComponentFactory.createComponent(
        widget.config.errorState!,
      );
    }

    if (items.isEmpty && widget.config.emptyState != null) {
      return EnhancedComponentFactory.createComponent(
        widget.config.emptyState!,
      );
    }

    if (widget.config.itemBuilder == null) {
      return const SizedBox.shrink();
    }

    final totalCount = items.length + (_hasMore ? 1 : 0);

    final useVirtualScroll = widget.config.dataSource?.virtualScrolling == true;

    if (useVirtualScroll) {
      // Render a dedicated scrollable viewport for large lists
      final viewportHeight = widget.config.style?.height ?? 400;
      return SizedBox(
        height: viewportHeight,
        child: ListView.builder(
          primary: false,
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: totalCount,
          itemBuilder: (context, index) {
            if (_hasMore && index == items.length) {
              if (_appendLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(child: CupertinoActivityIndicator()),
                );
              }
              if (widget.config.dataSource?.pagination?.autoLoad == true) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_appendLoading) {
                    _loadPage(reset: false);
                  }
                });
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onPressed: () => _loadPage(reset: false),
                    child: const Text('Load more'),
                  ),
                ),
              );
            }
            final item = items[index];
            return EnhancedComponentFactory.createComponent(
              widget.config.itemBuilder!.copyWith(boundData: item),
            );
          },
        ),
      );
    }

    final EdgeInsets listPadding =
        widget.config.style?.padding?.toEdgeInsets() ??
        const EdgeInsets.symmetric(horizontal: 16.0);

    return Padding(
      padding: listPadding,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: totalCount,
        itemBuilder: _buildListItem,
      ),
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    if (_hasMore && index == items.length) {
      // Load more footer
      if (_appendLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Center(child: CupertinoActivityIndicator()),
        );
      }
      // Auto-load next page when footer becomes visible if enabled
      if (widget.config.dataSource?.pagination?.autoLoad == true) {
        // Defer to next microtask to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_appendLoading) {
            _loadPage(reset: false);
          }
        });
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Center(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onPressed: () => _loadPage(reset: false),
            child: const Text('Load more'),
          ),
        ),
      );
    }

    final item = items[index];
    return EnhancedComponentFactory.createComponent(
      widget.config.itemBuilder!.copyWith(boundData: item),
    );
  }
}

/// Enhanced form widget with validation
class EnhancedFormWidget extends StatefulWidget {
  final EnhancedComponentConfig config;

  const EnhancedFormWidget({super.key, required this.config});

  @override
  State<EnhancedFormWidget> createState() => _EnhancedFormWidgetState();
}

class _EnhancedFormWidgetState extends State<EnhancedFormWidget> {
  final Map<String, dynamic> formData = {};
  final Map<String, String?> errors = {};

  @override
  Widget build(BuildContext context) {
    final children =
        widget.config.children?.map((child) {
          // Pass form context to children
          return EnhancedComponentFactory.createComponent(child);
        }).toList() ??
        [];

    return Container(
      padding: widget.config.style?.padding?.toEdgeInsets(),
      decoration: BoxDecoration(
        color: EnhancedComponentFactory._parseColor(
          widget.config.style?.backgroundColor,
        ),
        borderRadius: BorderRadius.circular(
          widget.config.style?.borderRadius ?? 0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
