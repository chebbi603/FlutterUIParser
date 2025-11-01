Project: demo_json_parser (Flutter)
# Canonical JSON-Driven Framework Guide

## Overview

This framework implements a production-grade, JSON-driven application architecture where a single canonical JSON contract serves as the source of truth for data models, API contracts, UI rendering, business logic, state management, and deployment configuration.

## Graph-Based Rendering Engine

- The runtime maintains a DAG of dependencies among state, data sources, actions, and components.
- Cycle detection prevents invalid dependencies.
- Updates propagate using a topological order to only rerender affected subscribers.
- Components subscribe via `GraphSubscriber(componentId, dependencies: [...])` and rebuild when their sources tick.

## Centralized State

- `EnhancedStateManager` provides global and page-scoped state.
- Persistence policies: `local`, `secure`, `session`, `memory`.
- Bind UI using `${state.key}` in component configs.
- Undo/redo and optimistic updates:
  - Use `ActionConfig { action: "updateState" }` or `apiCall` with `params.optimisticState`.
  - Rollback occurs automatically if the `apiCall` fails.

## Data Layer

- Endpoints describe method, path, auth, params, caching, retry, and response schema.
- Request deduplication merges concurrent identical calls.
- Pagination:
  - List components use `dataSource.pagination { enabled, totalPath, pagePath, autoLoad }`.
  - `autoLoad` triggers fetching the next page when the footer is visible.
- Response validation uses basic JSON Schema semantics from `responseSchema`.

## Component Factory

- Components are delegated to dedicated builders under `lib/widgets/components`.
- Styles resolve theme tokens from `themingAccessibility.tokens`.
- Registry validates required props and applies defaults.

## Action System

- Actions: navigate, pop, openUrl, apiCall, updateState, showError, showSuccess, submitForm, refreshData, showBottomSheet, showDialog, clearCache, undo, redo.
- Middleware supports logging and can be extended for permissions and analytics.
- Event bus emits `ActionStarted`, `ActionCompleted`, `ActionFailed` for instrumentation.

## Validation

- Field-level validation keys: `required`, `email`, `minLength`, `maxLength`, `pattern`, `message`.
- Rule-based validations via `validations.rules`; cross-field rules via `validations.crossField`.

## Development

- Run `flutter pub get` then `flutter run` to launch on the iOS simulator.
- Use `dart analyze` to keep the codebase lint-free.

## Architecture Principles

### Single Source of Truth
- **Canonical Contract**: One JSON file defines the entire application
- **Code Generation**: All models, services, and UI are generated from the contract
- **Schema Evolution**: Versioned migrations ensure backward compatibility
- **Type Safety**: Strong typing throughout the stack

### Core Components

1. **Canonical Contract** (`canonical_contract.json`)
   - Meta information and versioning
   - Data models with relationships
   - Service definitions and API contracts
   - UI pages and component definitions
   - State management configuration
   - Events and actions
   - Theming and accessibility
   - Assets and validation rules
   - Permissions and feature flags

2. **Enhanced Models** (`lib/models/enhanced_config_models.dart`)
   - Type-safe Dart models for all contract sections
   - Automatic JSON serialization/deserialization
   - Validation and constraint checking

3. **Services Layer** (`lib/services/enhanced_api_service.dart`)
   - Contract-driven API client
   - Automatic request/response validation
   - Caching and retry policies
   - Error handling and fallbacks

4. **UI System** (`lib/widgets/enhanced_component_factory.dart`)
   - Dynamic component rendering from JSON
   - Theme token resolution
   - Permission-based visibility
   - Data binding and state integration

5. **State Management** (`lib/state/enhanced_state_manager.dart`)
   - Scoped state (global, page, session, memory)
   - Automatic persistence based on configuration
   - Reactive updates with ChangeNotifier

## Contract Structure

### Meta Section
```json
{
  "meta": {
    "appName": "My App",
    "version": "1.0.0",
    "schemaVersion": "2.0.0",
    "generatedAt": "2024-12-18T10:00:00Z",
    "authors": ["Developer Name"],
    "compatibility": {
      "minFlutterVersion": "3.7.0",
      "targetPlatforms": ["iOS", "Android", "Web"]
    }
  }
}
```

### Data Models
```json
{
  "dataModels": {
    "User": {
      "fields": {
        "id": { "type": "string", "required": true, "primaryKey": true },
        "email": { "type": "string", "required": true, "validation": "email" },
        "name": { "type": "string", "required": true, "minLength": 2 }
      },
      "relationships": {
        "posts": { "type": "hasMany", "model": "Post", "foreignKey": "userId" }
      },
      "indexes": [
        { "fields": ["email"], "unique": true }
      ]
    }
  }
}
```

