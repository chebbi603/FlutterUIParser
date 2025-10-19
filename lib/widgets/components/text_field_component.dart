import 'package:flutter/cupertino.dart';
import '../../models/config_models.dart';
import '../../events/action_dispatcher.dart';
import '../../state/state_manager.dart';
import '../../utils/parsing_utils.dart';
import '../graph_subscriber.dart';
import 'common.dart';
import '../../validation/validator.dart';

class TextFieldComponent {
  static final EnhancedStateManager _stateManager = EnhancedStateManager();

  static Widget build(EnhancedComponentConfig config) {
    final stateKey = ComponentBindingUtils.resolveStateKey(config);
    final componentId = ComponentBindingUtils.componentIdFor(config, 'textField', stateKey);

    return GraphSubscriber(
      componentId: componentId,
      dependencies: stateKey != null ? [stateKey] : const <String>[],
      builder: (context) {
        final currentValue = stateKey != null ? (_stateManager.getState(stateKey) ?? '') : '';

        String? errorText;
        if (config.validation != null) {
          final validator = EnhancedValidator();
          final fieldId = config.name ?? stateKey ?? config.id ?? 'textField';
          final result = validator.validateField(fieldId, currentValue, config.validation!);
          if (!result.isValid) {
            errorText = result.message ?? 'Invalid input';
          }
        }

        return _ManagedTextField(
          key: ValueKey(componentId),
          componentId: componentId,
          config: config,
          stateKey: stateKey,
          value: currentValue.toString(),
          errorText: errorText,
        );
      },
    );
  }
}

class _ManagedTextField extends StatefulWidget {
  final String componentId;
  final EnhancedComponentConfig config;
  final String? stateKey;
  final String value;
  final String? errorText;

  const _ManagedTextField({
    super.key,
    required this.componentId,
    required this.config,
    required this.stateKey,
    required this.value,
    required this.errorText,
  });

  @override
  State<_ManagedTextField> createState() => _ManagedTextFieldState();
}

class _ManagedTextFieldState extends State<_ManagedTextField> {
  late final FocusNode focusNode;
  late final TextEditingController controller;
  String? _localErrorText;

  @override
  void initState() {
    super.initState();
    focusNode = FocusNode();
    controller = TextEditingController(text: widget.value);

    // Respect enabled flag: prevent focus when disabled (wired after config update)
    // ...
    final enabled = widget.config.enabled ?? true;
    focusNode.canRequestFocus = enabled;
    if (!enabled) {
      focusNode.unfocus();
    }

    // Initial validation
    if (widget.config.validation != null) {
      final validator = EnhancedValidator();
      final fieldId = widget.config.name ?? widget.stateKey ?? widget.componentId;
      final result = validator.validateField(fieldId, widget.value, widget.config.validation!);
      _localErrorText = result.isValid ? null : result.message;
    }
  }

  @override
  void didUpdateWidget(covariant _ManagedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!focusNode.hasFocus && controller.text != widget.value) {
      controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
    // Re-validate on external value updates
    if (widget.config.validation != null) {
      final validator = EnhancedValidator();
      final fieldId = widget.config.name ?? widget.stateKey ?? widget.componentId;
      final result = validator.validateField(fieldId, widget.value, widget.config.validation!);
      setState(() {
        _localErrorText = result.isValid ? null : result.message;
      });
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.config;
    final effectiveErrorText = widget.errorText ?? _localErrorText;

    final textField = Directionality(
      textDirection: TextDirection.ltr,
      child: CupertinoTextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.start,
        placeholder: c.placeholder ?? 'Enter text',
        keyboardType: ParsingUtils.parseKeyboardType(c.keyboardType),
        obscureText: c.obscureText ?? false,
        maxLines: c.maxLines ?? 1,
        onChanged: (value) {
          if (!(c.enabled ?? true)) return;
          if (widget.stateKey != null) {
            EnhancedStateManager().setState(widget.stateKey!, value);
          }
          if (c.onChanged != null) {
            EnhancedActionDispatcher.execute(context, c.onChanged!, {'value': value});
          }
          if (c.validation != null) {
            final validator = EnhancedValidator();
            final fieldId = c.name ?? widget.stateKey ?? widget.componentId;
            final result = validator.validateField(fieldId, value, c.validation!);
            setState(() {
              _localErrorText = result.isValid ? null : result.message;
            });
          }
        },
        decoration: BoxDecoration(
          border: Border.all(
            color: (() {
              final hasError = (effectiveErrorText != null && effectiveErrorText.isNotEmpty);
              return hasError ? CupertinoColors.destructiveRed : CupertinoColors.separator;
            })(),
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              c.label!,
              style: const TextStyle(fontSize: 13.0, color: CupertinoColors.systemGrey),
            ),
          ),
        textField,
        if (effectiveErrorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              effectiveErrorText,
              style: const TextStyle(fontSize: 12.0, color: CupertinoColors.destructiveRed),
            ),
          ),
      ],
    );

    return ComponentStyleUtils.withStyle(c, column);
  }
}