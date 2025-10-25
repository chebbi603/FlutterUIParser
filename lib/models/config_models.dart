import 'package:flutter/cupertino.dart';
import '../utils/parsing_utils.dart';

/// Enhanced configuration models for production-grade JSON-driven framework

/// Root canonical contract model
class CanonicalContract {
  final MetaConfig meta;
  final Map<String, DataModel> dataModels;
  final Map<String, ServiceConfig> services;
  final PagesUIConfig pagesUI;
  final StateConfig state;
  final EventsActionsConfig eventsActions;
  final ThemingAccessibilityConfig themingAccessibility;
  final AssetsConfig assets;
  final ValidationsConfig validations;
  final PermissionsFlagsConfig permissionsFlags;
  final PaginationConfig pagination;
  final AnalyticsConfig? analytics;

  CanonicalContract({
    required this.meta,
    required this.dataModels,
    required this.services,
    required this.pagesUI,
    required this.state,
    required this.eventsActions,
    required this.themingAccessibility,
    required this.assets,
    required this.validations,
    required this.permissionsFlags,
    required this.pagination,
    this.analytics,
  });

  factory CanonicalContract.fromJson(Map<String, dynamic> json) {
    return CanonicalContract(
      meta: MetaConfig.fromJson(json['meta'] ?? {}),
      dataModels: (json['dataModels'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, DataModel.fromJson(value)),
      ),
      services: (json['services'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, ServiceConfig.fromJson(value)),
      ),
      pagesUI: PagesUIConfig.fromJson(json['pagesUI'] ?? {}),
      state: StateConfig.fromJson(json['state'] ?? {}),
      eventsActions: EventsActionsConfig.fromJson(json['eventsActions'] ?? {}),
      themingAccessibility: ThemingAccessibilityConfig.fromJson(
        json['themingAccessibility'] ?? {},
      ),
      assets: AssetsConfig.fromJson(json['assets'] ?? {}),
      validations: ValidationsConfig.fromJson(json['validations'] ?? {}),
      permissionsFlags: PermissionsFlagsConfig.fromJson(
        json['permissionsFlags'] ?? {},
      ),
      pagination: PaginationConfig.fromJson(json['pagination'] ?? {}),
      analytics: json['analytics'] != null 
        ? AnalyticsConfig.fromJson(json['analytics'])
        : null,
    );
  }
}

/// Meta information about the application
class MetaConfig {
  final String appName;
  final String version;
  final String schemaVersion;
  final DateTime generatedAt;
  final List<String> authors;
  final String? description;
  final CompatibilityConfig? compatibility;

  MetaConfig({
    required this.appName,
    required this.version,
    required this.schemaVersion,
    required this.generatedAt,
    required this.authors,
    this.description,
    this.compatibility,
  });

  factory MetaConfig.fromJson(Map<String, dynamic> json) {
    return MetaConfig(
      appName: json['appName'] ?? 'App',
      version: json['version'] ?? '1.0.0',
      schemaVersion: json['schemaVersion'] ?? '1.0.0',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
      authors: List<String>.from(json['authors'] ?? []),
      description: json['description'],
      compatibility:
          json['compatibility'] != null
              ? CompatibilityConfig.fromJson(json['compatibility'])
              : null,
    );
  }
}

class CompatibilityConfig {
  final String minFlutterVersion;
  final List<String> targetPlatforms;

  CompatibilityConfig({
    required this.minFlutterVersion,
    required this.targetPlatforms,
  });

  factory CompatibilityConfig.fromJson(Map<String, dynamic> json) {
    return CompatibilityConfig(
      minFlutterVersion: json['minFlutterVersion'] ?? '3.0.0',
      targetPlatforms: List<String>.from(
        json['targetPlatforms'] ?? ['iOS', 'Android'],
      ),
    );
  }
}

/// Enhanced data model with relationships and validation
class DataModel {
  final Map<String, FieldConfig> fields;
  final Map<String, RelationshipConfig> relationships;
  final List<IndexConfig> indexes;

  DataModel({
    required this.fields,
    this.relationships = const {},
    this.indexes = const [],
  });

  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      fields: (json['fields'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, FieldConfig.fromJson(value)),
      ),
      relationships: (json['relationships'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, RelationshipConfig.fromJson(value)),
      ),
      indexes:
          (json['indexes'] as List? ?? [])
              .map((index) => IndexConfig.fromJson(index))
              .toList(),
    );
  }
}

class FieldConfig {
  final String type;
  final bool required;
  final bool primaryKey;
  final bool unique;
  final dynamic defaultValue;
  final String? validation;
  final int? minLength;
  final int? maxLength;
  final num? min;
  final num? max;
  final List<String>? enumValues;
  final String? foreignKey;
  final String? schema;
  final bool autoGenerate;
  final bool autoUpdate;

  FieldConfig({
    required this.type,
    this.required = false,
    this.primaryKey = false,
    this.unique = false,
    this.defaultValue,
    this.validation,
    this.minLength,
    this.maxLength,
    this.min,
    this.max,
    this.enumValues,
    this.foreignKey,
    this.schema,
    this.autoGenerate = false,
    this.autoUpdate = false,
  });