### Services
```json
{
  "services": {
    "auth": {
      "baseUrl": "${API_BASE_URL}/auth",
      "endpoints": {
        "login": {
          "path": "/login",
          "method": "POST",
          "auth": false,
          "requestSchema": {
            "type": "object",
            "properties": {
              "email": { "type": "string", "format": "email" },
              "password": { "type": "string", "minLength": 8 }
            },
            "required": ["email", "password"]
          },
          "responseSchema": {
            "type": "object",
            "properties": {
              "token": { "type": "string" },
              "user": { "$ref": "#/dataModels/User" }
            }
          },
          "caching": { "enabled": false },
          "retryPolicy": { "maxAttempts": 3, "backoffMs": 1000 }
        }
      }
    }
  }
}
```

#### Service Name Aliasing (new)
- The contract parser normalizes service names to create convenient aliases.
- Any service key that ends with `Service` or `Api` gains a lowercase alias with the suffix removed.
- The original key is preserved; explicit aliases in the contract are never overridden.
- Examples:
  - `AuthService` -> alias `auth`
  - `UserApi` -> alias `user`
  - `CatalogService` -> alias `catalog`

Example input and resulting access:
```json
{
  "services": [
    {
      "name": "AuthService",
      "baseUrl": "${API_BASE_URL}/auth",
      "endpoints": [ { "name": "login", "path": "/login", "method": "POST" } ]
    }
  ]
}
```

- During parsing, both keys are available: `"AuthService"` and `"auth"`.
- In Flutter, you may reference either name. The alias keeps code concise:
  - `contract.services['auth']`
  - `contract.services['AuthService']`

Notes:
- Aliasing only applies to keys that literally end with `Service` or `Api`.
- If the normalized alias already exists in the input, the explicit mapping is kept as‑is.
- This behavior improves interoperability with backends that prefer verbose names while enabling succinct frontend usage.

### UI Pages
```json
{
  "pagesUI": {
    "routes": {
      "/": { "pageId": "home", "auth": false },
      "/dashboard": { "pageId": "dashboard", "auth": true }
    },
    "bottomNavigation": {
      "enabled": true,
      "items": [
        { "pageId": "home", "title": "Home", "icon": "house" },
        { "pageId": "dashboard", "title": "Dashboard", "icon": "chart.bar" }
      ]
    },
    "pages": {
      "home": {
        "id": "home",
        "title": "Welcome",
        "layout": "scroll",
        "children": [
          {
            "type": "text",
            "text": "Welcome to ${meta.appName}",
            "style": {
              "fontSize": 24,
              "fontWeight": "bold",
              "color": "${theme.primary}"
            }
          }
        ]
      }
    }
  }
}
```

### Bottom Navigation Enhancements
- Items support either `pageId` or `route` to resolve the tab’s page.
  - If `route` is provided, it maps directly via `NavigationBridge.switchTo(route)`.
  - If only `pageId` is provided, the app infers the route from `pagesUI.routes` where `routeConfig.pageId == item.pageId`.
- Items accept `title` or `label` for the displayed tab text.
- `initialIndex` selects the starting tab; `style` allows color customization via tokens or raw values.
- Example:
```json
{
  "bottomNavigation": {
    "enabled": true,
    "initialIndex": 0,
    "items": [
      { "route": "/home", "label": "Home", "icon": "house" },
      { "pageId": "courses", "title": "Courses", "icon": "doc_text" }
    ]
  }
}
```

## Component System

### Supported Components

#### Layout Components
- `column`: Vertical layout with spacing
- `row`: Horizontal layout with spacing
- `grid`: Grid layout with configurable columns
- `center`: Centers child content
- `hero`: Prominent content section
- `card`: Elevated container with styling

#### Input Components
- `textField`: Text input with validation
- `button`: Primary action button
- `textButton`: Text-only button
- `iconButton`: Icon-only button
- `switch`: Toggle switch
- `slider`: Value slider
- `searchBar`: Search input field

#### Display Components
- `text`: Text display with styling
- `icon`: Icon display
- `image`: Image display (network/asset)
- `chip`: Small labeled container
- `progressIndicator`: Loading indicator

#### Data Components
- `list`: Dynamic list with data source
- `form`: Form container with validation

