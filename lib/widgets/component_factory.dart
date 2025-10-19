import 'package:flutter/cupertino.dart';
import 'dart:async';
import '../models/config_models.dart';
import '../services/api_service.dart';
import '../utils/parsing_utils.dart';
import '../widgets/media_widgets.dart';
import '../events/action_dispatcher.dart';
import '../state/state_manager.dart';
import '../validation/validator.dart';
import '../permissions/permission_manager.dart';

/// Enhanced component factory with theming, validation, permissions, and state management
class EnhancedComponentFactory {
  static final ContractApiService _apiService = ContractApiService();
  static final EnhancedStateManager _stateManager = EnhancedStateManager();
  static final EnhancedValidator _validator = EnhancedValidator();
  static final PermissionManager _permissionManager = PermissionManager();

  static CanonicalContract? _contract;
  static Map<String, String>? _currentTheme;

  /// Initialize with canonical contract
  static void initialize(CanonicalContract contract) {
    _contract = contract;
    _apiService.initialize(contract);
    // StateManager is initialized in app.dart; avoid double initialization
    _validator.initialize(contract.validations);
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
        return _createText(
          EnhancedComponentConfig(
            type: 'text',
            text: 'Unknown component: ${resolvedConfig.type}',
            style: StyleConfig(color: _currentTheme?['error']),
          ),
        );
    }
  }

  static EnhancedComponentConfig _resolveThemeTokens(
    EnhancedComponentConfig config,
  ) {
    if (config.style == null || _currentTheme == null) return config;

    final style = config.style!;
    final resolvedStyle = StyleConfig(
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      color: _resolveToken(style.color),
      backgroundColor: _resolveToken(style.backgroundColor),
      foregroundColor: _resolveToken(style.foregroundColor),
      textAlign: style.textAlign,
      width: style.width,
      height: style.height,
      maxWidth: style.maxWidth,
      borderRadius: style.borderRadius,
      elevation: style.elevation,
      padding: style.padding,
      margin: style.margin,
    );

    return EnhancedComponentConfig(
      type: config.type,
      id: config.id,
      text: config.text,
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

    if (value.startsWith('\${theme.') && value.endsWith('}')) {
      final tokenName = value.substring(8, value.length - 1);
      return _currentTheme![tokenName] ?? value;
    }

    return value;
  }

  static Widget _createText(EnhancedComponentConfig config) {
    String displayText = config.text ?? 'Text';

    // Handle data binding
    if (config.binding != null && config.boundData != null) {
      final boundValue = config.boundData![config.binding!];
      if (boundValue != null) {
        displayText = boundValue.toString();
      }
    }

    // Handle state binding
    if (config.binding != null && config.binding!.startsWith('\${state.')) {
      final stateKey = config.binding!.substring(8, config.binding!.length - 1);
      final stateValue = _stateManager.getState(stateKey);
      if (stateValue != null) {
        displayText = stateValue.toString();
      }
    }

    final text = Text(
      displayText,
      style: _buildTextStyle(config.style),
      textAlign: _parseTextAlign(config.style?.textAlign),
      maxLines: config.maxLines,
      overflow: _parseTextOverflow(config.overflow),
    );

    return _withStyle(config, text);
  }

  static Widget _createTextField(EnhancedComponentConfig config) {
    return StatefulBuilder(
      builder: (context, setState) {
        String? errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (config.label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  config.label!,
                  style: TextStyle(
                    fontSize: 13.0,
                    color: _parseColor(_currentTheme?['onSurfaceVariant']),
                  ),
                ),
              ),
            CupertinoTextField(
              placeholder: config.placeholder ?? 'Enter text',
              keyboardType: ParsingUtils.parseKeyboardType(config.keyboardType),
              obscureText: config.obscureText ?? false,
              maxLines: config.maxLines ?? 1,
              onChanged: (value) {
                // Validate on change
                if (config.validation != null) {
                  final validationResult = _validator.validateField(
                    config.id ?? 'field',
                    value,
                    config.validation!,
                  );
                  setState(() {
                    errorText =
                        validationResult.isValid
                            ? null
                            : validationResult.message;
                  });
                }

                // Handle state updates
                if (config.onChanged != null) {
                  EnhancedActionDispatcher.execute(context, config.onChanged!, {
                    'value': value,
                  });
                }
              },
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      (() {
                        final hasError =
                            (errorText != null && errorText!.isNotEmpty);
                        return hasError
                            ? (_parseColor(_currentTheme?['error']) ??
                                CupertinoColors.destructiveRed)
                            : CupertinoColors.separator;
                      })(),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  errorText!,
                  style: TextStyle(
                    fontSize: 12.0,
                    color:
                        _parseColor(_currentTheme?['error']) ??
                        CupertinoColors.destructiveRed,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  static Widget _createButton(EnhancedComponentConfig config) {
    return Builder(
      builder:
          (context) => CupertinoButton(
            onPressed:
                config.onTap != null
                    ? () =>
                        EnhancedActionDispatcher.execute(context, config.onTap!)
                    : null,
            color: _parseColor(config.style?.backgroundColor),
            borderRadius: BorderRadius.circular(
              config.style?.borderRadius ?? 8.0,
            ),
            padding:
                config.style?.padding?.toEdgeInsets() ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              config.text ?? 'Button',
              style: TextStyle(
                color:
                    _parseColor(config.style?.foregroundColor) ??
                    CupertinoColors.white,
                fontSize: config.style?.fontSize ?? 16.0,
                fontWeight: _parseFontWeight(config.style?.fontWeight),
              ),
            ),
          ),
    );
  }

  static Widget _createTextButton(EnhancedComponentConfig config) {
    return Builder(
      builder:
          (context) => CupertinoButton(
            onPressed:
                config.onTap != null
                    ? () =>
                        EnhancedActionDispatcher.execute(context, config.onTap!)
                    : null,
            padding: config.style?.padding?.toEdgeInsets() ?? EdgeInsets.zero,
            child: Text(
              config.text ?? 'Text Button',
              style: TextStyle(
                color:
                    _parseColor(config.style?.color) ??
                    _parseColor(_currentTheme?['primary']),
                fontSize: config.style?.fontSize ?? 16.0,
                fontWeight: _parseFontWeight(config.style?.fontWeight),
              ),
              textAlign: _parseTextAlign(config.style?.textAlign),
            ),
          ),
    );
  }

  static Widget _createIconButton(EnhancedComponentConfig config) {
    return Builder(
      builder:
          (context) => CupertinoButton(
            onPressed:
                config.onTap != null
                    ? () =>
                        EnhancedActionDispatcher.execute(context, config.onTap!)
                    : null,
            padding: EdgeInsets.zero,
            child: Icon(
              _parseIcon(config.icon),
              size: ParsingUtils.safeToDouble(config.size) ?? 24.0,
              color: _parseColor(config.style?.color),
            ),
          ),
    );
  }

  static Widget _createIcon(EnhancedComponentConfig config) {
    return Icon(
      _parseIcon(config.icon ?? config.name),
      size: ParsingUtils.safeToDouble(config.size) ?? 24.0,
      color: _parseColor(config.style?.color),
    );
  }

  static Widget _createImage(EnhancedComponentConfig config) {
    return NetworkOrAssetImage(
      src:
          config.binding != null && config.boundData != null
              ? config.boundData![config.binding!]?.toString() ?? ''
              : config.text ?? '',
      width: config.style?.width,
      height: config.style?.height,
      fit: BoxFit.cover,
    );
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

    return Container(
      padding:
          config.style?.padding?.toEdgeInsets() ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            _parseColor(config.style?.backgroundColor) ??
            _parseColor(_currentTheme?['surface']),
        borderRadius: BorderRadius.circular(config.style?.borderRadius ?? 8.0),
        boxShadow:
            config.style?.elevation != null && config.style!.elevation! > 0
                ? [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.1),
                    blurRadius: config.style!.elevation!,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  static Widget _createList(EnhancedComponentConfig config) {
    return EnhancedListWidget(config: config);
  }

  static Widget _createGrid(EnhancedComponentConfig config) {
    final children =
        config.children?.map((child) => createComponent(child)).toList() ?? [];
    final columns = config.columns ?? 2;
    final spacing = config.spacing ?? 8.0;

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
        config.children?.map((child) => createComponent(child)).toList() ?? [];

    return Row(
      mainAxisAlignment: _parseMainAxisAlignment(config.mainAxisAlignment),
      crossAxisAlignment: _parseCrossAxisAlignment(config.crossAxisAlignment),
      children: _applySpacing(children, Axis.horizontal, config.spacing ?? 0),
    );
  }

  static Widget _createColumn(EnhancedComponentConfig config) {
    final children =
        config.children?.map((child) => createComponent(child)).toList() ?? [];

    return Column(
      mainAxisAlignment: _parseMainAxisAlignment(config.mainAxisAlignment),
      crossAxisAlignment: _parseCrossAxisAlignment(config.crossAxisAlignment),
      children: _applySpacing(children, Axis.vertical, config.spacing ?? 0),
    );
  }

  static Widget _createCenter(EnhancedComponentConfig config) {
    final child =
        config.children?.isNotEmpty == true
            ? createComponent(config.children!.first)
            : const SizedBox.shrink();

    return Center(child: child);
  }

  static Widget _createHero(EnhancedComponentConfig config) {
    final children =
        config.children?.map((child) => createComponent(child)).toList() ?? [];

    return Container(
      padding:
          config.style?.padding?.toEdgeInsets() ?? const EdgeInsets.all(24),
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
    return StatefulBuilder(
      builder: (context, setState) {
        // Simple debounce using Timer if debounceMs specified
        Timer? _debounce;

        return CupertinoSearchTextField(
          placeholder: config.placeholder ?? 'Search...',
          onChanged: (value) {
            if (config.onChanged != null) {
              final debounceMs = config.onChanged!.debounceMs ?? 0;
              if (_debounce != null) {
                _debounce!.cancel();
                _debounce = null;
              }
              if (debounceMs > 0) {
                _debounce = Timer(Duration(milliseconds: debounceMs), () {
                  EnhancedActionDispatcher.execute(
                    context,
                    config.onChanged!,
                    {'value': value},
                  );
                });
              } else {
                EnhancedActionDispatcher.execute(
                  context,
                  config.onChanged!,
                  {'value': value},
                );
              }
            }
          },
        );
      },
    );
  }

  static Widget _createFilterChips(EnhancedComponentConfig config) {
    // This would be implemented with actual chip selection logic
    return const Placeholder(fallbackHeight: 40);
  }

  static Widget _createChip(EnhancedComponentConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _parseColor(config.style?.backgroundColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        config.text ?? 'Chip',
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
    return StatefulBuilder(
      builder: (context, setState) {
        String? stateKey;
        if (config.binding != null) {
          if (config.binding!.startsWith('\${state.')) {
            stateKey =
                config.binding!.substring(8, config.binding!.length - 1);
          } else {
            stateKey = config.binding;
          }
        } else if (config.onChanged?.params != null) {
          stateKey = config.onChanged!.params!['key']?.toString();
        }
        bool value = false;
        if (stateKey != null) {
          final current = _stateManager.getState(stateKey);
          if (current is bool) {
            value = current;
          } else if (current is num) {
            value = current != 0;
          }
        }
        return CupertinoSwitch(
          value: value,
          onChanged: (newValue) {
            setState(() {});
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

  static Widget _createSlider(EnhancedComponentConfig config) {
    return StatefulBuilder(
      builder: (context, setState) {
        String? stateKey;
        if (config.binding != null) {
          if (config.binding!.startsWith('\${state.')) {
            stateKey =
                config.binding!.substring(8, config.binding!.length - 1);
          } else {
            stateKey = config.binding;
          }
        } else if (config.onChanged?.params != null) {
          stateKey = config.onChanged!.params!['key']?.toString();
        }
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
        return CupertinoSlider(
          value: value,
          onChanged: (newValue) {
            setState(() {});
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

  // Helper methods
  static TextStyle _buildTextStyle(StyleConfig? style) {
    return TextStyle(
      fontSize: style?.fontSize ?? 16.0,
      fontWeight: _parseFontWeight(style?.fontWeight),
      color: _parseColor(style?.color),
    );
  }

  static Widget _withStyle(EnhancedComponentConfig config, Widget child) {
    Widget current = child;

    if (config.style != null) {
      final style = config.style!;

      // Apply container styling
      current = Container(
        width: style.width,
        height: style.height,
        constraints:
            style.maxWidth != null
                ? BoxConstraints(maxWidth: style.maxWidth!)
                : null,
        margin: style.margin?.toEdgeInsets(),
        child: current,
      );
    }

    return current;
  }

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
    return ParsingUtils.parseColor(colorString);
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

  static TextOverflow _parseTextOverflow(String? overflow) {
    switch (overflow) {
      case 'ellipsis':
        return TextOverflow.ellipsis;
      case 'fade':
        return TextOverflow.fade;
      case 'clip':
        return TextOverflow.clip;
      default:
        return TextOverflow.visible;
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

  static IconData _parseIcon(String? iconName) {
    if (iconName == null) return CupertinoIcons.circle;

    // Use contract icon mapping if available
    if (_contract?.assets.icons.containsKey(iconName) == true) {
      final iconPath = _contract!.assets.icons[iconName]!;
      // Parse CupertinoIcons path
      if (iconPath.startsWith('CupertinoIcons.')) {
        return _getCupertinoIcon(iconPath.substring(15));
      }
    }

    return _getCupertinoIcon(iconName);
  }

  static IconData _getCupertinoIcon(String name) {
    switch (name) {
      case 'house':
        return CupertinoIcons.house;
      case 'doc_text':
        return CupertinoIcons.doc_text;
      case 'person_circle':
        return CupertinoIcons.person_circle;
      case 'gear':
        return CupertinoIcons.gear;
      case 'plus':
        return CupertinoIcons.plus;
      case 'ellipsis':
        return CupertinoIcons.ellipsis;
      case 'chart_bar':
        return CupertinoIcons.chart_bar;
      case 'exclamationmark_triangle':
        return CupertinoIcons.exclamationmark_triangle;
      default:
        return CupertinoIcons.circle;
    }
  }
}

/// Enhanced list widget with data source integration
class EnhancedListWidget extends StatefulWidget {
  final EnhancedComponentConfig config;

  const EnhancedListWidget({super.key, required this.config});

  @override
  State<EnhancedListWidget> createState() => _EnhancedListWidgetState();
}

class _EnhancedListWidgetState extends State<EnhancedListWidget> {
  List<dynamic> items = [];
  bool loading = false;
  bool error = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.config.dataSource == null) return;

    setState(() {
      loading = true;
      error = false;
    });

    try {
      final dataSource = widget.config.dataSource!;
      final response = await ContractApiService().fetchList(
        service: dataSource.service ?? '',
        endpoint: dataSource.endpoint ?? '',
        params: dataSource.params,
        listPath: dataSource.listPath ?? 'data',
      );

      setState(() {
        items = response.data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
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

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return EnhancedComponentFactory.createComponent(
          widget.config.itemBuilder!.copyWith(boundData: item),
        );
      },
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