  factory FieldConfig.fromJson(Map<String, dynamic> json) {
    return FieldConfig(
      type: json['type'] ?? 'string',
      required: json['required'] ?? false,
      primaryKey: json['primaryKey'] ?? false,
      unique: json['unique'] ?? false,
      defaultValue: json['default'],
      validation: json['validation'],
      minLength: json['minLength'],
      maxLength: json['maxLength'],
      min: json['min'],
      max: json['max'],
      enumValues:
          json['values'] != null ? List<String>.from(json['values']) : null,
      foreignKey: json['foreignKey'],
      schema: json['schema'],
      autoGenerate: json['autoGenerate'] ?? false,
      autoUpdate: json['autoUpdate'] ?? false,
    );
  }
}

class RelationshipConfig {
  final String type; // hasOne, hasMany, belongsTo, belongsToMany
  final String model;
  final String? foreignKey;
  final String? through;

  RelationshipConfig({
    required this.type,
    required this.model,
    this.foreignKey,
    this.through,
  });

  factory RelationshipConfig.fromJson(Map<String, dynamic> json) {
    return RelationshipConfig(
      type: json['type'] ?? 'hasOne',
      model: json['model'] ?? '',
      foreignKey: json['foreignKey'],
      through: json['through'],
    );
  }
}

class IndexConfig {
  final List<String> fields;
  final bool unique;
  final Map<String, dynamic>? where;

  IndexConfig({required this.fields, this.unique = false, this.where});

  factory IndexConfig.fromJson(Map<String, dynamic> json) {
    return IndexConfig(
      fields: List<String>.from(json['fields'] ?? []),
      unique: json['unique'] ?? false,
      where: json['where'],
    );
  }
}

/// Enhanced service configuration with API contracts
class ServiceConfig {
  final String baseUrl;
  final Map<String, EndpointConfig> endpoints;

  ServiceConfig({required this.baseUrl, required this.endpoints});

  factory ServiceConfig.fromJson(Map<String, dynamic> json) {
    return ServiceConfig(
      baseUrl: json['baseUrl'] ?? '',
      endpoints: (json['endpoints'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, EndpointConfig.fromJson(value)),
      ),
    );
  }
}

class EndpointConfig {
  final String path;
  final String method;
  final dynamic auth; // bool or string
  final Map<String, QueryParamConfig>? queryParams;
  final Map<String, dynamic>? requestSchema;
  final Map<String, dynamic>? responseSchema;
  final Map<String, String>? errorCodes;
  final CachingConfig? caching;
  final RetryPolicyConfig? retryPolicy;

  EndpointConfig({
    required this.path,
    required this.method,
    this.auth,
    this.queryParams,
    this.requestSchema,
    this.responseSchema,
    this.errorCodes,
    this.caching,
    this.retryPolicy,
  });

  factory EndpointConfig.fromJson(Map<String, dynamic> json) {
    return EndpointConfig(
      path: json['path'] ?? '',
      method: json['method'] ?? 'GET',
      auth: json['auth'],
      queryParams:
          json['queryParams'] != null
              ? (json['queryParams'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, QueryParamConfig.fromJson(value)),
              )
              : null,
      requestSchema: json['requestSchema'],
      responseSchema: json['responseSchema'],
      errorCodes: json['errorCodes']?.cast<String, String>(),
      caching:
          json['caching'] != null
              ? CachingConfig.fromJson(json['caching'])
              : null,
      retryPolicy:
          json['retryPolicy'] != null
              ? RetryPolicyConfig.fromJson(json['retryPolicy'])
              : null,
    );
  }
}

class QueryParamConfig {
  final String type;
  final dynamic defaultValue;
  final num? min;
  final num? max;
  final List<String>? enumValues;
  final int? minLength;

  QueryParamConfig({
    required this.type,
    this.defaultValue,
    this.min,
    this.max,
    this.enumValues,
    this.minLength,
  });

  factory QueryParamConfig.fromJson(Map<String, dynamic> json) {
    return QueryParamConfig(
      type: json['type'] ?? 'string',
      defaultValue: json['default'],
      min: json['min'],
      max: json['max'],
      enumValues: json['enum'] != null ? List<String>.from(json['enum']) : null,
      minLength: json['minLength'],
    );
  }
}

class CachingConfig {
  final bool enabled;
  final int? ttlSeconds;

  CachingConfig({required this.enabled, this.ttlSeconds});

  factory CachingConfig.fromJson(Map<String, dynamic> json) {
    return CachingConfig(
      enabled: json['enabled'] ?? false,
      ttlSeconds: json['ttlSeconds'],
    );
  }
}

class RetryPolicyConfig {
  final int maxAttempts;
  final int backoffMs;

  RetryPolicyConfig({required this.maxAttempts, required this.backoffMs});

  factory RetryPolicyConfig.fromJson(Map<String, dynamic> json) {
    return RetryPolicyConfig(
      maxAttempts: json['maxAttempts'] ?? 3,
      backoffMs: json['backoffMs'] ?? 1000,
    );
  }
}