#### Media Components
- `audio`: Audio player
- `video`: Video player
- `webview`: Web content display

### Component Properties

#### Common Properties
```json
{
  "type": "text",
  "id": "unique-id",
  "text": "Display text",
  "binding": "data.field",
  "permissions": ["read"],
  "style": {
    "fontSize": 16,
    "fontWeight": "bold",
    "color": "${theme.primary}",
    "backgroundColor": "${theme.surface}",
    "padding": { "all": 16 },
    "margin": { "vertical": 8 },
    "borderRadius": 8,
    "elevation": 2
  },
  "onTap": {
    "action": "navigate",
    "route": "/details"
  }
}
```

#### Data Binding
```json
{
  "type": "text",
  "binding": "title",
  "text": "Fallback text"
}
```

#### State Binding
```json
{
  "type": "text",
  "text": "${state.user.name}"
}
```

#### Theme Tokens
```json
{
  "style": {
    "color": "${theme.primary}",
    "backgroundColor": "${theme.surface}"
  }
}
```

## State Management

### State Scopes

#### Global State
```json
{
  "state": {
    "global": {
      "user": {
        "type": "object",
        "schema": "User",
        "persistence": "secure",
        "default": null
      },
      "theme": {
        "type": "string",
        "enum": ["light", "dark", "system"],
        "persistence": "local",
        "default": "system"
      }
    }
  }
}
```

#### Page State
```json
{
  "state": {
    "pages": {
      "posts": {
        "searchQuery": {
          "type": "string",
          "persistence": "session",
          "default": ""
        },
        "currentPage": {
          "type": "integer",
          "persistence": "memory",
          "default": 1
        }
      }
    }
  }
}
```

### Persistence Types
- `memory`: Session-only, lost on app restart
- `session`: Persists during app session
- `local`: Persists across app restarts
- `secure`: Encrypted persistence for sensitive data

## Actions and Events

### Action Types

#### Navigation
```json
{
  "action": "navigate",
  "route": "/details",
  "data": { "id": "123" }
}
```

#### API Calls
```json
{
  "action": "apiCall",
  "service": "posts",
  "endpoint": "create",
  "data": { "title": "New Post" },
  "onSuccess": {
    "action": "navigate",
    "route": "/posts"
  },
  "onError": {
    "action": "showError",
    "message": "Failed to create post"
  }
}
```

#### State Updates
```json
{
  "action": "updateState",
  "key": "posts.searchQuery",
  "value": "${input.value}",
  "debounceMs": 300
}
```

#### UI Actions
```json
{
  "action": "showBottomSheet",
  "content": "actionSheet",
  "data": { "itemId": "123" }
}
```

### Event Lifecycle
```json
{
  "eventsActions": {
    "onAppStart": [
      { "action": "loadState" },
      { "action": "checkAuth" }
    ],
    "onLogin": [
      { "action": "saveToken", "secure": true },
      { "action": "updateState", "key": "user", "value": "${response.user}" }
    ]
  }
}
```

## Theming System

### Theme Tokens
```json
{
  "themingAccessibility": {
    "tokens": {
      "light": {
        "primary": "#007AFF",
        "onPrimary": "#FFFFFF",
        "surface": "#FFFFFF",
        "onSurface": "#1C1B1F",
        "background": "#FEFBFF",
        "error": "#FF3B30"
      },
      "dark": {
        "primary": "#0A84FF",
        "onPrimary": "#FFFFFF",
        "surface": "#1C1C1E",
        "onSurface": "#E6E1E5",
        "background": "#000000",
        "error": "#FF453A"
      }
    }
  }
}
```

### Typography
```json
{
  "typography": {
    "largeTitle": { "fontSize": 34, "fontWeight": "bold", "lineHeight": 1.2 },
    "title1": { "fontSize": 28, "fontWeight": "bold", "lineHeight": 1.2 },
    "body": { "fontSize": 17, "fontWeight": "regular", "lineHeight": 1.4 }
  }
}
```

### Accessibility
```json
{
  "accessibility": {
    "minimumTouchTarget": 44,
    "contrastRatio": 4.5,
    "voiceOverSupport": true,
    "dynamicType": true,
    "reduceMotion": true
  }
}
```

## Validation System

### Field Validation
```json
{
  "type": "textField",
  "validation": {
    "required": true,
    "email": true,
    "minLength": 8,
    "message": "Please enter a valid email"
  }
}
```