/// Enhanced UI configuration with routing and navigation
class PagesUIConfig {
  final Map<String, RouteConfig> routes;
  final EnhancedBottomNavigationConfig? bottomNavigation;
  final Map<String, EnhancedPageConfig> pages;

  PagesUIConfig({
    required this.routes,
    this.bottomNavigation,
    required this.pages,
  });

  factory PagesUIConfig.fromJson(Map<String, dynamic> json) {
    return PagesUIConfig(
      routes: (json['routes'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, RouteConfig.fromJson(value)),
      ),
      bottomNavigation:
          json['bottomNavigation'] != null
              ? EnhancedBottomNavigationConfig.fromJson(
                json['bottomNavigation'],
              )
              : null,
      pages: (json['pages'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, EnhancedPageConfig.fromJson(value)),
      ),
    );
  }
}

/// Enhanced bottom navigation configuration
class EnhancedBottomNavigationConfig {
  final bool enabled;
  final bool? authRequired;
  final int initialIndex;
  final StyleConfig? style;
  final List<BottomNavigationItemConfig> items;

  EnhancedBottomNavigationConfig({
    required this.enabled,
    this.authRequired,
    required this.initialIndex,
    this.style,
    required this.items,
  });

  factory EnhancedBottomNavigationConfig.fromJson(Map<String, dynamic> json) {
    return EnhancedBottomNavigationConfig(
      enabled: json['enabled'] ?? true,
      authRequired: json['authRequired'],
      initialIndex: json['initialIndex'] ?? 0,
      style: json['style'] != null ? StyleConfig.fromJson(json['style']) : null,
      items:
          (json['items'] as List? ?? [])
              .map((item) => BottomNavigationItemConfig.fromJson(item))
              .toList(),
    );
  }
}

class BottomNavigationItemConfig {
  final String pageId;
  final String title;
  final String icon;
  final String? badge;

  BottomNavigationItemConfig({
    required this.pageId,
    required this.title,
    required this.icon,
    this.badge,
  });

  factory BottomNavigationItemConfig.fromJson(Map<String, dynamic> json) {
    return BottomNavigationItemConfig(
      pageId: json['pageId'] ?? '',
      title: json['title'] ?? '',
      icon: json['icon'] ?? '',
      badge: json['badge'],
    );
  }
}

class RouteConfig {
  final String pageId;
  final dynamic auth; // bool or string
  final String? redirectIfAuth;
  final List<String>? params;

  RouteConfig({
    required this.pageId,
    this.auth,
    this.redirectIfAuth,
    this.params,
  });

  factory RouteConfig.fromJson(Map<String, dynamic> json) {
    return RouteConfig(
      pageId: json['pageId'] ?? '',
      auth: json['auth'],
      redirectIfAuth: json['redirectIfAuth'],
      params: json['params'] != null ? List<String>.from(json['params']) : null,
    );
  }
}

/// Enhanced page configuration with advanced features
class EnhancedPageConfig {
  final String id;
  final String title;
  final String layout;
  final EnhancedNavigationBarConfig? navigationBar;
  final List<EnhancedComponentConfig> children;
  final StyleConfig? style;

  EnhancedPageConfig({
    required this.id,
    required this.title,
    required this.layout,
    this.navigationBar,
    required this.children,
    this.style,
  });

  factory EnhancedPageConfig.fromJson(Map<String, dynamic> json) {
    return EnhancedPageConfig(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      layout: json['layout'] ?? 'column',
      navigationBar:
          json['navigationBar'] != null
              ? EnhancedNavigationBarConfig.fromJson(json['navigationBar'])
              : null,
      children:
          (json['children'] as List? ?? [])
              .map((child) => EnhancedComponentConfig.fromJson(child))
              .toList(),
      style: json['style'] != null ? StyleConfig.fromJson(json['style']) : null,
    );
  }
}

class EnhancedNavigationBarConfig {
  final String title;
  final String? style;
  final List<EnhancedComponentConfig>? actions;

  EnhancedNavigationBarConfig({required this.title, this.style, this.actions});

  factory EnhancedNavigationBarConfig.fromJson(Map<String, dynamic> json) {
    return EnhancedNavigationBarConfig(
      title: json['title'] ?? '',
      style: json['style'],
      actions:
          json['actions'] != null
              ? (json['actions'] as List)
                  .map((action) => EnhancedComponentConfig.fromJson(action))
                  .toList()
              : null,
    );
  }
}

/// Enhanced component configuration with advanced features
class EnhancedComponentConfig {
  final String type;
  final String? id;
  final String? text;
  final String? src;
  final String? binding;
  final String? label;
  final String? placeholder;
  final String? icon;
  final String? name;
  final int? size;
  final int? columns;
  final int? flex;
  final int? maxLines;
  final String? overflow;
  final bool? obscureText;
  final String? keyboardType;
  final List<String>? permissions;
  final List<EnhancedComponentConfig>? children;
  final EnhancedDataSourceConfig? dataSource;
  final EnhancedComponentConfig? itemBuilder;
  final EnhancedComponentConfig? emptyState;
  final EnhancedComponentConfig? loadingState;
  final EnhancedComponentConfig? errorState;
  final ValidationConfig? validation;
  final StyleConfig? style;
  final ActionConfig? onTap;
  final ActionConfig? onChanged;
  final ActionConfig? onSubmit;
  final String? mainAxisAlignment;
  final String? crossAxisAlignment;
  final double? spacing;
  final Map<String, dynamic>? boundData;
  final bool? enabled;