### Validation Rules
```json
{
  "validations": {
    "rules": {
      "email": {
        "pattern": "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$",
        "message": "Please enter a valid email address"
      },
      "password": {
        "minLength": 8,
        "pattern": "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d@$!%*?&]{8,}$",
        "message": "Password must contain uppercase, lowercase, and number"
      }
    },
    "crossField": {
      "passwordConfirmation": {
        "fields": ["password", "confirmPassword"],
        "rule": "equal",
        "message": "Passwords do not match"
      }
    }
  }
}
```

## Permissions and Security

### Role-Based Access Control
```json
{
  "permissionsFlags": {
    "roles": {
      "user": {
        "permissions": ["posts.read", "profile.read"]
      },
      "admin": {
        "inherits": ["user"],
        "permissions": ["posts.create", "posts.delete", "users.manage"]
      }
    }
  }
}
```

### Feature Flags
```json
{
  "featureFlags": {
    "newDashboard": {
      "enabled": true,
      "rolloutPercentage": 50,
      "targetRoles": ["admin"]
    }
  }
}
```

### Component Permissions
```json
{
  "type": "button",
  "text": "Delete Post",
  "permissions": ["posts.delete"],
  "onTap": {
    "action": "apiCall",
    "service": "posts",
    "endpoint": "delete"
  }
}
```

## Migration System

### Schema Versioning
The framework supports automatic migration between schema versions:

```dart
// Migrate contract to current version
final migratedData = ContractMigrator.migrate(contractData);

// Validate migrated contract
final errors = ContractMigrator.validateMigratedContract(migratedData);
```

### Migration Example
```json
{
  "meta": {
    "schemaVersion": "1.0.0"
  }
}
```

Automatically migrates to:
```json
{
  "meta": {
    "schemaVersion": "2.0.0",
    "migratedAt": "2024-12-18T10:00:00Z"
  },
  "dataModels": {},
  "services": {},
  "pagesUI": {},
  "state": {},
  "eventsActions": {},
  "themingAccessibility": {},
  "assets": {},
  "validations": {},
  "permissionsFlags": {},
  "pagination": {}
}
```

## Usage Examples

### CRUD Application
```json
{
  "meta": {
    "appName": "Task Manager",
    "version": "1.0.0",
    "schemaVersion": "2.0.0"
  },
  "dataModels": {
    "Task": {
      "fields": {
        "id": { "type": "string", "primaryKey": true },
        "title": { "type": "string", "required": true },
        "completed": { "type": "boolean", "default": false },
        "createdAt": { "type": "datetime", "autoGenerate": true }
      }
    }
  },
  "services": {
    "tasks": {
      "baseUrl": "${API_BASE_URL}/tasks",
      "endpoints": {
        "list": {
          "path": "/",
          "method": "GET",
          "responseSchema": {
            "type": "object",
            "properties": {
              "data": { "type": "array", "items": { "$ref": "#/dataModels/Task" } }
            }
          }
        },
        "create": {
          "path": "/",
          "method": "POST",
          "requestSchema": {
            "type": "object",
            "properties": {
              "title": { "type": "string", "minLength": 1 }
            },
            "required": ["title"]
          }
        }
      }
    }
  },
  "pagesUI": {
    "pages": {
      "tasks": {
        "id": "tasks",
        "title": "Tasks",
        "children": [
          {
            "type": "form",
            "children": [
              {
                "type": "textField",
                "id": "title",
                "placeholder": "Enter task title",
                "validation": { "required": true }
              },
              {
                "type": "button",
                "text": "Add Task",
                "onTap": {
                  "action": "apiCall",
                  "service": "tasks",
                  "endpoint": "create",
                  "onSuccess": { "action": "refreshData", "listId": "taskList" }
                }
              }
            ]
          },
          {
            "type": "list",
            "id": "taskList",
            "dataSource": {
              "service": "tasks",
              "endpoint": "list",
              "listPath": "data"
            },
            "itemBuilder": {
              "type": "card",
              "children": [
                {
                  "type": "text",
                  "binding": "title",
                  "style": { "fontSize": 16, "fontWeight": "semibold" }
                }
              ]
            }
          }
        ]
      }
    }
  }
}
```