  EnhancedComponentConfig({
    required this.type,
    this.id,
    this.text,
    this.src,
    this.binding,
    this.label,
    this.placeholder,
    this.icon,
    this.name,
    this.size,
    this.columns,
    this.flex,
    this.maxLines,
    this.overflow,
    this.obscureText,
    this.keyboardType,
    this.permissions,
    this.children,
    this.dataSource,
    this.itemBuilder,
    this.emptyState,
    this.loadingState,
    this.errorState,
    this.validation,
    this.style,
    this.onTap,
    this.onChanged,
    this.onSubmit,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.spacing,
    this.boundData,
    this.enabled,
  });

  factory EnhancedComponentConfig.fromJson(Map<String, dynamic> json) {
    return EnhancedComponentConfig(
      type: json['type'] ?? '',
      id: json['id'],
      text: json['text'],
      src: json['src'] ?? json['text'],
      binding: json['binding'],
      label: json['label'],
      placeholder: json['placeholder'],
      icon: json['icon'],
      name: json['name'],
      size: json['size'],
      columns: json['columns'],
      flex: json['flex'],
      maxLines: json['maxLines'],
      overflow: json['overflow'],
      obscureText: json['obscureText'],
      keyboardType: json['keyboardType'],
      permissions:
          json['permissions'] != null
              ? List<String>.from(json['permissions'])
              : null,
      children:
          json['children'] != null
              ? (json['children'] as List)
                  .map((child) => EnhancedComponentConfig.fromJson(child))
                  .toList()
              : null,
      dataSource:
          json['dataSource'] != null
              ? EnhancedDataSourceConfig.fromJson(json['dataSource'])
              : null,
      itemBuilder:
          json['itemBuilder'] != null
              ? EnhancedComponentConfig.fromJson(json['itemBuilder'])
              : null,
      emptyState:
          json['emptyState'] != null
              ? EnhancedComponentConfig.fromJson(json['emptyState'])
              : null,
      loadingState:
          json['loadingState'] != null
              ? EnhancedComponentConfig.fromJson(json['loadingState'])
              : null,
      errorState:
          json['errorState'] != null
              ? EnhancedComponentConfig.fromJson(json['errorState'])
              : null,
      validation:
          json['validation'] != null
              ? ValidationConfig.fromJson(json['validation'])
              : null,
      style: json['style'] != null ? StyleConfig.fromJson(json['style']) : null,
      onTap:
          json['onTap'] != null ? ActionConfig.fromJson(json['onTap']) : null,
      onChanged:
          json['onChanged'] != null
              ? ActionConfig.fromJson(json['onChanged'])
              : null,
      onSubmit:
          json['onSubmit'] != null
              ? ActionConfig.fromJson(json['onSubmit'])
              : null,
      mainAxisAlignment: json['mainAxisAlignment'],
      crossAxisAlignment: json['crossAxisAlignment'],
      spacing: ParsingUtils.safeToDouble(json['spacing']),
      boundData: json['boundData'],
      enabled: json['enabled'] ?? true,
    );
  }

  EnhancedComponentConfig copyWith({
    String? type,
    String? id,
    String? text,
    String? src,
    String? binding,
    Map<String, dynamic>? boundData,
    bool? enabled,
  }) {
    return EnhancedComponentConfig(
      type: type ?? this.type,
      id: id ?? this.id,
      text: text ?? this.text,
      src: src ?? this.src,
      binding: binding ?? this.binding,
      label: label,
      placeholder: placeholder,
      icon: icon,
      name: name,
      size: size,
      columns: columns,
      flex: flex,
      maxLines: maxLines,
      overflow: overflow,
      obscureText: obscureText,
      keyboardType: keyboardType,
      permissions: permissions,
      children: children,
      dataSource: dataSource,
      itemBuilder: itemBuilder,
      emptyState: emptyState,
      loadingState: loadingState,
      errorState: errorState,
      validation: validation,
      style: style,
      onTap: onTap,
      onChanged: onChanged,
      onSubmit: onSubmit,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      spacing: spacing,
      boundData: boundData ?? this.boundData,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Enhanced data source with advanced features
class EnhancedDataSourceConfig {
  final String? service;
  final String? endpoint;
  final Map<String, dynamic>? params;
  final String? listPath;
  final EnhancedPaginationConfig? pagination;
  final bool? virtualScrolling;

  EnhancedDataSourceConfig({
    this.service,
    this.endpoint,
    this.params,
    this.listPath,
    this.pagination,
    this.virtualScrolling,
  });

  factory EnhancedDataSourceConfig.fromJson(Map<String, dynamic> json) {
    return EnhancedDataSourceConfig(
      service: json['service'],
      endpoint: json['endpoint'],
      params: json['params'],
      listPath: json['listPath'],
      pagination:
          json['pagination'] != null
              ? EnhancedPaginationConfig.fromJson(json['pagination'])
              : null,
      virtualScrolling: json['virtualScrolling'],
    );
  }
}

class EnhancedPaginationConfig {
  final bool enabled;
  final String? totalPath;
  final String? pagePath;
  final bool autoLoad;

  EnhancedPaginationConfig({
    required this.enabled,
    this.totalPath,
    this.pagePath,
    this.autoLoad = false,
  });

  factory EnhancedPaginationConfig.fromJson(Map<String, dynamic> json) {
    return EnhancedPaginationConfig(
      enabled: json['enabled'] ?? true,
      totalPath: json['totalPath'],
      pagePath: json['pagePath'],
      autoLoad: json['autoLoad'] ?? false,
    );
  }
}

/// Style configuration for components
class StyleConfig {
  final double? fontSize;
  final String? fontWeight;
  final String? color;
  final String? backgroundColor;
  final String? foregroundColor;
  final String? textAlign;
  final double? width;
  final double? height;
  final double? maxWidth;
  final double? borderRadius;
  final double? elevation;
  final EdgeInsetsConfig? padding;
  final EdgeInsetsConfig? margin;

  StyleConfig({
    this.fontSize,
    this.fontWeight,
    this.color,
    this.backgroundColor,
    this.foregroundColor,
    this.textAlign,
    this.width,
    this.height,
    this.maxWidth,
    this.borderRadius,
    this.elevation,
    this.padding,
    this.margin,
  });

  factory StyleConfig.fromJson(Map<String, dynamic> json) {
    return StyleConfig(
      fontSize: ParsingUtils.safeToDouble(json['fontSize']),
      fontWeight: json['fontWeight'],
      color: json['color'],
      backgroundColor: json['backgroundColor'],
      foregroundColor: json['foregroundColor'],
      textAlign: json['textAlign'],
      width: ParsingUtils.safeToDouble(json['width']),
      height: ParsingUtils.safeToDouble(json['height']),
      maxWidth: ParsingUtils.safeToDouble(json['maxWidth']),
      borderRadius: ParsingUtils.safeToDouble(json['borderRadius']),
      elevation: ParsingUtils.safeToDouble(json['elevation']),
      padding:
          json['padding'] != null
              ? EdgeInsetsConfig.fromJson(json['padding'])
              : null,
      margin:
          json['margin'] != null
              ? EdgeInsetsConfig.fromJson(json['margin'])
              : null,
    );
  }
}

class EdgeInsetsConfig {
  final double? all;
  final double? horizontal;
  final double? vertical;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  EdgeInsetsConfig({
    this.all,
    this.horizontal,
    this.vertical,
    this.top,
    this.bottom,
    this.left,
    this.right,
  });

  factory EdgeInsetsConfig.fromJson(dynamic json) {
    if (json is num || json is String) {
      return EdgeInsetsConfig(all: ParsingUtils.safeToDouble(json));
    }
    if (json is Map<String, dynamic>) {
      return EdgeInsetsConfig(
        all: ParsingUtils.safeToDouble(json['all']),
        horizontal: ParsingUtils.safeToDouble(json['horizontal']),
        vertical: ParsingUtils.safeToDouble(json['vertical']),
        top: ParsingUtils.safeToDouble(json['top']),
        bottom: ParsingUtils.safeToDouble(json['bottom']),
        left: ParsingUtils.safeToDouble(json['left']),
        right: ParsingUtils.safeToDouble(json['right']),
      );
    }
    return EdgeInsetsConfig();
  }

  EdgeInsets toEdgeInsets() {
    if (all != null) {
      return EdgeInsets.all(all!);
    }
    if (horizontal != null || vertical != null) {
      return EdgeInsets.symmetric(
        horizontal: horizontal ?? 0,
        vertical: vertical ?? 0,
      );
    }
    return EdgeInsets.fromLTRB(left ?? 0, top ?? 0, right ?? 0, bottom ?? 0);
  }
}

/// Validation configuration
class ValidationConfig {
  final bool? required;
  final bool? email;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final String? message;

  ValidationConfig({
    this.required,
    this.email,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.message,
  });

  factory ValidationConfig.fromJson(Map<String, dynamic> json) {
    return ValidationConfig(
      required: json['required'],
      email: json['email'],
      minLength: json['minLength'],
      maxLength: json['maxLength'],
      pattern: json['pattern'],
      message: json['message'],
    );
  }
}

/// Enhanced action configuration
class ActionConfig {
  final String action;
  final Map<String, dynamic>? params;
  final String? route;
  final String? service;
  final String? endpoint;
  final String? key;
  final dynamic value;
  final String? scope;
  final ActionConfig? onSuccess;
  final ActionConfig? onError;
  final int? debounceMs;

  ActionConfig({
    required this.action,
    this.params,
    this.route,
    this.service,
    this.endpoint,
    this.key,
    this.value,
    this.scope,
    this.onSuccess,
    this.onError,
    this.debounceMs,
  });

  factory ActionConfig.fromJson(dynamic json) {
    if (json == null) return ActionConfig(action: 'none');
    if (json is String) return ActionConfig(action: json);

    final map = json as Map<String, dynamic>;
    return ActionConfig(
      action: map['action'] ?? 'none',
      params: map['params'],
      route: map['route'],
      service: map['service'],
      endpoint: map['endpoint'],
      key: map['key'],
      value: map['value'],
      scope: map['scope'],
      onSuccess:
          map['onSuccess'] != null
              ? ActionConfig.fromJson(map['onSuccess'])
              : null,
      onError:
          map['onError'] != null ? ActionConfig.fromJson(map['onError']) : null,
      debounceMs: map['debounceMs'],
    );
  }
}

/// State management configuration
class StateConfig {
  final Map<String, StateFieldConfig> global;
  final Map<String, Map<String, StateFieldConfig>> pages;

  StateConfig({required this.global, required this.pages});

  factory StateConfig.fromJson(Map<String, dynamic> json) {
    return StateConfig(
      global: (json['global'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, StateFieldConfig.fromJson(value)),
      ),
      pages: (json['pages'] as Map<String, dynamic>? ?? {}).map(
        (pageKey, pageValue) => MapEntry(
          pageKey,
          (pageValue as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, StateFieldConfig.fromJson(value)),
          ),
        ),
      ),
    );
  }
}

class StateFieldConfig {
  final String type;
  final String? persistence;
  final dynamic defaultValue;
  final List<String>? enumValues;
  final String? schema;

  StateFieldConfig({
    required this.type,
    this.persistence,
    this.defaultValue,
    this.enumValues,
    this.schema,
  });

  factory StateFieldConfig.fromJson(Map<String, dynamic> json) {
    return StateFieldConfig(
      type: json['type'] ?? 'string',
      persistence: json['persistence'],
      defaultValue: json['default'],
      enumValues: json['enum'] != null ? List<String>.from(json['enum']) : null,
      schema: json['schema'],
    );
  }
}

/// Events and actions configuration
class EventsActionsConfig {
  final List<ActionConfig>? onAppStart;
  final List<ActionConfig>? onLogin;
  final List<ActionConfig>? onLogout;
  final Map<String, ActionDefinitionConfig> actions;

  EventsActionsConfig({
    this.onAppStart,
    this.onLogin,
    this.onLogout,
    required this.actions,
  });

  factory EventsActionsConfig.fromJson(Map<String, dynamic> json) {
    return EventsActionsConfig(
      onAppStart:
          json['onAppStart'] != null
              ? (json['onAppStart'] as List)
                  .map((e) => ActionConfig.fromJson(e))
                  .toList()
              : null,
      onLogin:
          json['onLogin'] != null
              ? (json['onLogin'] as List)
                  .map((e) => ActionConfig.fromJson(e))
                  .toList()
              : null,
      onLogout:
          json['onLogout'] != null
              ? (json['onLogout'] as List)
                  .map((e) => ActionConfig.fromJson(e))
                  .toList()
              : null,
      actions: (json['actions'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, ActionDefinitionConfig.fromJson(value)),
      ),
    );
  }
}

class ActionDefinitionConfig {
  final List<String> params;
  final String implementation;

  ActionDefinitionConfig({required this.params, required this.implementation});

  factory ActionDefinitionConfig.fromJson(Map<String, dynamic> json) {
    return ActionDefinitionConfig(
      params: List<String>.from(json['params'] ?? []),
      implementation: json['implementation'] ?? '',
    );
  }
}

/// Theming and accessibility configuration
class ThemingAccessibilityConfig {
  final Map<String, Map<String, String>> tokens;
  final Map<String, TypographyConfig> typography;
  final AccessibilityConfig accessibility;

  ThemingAccessibilityConfig({
    required this.tokens,
    required this.typography,
    required this.accessibility,
  });

  factory ThemingAccessibilityConfig.fromJson(Map<String, dynamic> json) {
    return ThemingAccessibilityConfig(
      tokens: (json['tokens'] as Map<String, dynamic>? ?? {}).map((key, value) {
        if (value is Map) {
          final mapped = value.map(
            (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
          );
          return MapEntry(key, Map<String, String>.from(mapped));
        }
        // Fallback to empty map if token section is invalid
        return MapEntry(key, <String, String>{});
      }),
      typography: (json['typography'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, TypographyConfig.fromJson(value)),
      ),
      accessibility: AccessibilityConfig.fromJson(json['accessibility'] ?? {}),
    );
  }
}

class TypographyConfig {
  final double fontSize;
  final String fontWeight;
  final double lineHeight;

  TypographyConfig({
    required this.fontSize,
    required this.fontWeight,
    required this.lineHeight,
  });

  factory TypographyConfig.fromJson(Map<String, dynamic> json) {
    return TypographyConfig(
      fontSize: ParsingUtils.safeToDouble(json['fontSize']) ?? 16.0,
      fontWeight: json['fontWeight'] ?? 'regular',
      lineHeight: ParsingUtils.safeToDouble(json['lineHeight']) ?? 1.4,
    );
  }
}

class AccessibilityConfig {
  final double minimumTouchTarget;
  final double contrastRatio;
  final Map<String, String> semanticLabels;
  final bool voiceOverSupport;
  final bool dynamicType;
  final bool reduceMotion;

  AccessibilityConfig({
    required this.minimumTouchTarget,
    required this.contrastRatio,
    required this.semanticLabels,
    required this.voiceOverSupport,
    required this.dynamicType,
    required this.reduceMotion,
  });

  factory AccessibilityConfig.fromJson(Map<String, dynamic> json) {
    return AccessibilityConfig(
      minimumTouchTarget:
          ParsingUtils.safeToDouble(json['minimumTouchTarget']) ?? 44.0,
      contrastRatio: ParsingUtils.safeToDouble(json['contrastRatio']) ?? 4.5,
      semanticLabels: Map<String, String>.from(json['semanticLabels'] ?? {}),
      voiceOverSupport: json['voiceOverSupport'] ?? true,
      dynamicType: json['dynamicType'] ?? true,
      reduceMotion: json['reduceMotion'] ?? true,
    );
  }
}

/// Assets configuration
class AssetsConfig {
  final Map<String, dynamic> images;
  final Map<String, String> icons;
  final Map<String, dynamic> fonts;
  final LazyLoadingConfig lazyLoading;

  AssetsConfig({
    required this.images,
    required this.icons,
    required this.fonts,
    required this.lazyLoading,
  });

  factory AssetsConfig.fromJson(Map<String, dynamic> json) {
    return AssetsConfig(
      images: json['images'] ?? {},
      icons: ((json['icons']?['mapping'] as Map<String, dynamic>? ?? {})).map(
        (k, v) => MapEntry(k, v?.toString() ?? ''),
      ),
      fonts: json['fonts'] ?? {},
      lazyLoading: LazyLoadingConfig.fromJson(json['lazyLoading'] ?? {}),
    );
  }
}

class LazyLoadingConfig {
  final bool enabled;
  final String? placeholder;
  final String? errorFallback;

  LazyLoadingConfig({
    required this.enabled,
    this.placeholder,
    this.errorFallback,
  });

  factory LazyLoadingConfig.fromJson(Map<String, dynamic> json) {
    return LazyLoadingConfig(
      enabled: json['enabled'] ?? true,
      placeholder: json['placeholder'],
      errorFallback: json['errorFallback'],
    );
  }
}

/// Validations configuration
class ValidationsConfig {
  final Map<String, ValidationRuleConfig> rules;
  final Map<String, CrossFieldValidationConfig> crossField;

  ValidationsConfig({required this.rules, required this.crossField});

  factory ValidationsConfig.fromJson(Map<String, dynamic> json) {
    return ValidationsConfig(
      rules: (json['rules'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, ValidationRuleConfig.fromJson(value)),
      ),
      crossField: (json['crossField'] as Map<String, dynamic>? ?? {}).map(
        (key, value) =>
            MapEntry(key, CrossFieldValidationConfig.fromJson(value)),
      ),
    );
  }
}

class ValidationRuleConfig {
  final String? pattern;
  final int? minLength;
  final bool? required;
  final String message;

  ValidationRuleConfig({
    this.pattern,
    this.minLength,
    this.required,
    required this.message,
  });

  factory ValidationRuleConfig.fromJson(Map<String, dynamic> json) {
    return ValidationRuleConfig(
      pattern: json['pattern'],
      minLength: json['minLength'],
      required: json['required'],
      message: json['message'] ?? 'Validation failed',
    );
  }
}

class CrossFieldValidationConfig {
  final List<String> fields;
  final String rule;
  final String message;

  CrossFieldValidationConfig({
    required this.fields,
    required this.rule,
    required this.message,
  });

  factory CrossFieldValidationConfig.fromJson(Map<String, dynamic> json) {
    return CrossFieldValidationConfig(
      fields: List<String>.from(json['fields'] ?? []),
      rule: json['rule'] ?? '',
      message: json['message'] ?? 'Validation failed',
    );
  }
}

/// Permissions and flags configuration
class PermissionsFlagsConfig {
  final Map<String, RoleConfig> roles;
  final Map<String, FeatureFlagConfig> featureFlags;

  PermissionsFlagsConfig({required this.roles, required this.featureFlags});

  factory PermissionsFlagsConfig.fromJson(Map<String, dynamic> json) {
    return PermissionsFlagsConfig(
      roles: (json['roles'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, RoleConfig.fromJson(value)),
      ),
      featureFlags: (json['featureFlags'] as Map<String, dynamic>? ?? {}).map(
        (key, value) => MapEntry(key, FeatureFlagConfig.fromJson(value)),
      ),
    );
  }
}

class RoleConfig {
  final List<String> permissions;
  final List<String>? inherits;

  RoleConfig({required this.permissions, this.inherits});

  factory RoleConfig.fromJson(Map<String, dynamic> json) {
    return RoleConfig(
      permissions: List<String>.from(json['permissions'] ?? []),
      inherits:
          json['inherits'] != null ? List<String>.from(json['inherits']) : null,
    );
  }
}

class FeatureFlagConfig {
  final bool enabled;
  final int rolloutPercentage;
  final List<String>? targetRoles;

  FeatureFlagConfig({
    required this.enabled,
    required this.rolloutPercentage,
    this.targetRoles,
  });

  factory FeatureFlagConfig.fromJson(Map<String, dynamic> json) {
    return FeatureFlagConfig(
      enabled: json['enabled'] ?? false,
      rolloutPercentage: json['rolloutPercentage'] ?? 0,
      targetRoles:
          json['targetRoles'] != null
              ? List<String>.from(json['targetRoles'])
              : null,
    );
  }
}

/// Pagination configuration
class PaginationConfig {
  final PaginationDefaultsConfig defaults;
  final SortingDefaultsConfig sorting;
  final FilteringConfig filtering;

  PaginationConfig({
    required this.defaults,
    required this.sorting,
    required this.filtering,
  });

  factory PaginationConfig.fromJson(Map<String, dynamic> json) {
    return PaginationConfig(
      defaults: PaginationDefaultsConfig.fromJson(json['defaults'] ?? {}),
      sorting: SortingDefaultsConfig.fromJson(
        json['sorting']?['defaults'] ?? {},
      ),
      filtering: FilteringConfig.fromJson(json['filtering'] ?? {}),
    );
  }
}

class PaginationDefaultsConfig {
  final int pageSize;
  final int maxPageSize;
  final String pageParam;
  final String sizeParam;

  PaginationDefaultsConfig({
    required this.pageSize,
    required this.maxPageSize,
    required this.pageParam,
    required this.sizeParam,
  });

  factory PaginationDefaultsConfig.fromJson(Map<String, dynamic> json) {
    return PaginationDefaultsConfig(
      pageSize: json['pageSize'] ?? 20,
      maxPageSize: json['maxPageSize'] ?? 100,
      pageParam: json['pageParam'] ?? 'page',
      sizeParam: json['sizeParam'] ?? 'limit',
    );
  }
}

class SortingDefaultsConfig {
  final String sortParam;
  final String orderParam;
  final String defaultSort;
  final String defaultOrder;

  SortingDefaultsConfig({
    required this.sortParam,
    required this.orderParam,
    required this.defaultSort,
    required this.defaultOrder,
  });

  factory SortingDefaultsConfig.fromJson(Map<String, dynamic> json) {
    return SortingDefaultsConfig(
      sortParam: json['sortParam'] ?? 'sortBy',
      orderParam: json['orderParam'] ?? 'sortOrder',
      defaultSort: json['defaultSort'] ?? 'createdAt',
      defaultOrder: json['defaultOrder'] ?? 'desc',
    );
  }
}

class FilteringConfig {
  final Map<String, String> operators;

  FilteringConfig({required this.operators});

  factory FilteringConfig.fromJson(Map<String, dynamic> json) {
    return FilteringConfig(
      operators: Map<String, String>.from(json['operators'] ?? {}),
    );
  }
}

/// Analytics configuration for tracking user behavior
class AnalyticsConfig {
  final bool enabled;
  final bool mockMode;
  final int batchSize;
  final int batchIntervalSeconds;
  final String? backendUrl;
  final double samplingRate;
  final List<String> trackedComponents;
  final List<String> trackedEventTypes;
  final int maxRetries;
  final int requestTimeoutMs;
  final int initialBackoffMs;

  AnalyticsConfig({
    this.enabled = true,
    this.mockMode = true,
    this.batchSize = 50,
    this.batchIntervalSeconds = 30,
    this.backendUrl,
    this.samplingRate = 1.0,
    this.trackedComponents = const [],
    this.trackedEventTypes = const [
      'tap', 'input', 'pageEnter', 'pageExit', 'formSubmit', 'error'
    ],
    this.maxRetries = 3,
    this.requestTimeoutMs = 5000,
    this.initialBackoffMs = 500,
  });

  factory AnalyticsConfig.fromJson(Map<String, dynamic> json) {
    return AnalyticsConfig(
      enabled: json['enabled'] ?? true,
      mockMode: json['mockMode'] ?? true,
      batchSize: json['batchSize'] ?? 50,
      batchIntervalSeconds: json['batchIntervalSeconds'] ?? 30,
      backendUrl: json['backendUrl'],
      samplingRate: (json['samplingRate'] ?? 1.0).toDouble(),
      trackedComponents: List<String>.from(json['trackedComponents'] ?? []),
      trackedEventTypes: List<String>.from(
        json['trackedEventTypes'] ?? [
          'tap', 'input', 'pageEnter', 'pageExit', 'formSubmit', 'error'
        ]
      ),
      maxRetries: json['maxRetries'] ?? 3,
      requestTimeoutMs: json['requestTimeoutMs'] ?? 5000,
      initialBackoffMs: json['initialBackoffMs'] ?? 500,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'mockMode': mockMode,
      'batchSize': batchSize,
      'batchIntervalSeconds': batchIntervalSeconds,
      'backendUrl': backendUrl,
      'samplingRate': samplingRate,
      'trackedComponents': trackedComponents,
      'trackedEventTypes': trackedEventTypes,
      'maxRetries': maxRetries,
      'requestTimeoutMs': requestTimeoutMs,
      'initialBackoffMs': initialBackoffMs,
    };
  }

  bool shouldTrackEvent(String eventType) {
    return trackedEventTypes.contains(eventType);
  }
}