### Authentication Flow
```json
{
  "pagesUI": {
    "routes": {
      "/": { "pageId": "home", "auth": false },
      "/login": { "pageId": "login", "auth": false },
      "/dashboard": { "pageId": "dashboard", "auth": true }
    },
    "pages": {
      "login": {
        "id": "login",
        "title": "Sign In",
        "layout": "center",
        "children": [
          {
            "type": "form",
            "id": "loginForm",
            "onSubmit": {
              "action": "apiCall",
              "service": "auth",
              "endpoint": "login",
              "onSuccess": {
                "action": "navigate",
                "route": "/dashboard"
              }
            },
            "children": [
              {
                "type": "textField",
                "id": "email",
                "label": "Email",
                "keyboardType": "email",
                "validation": { "required": true, "email": true }
              },
              {
                "type": "textField",
                "id": "password",
                "label": "Password",
                "obscureText": true,
                "validation": { "required": true, "minLength": 8 }
              },
              {
                "type": "button",
                "text": "Sign In",
                "onTap": { "action": "submitForm", "formId": "loginForm" }
              }
            ]
          }
        ]
      }
    }
  }
}
```

## Best Practices

### Contract Design
1. **Versioning**: Always increment schema version for breaking changes
2. **Validation**: Define comprehensive validation rules
3. **Permissions**: Use granular permissions for security
4. **Theming**: Use semantic color names, not hex values
5. **State**: Minimize global state, prefer page-scoped state

### Performance
1. **Caching**: Enable caching for read-heavy endpoints
2. **Pagination**: Use pagination for large data sets
3. **Lazy Loading**: Enable lazy loading for images and media
4. **Debouncing**: Use debouncing for search and input actions

### Security
1. **Authentication**: Protect sensitive routes with auth requirements
2. **Permissions**: Check permissions at component level
3. **Validation**: Validate all user inputs
4. **Secrets**: Never embed secrets in the contract

### Accessibility
1. **Touch Targets**: Ensure minimum 44pt touch targets
2. **Contrast**: Maintain 4.5:1 contrast ratio
3. **Labels**: Provide semantic labels for screen readers
4. **Dynamic Type**: Support dynamic type scaling

## Testing Strategy

### Contract Testing
```dart
test('contract validation', () {
  final contract = CanonicalContract.fromJson(contractData);
  expect(contract.meta.appName, isNotEmpty);
  expect(contract.pagesUI.pages, isNotEmpty);
});
```

### API Testing
```dart
test('API endpoint validation', () async {
  final response = await apiService.call(
    service: 'auth',
    endpoint: 'login',
    data: {'email': 'test@example.com', 'password': 'password123'},
  );
  expect(response.data['token'], isNotNull);
});
```

### UI Testing
```dart
testWidgets('login form validation', (tester) async {
  await tester.pumpWidget(MyApp());
  await tester.enterText(find.byType(CupertinoTextField).first, 'invalid-email');
  await tester.tap(find.text('Sign In'));
  await tester.pump();
  expect(find.text('Please enter a valid email'), findsOneWidget);
});
```

## Deployment

### Environment Configuration
```json
{
  "services": {
    "api": {
      "baseUrl": "${API_BASE_URL}",
      "endpoints": {
        "health": {
          "path": "/health",
          "method": "GET"
        }
      }
    }
  }
}
```

### CI/CD Integration
1. **Contract Validation**: Validate contract schema in CI
2. **Migration Testing**: Test migrations between versions
3. **API Contract Testing**: Verify API endpoints match contract
4. **UI Testing**: Test generated UI components

### Monitoring
1. **Error Tracking**: Monitor API and UI errors
2. **Performance**: Track API response times and UI render times
3. **Usage Analytics**: Track feature usage and user flows
4. **Crash Reporting**: Monitor app crashes and exceptions

## Troubleshooting

### Common Issues

#### Contract Loading Errors
- Verify JSON syntax is valid
- Check asset path in pubspec.yaml
- Ensure all required sections are present

#### API Errors
- Verify service configuration
- Check authentication tokens
- Validate request/response schemas

#### UI Rendering Issues
- Check component type spelling
- Verify theme token references
- Ensure data binding paths are correct

#### State Management Issues
- Check state scope configuration
- Verify persistence settings
- Ensure state keys are unique

### Debug Tools
1. **Contract Validator**: Validate contract structure
2. **API Inspector**: Monitor API calls and responses
3. **State Inspector**: View current state values
4. **Theme Inspector**: Preview theme tokens

## Conclusion

This canonical JSON-driven framework provides a comprehensive solution for building scalable, maintainable applications where the JSON contract serves as the single source of truth. The framework ensures type safety, supports schema evolution, and provides a rich set of features for modern app development while maintaining Apple's design guidelines through Cupertino widgets.