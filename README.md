# Canonical JSON-Driven Framework

A production-grade Flutter framework where a single canonical JSON contract serves as the source of truth for data models, API contracts, UI rendering, business logic, state management, and deployment configuration.

## 🚀 Features

### Core Framework

- **Single Source of Truth**: One JSON contract defines the entire application
- **Type Safety**: Strong typing throughout the stack with automatic validation
- **Schema Evolution**: Versioned migrations ensure backward compatibility
- **Code Generation**: All models, services, and UI generated from contract

### UI System

- **Dynamic Rendering**: Components rendered from JSON configuration
- **Theme System**: Comprehensive theming with light/dark mode support
- **Accessibility**: Built-in accessibility features following Apple guidelines
- **Cupertino Widgets**: Native iOS design language throughout

### Data & Services

- **API Contracts**: Service definitions with request/response validation
- **Caching**: Intelligent caching with TTL and invalidation
- **Retry Policies**: Configurable retry logic with exponential backoff
- **Error Handling**: Comprehensive error handling and fallbacks

### State Management

- **Scoped State**: Global, page, session, and memory state scopes
- **Persistence**: Automatic persistence based on configuration
- **Reactive Updates**: Real-time UI updates with ChangeNotifier
- **Data Binding**: Seamless data binding between state and UI

### Security & Permissions

- **Role-Based Access**: Granular permission system
- **Feature Flags**: Dynamic feature rollouts
- **Authentication**: Built-in auth flow support
- **Validation**: Comprehensive input validation

## 📁 Project Structure

```
demo_json_parser/
├── assets/
│   ├── canonical_contract.json    # Main contract file
│   └── advanced_config.json       # Legacy config (for migration)
├── lib/
│   ├── models/
│   │   └── enhanced_config_models.dart    # Type-safe contract models
│   ├── services/
│   │   └── enhanced_api_service.dart      # API service with contracts
│   ├── widgets/
│   │   ├── enhanced_component_factory.dart # Dynamic UI components
│   │   └── enhanced_page_builder.dart     # Page rendering
│   ├── state/
│   │   └── enhanced_state_manager.dart    # State management
│   ├── validation/
│   │   └── enhanced_validator.dart        # Input validation
│   ├── permissions/
│   │   └── permission_manager.dart        # Access control
│   ├── events/
│   │   └── enhanced_action_dispatcher.dart # Action handling
│   ├── migration/
│   │   └── contract_migrator.dart         # Schema migrations
│   ├── enhanced_main.dart                 # Enhanced app entry point
│   └── main.dart                          # Original demo app
└── docs
```

## 🚦 Quick Start

### 1. Run the Enhanced Framework

```bash
# Clone the repository
git clone <repository-url>
cd demo_json_parser

# Install dependencies
flutter pub get

# Run the enhanced app
flutter run lib/enhanced_main.dart
```

### 2. Run the Original Demo

```bash
# Run the original demo
flutter run
```

### 3. Explore the Contract

Edit `assets/canonical_contract.json` to see real-time changes in the app.

## 📖 Documentation

- **[Canonical Framework Guide](docs/flutter-canonical_framework_guide.md)**: Comprehensive documentation
- **[System Overview](docs/flutter-system_overview.md)**: Original system documentation
- **[Contract Validator Usage](docs/contract_validator_usage.md)**: How to validate contracts and use the CLI

## 🔌 Backend Integration

- Base URL: `http://localhost:8081`
- Canonical fetch flow:
  - Primary: `GET /contracts/canonical` (public)
  - Fallback: `GET /contracts/public/canonical` (public alias) when the primary returns `401` or `404` due to route collisions.
  - Final fallback: load `assets/canonical_contract.json` when the backend is unavailable.
- Emulator run (iOS):
  - Launch the iOS Simulator (`open -a Simulator`) and run `flutter run`.
  - Ensure your backend is running on `8081` to serve the canonical contract.

## 🔧 Configuration Examples

### Simple Page

```json
{
  "pagesUI": {
    "pages": {
      "home": {
        "id": "home",
        "title": "Welcome",
        "children": [
          {
            "type": "text",
            "text": "Hello, World!",
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

### API Service

```json
{
  "services": {
    "posts": {
      "baseUrl": "https://jsonplaceholder.typicode.com",
      "endpoints": {
        "list": {
          "path": "/posts",
          "method": "GET",
          "caching": { "enabled": true, "ttlSeconds": 300 }
        }
      }
    }
  }
}
```

### Dynamic List

```json
{
  "type": "list",
  "dataSource": {
    "service": "posts",
    "endpoint": "list",
    "listPath": "data"
  },
  "itemBuilder": {
    "type": "card",
    "children": [
      {
        "type": "text",
        "binding": "title",
        "style": { "fontWeight": "bold" }
      },
      {
        "type": "text",
        "binding": "body",
        "style": { "color": "${theme.onSurfaceVariant}" }
      }
    ]
  }
}
```

## 🎨 Theming

The framework includes a comprehensive theming system:

```json
{
  "themingAccessibility": {
    "tokens": {
      "light": {
        "primary": "#007AFF",
        "surface": "#FFFFFF",
        "background": "#F2F2F7"
      },
      "dark": {
        "primary": "#0A84FF",
        "surface": "#1C1C1E",
        "background": "#000000"
      }
    }
  }
}
```

## 🔐 Security Features

- **Role-based permissions**: Control component visibility
- **Input validation**: Comprehensive validation rules
- **Secure state**: Encrypted persistence for sensitive data
- **API validation**: Request/response schema validation

## 🧪 Testing

The framework supports comprehensive testing:

```dart
// Contract testing
test('contract validation', () {
  final contract = CanonicalContract.fromJson(contractData);
  expect(contract.meta.appName, isNotEmpty);
});

// API testing
test('API endpoint', () async {
  final response = await apiService.call(
    service: 'auth',
    endpoint: 'login',
    data: testCredentials,
  );
  expect(response.data['token'], isNotNull);
});
```

## 🔄 Migration System

Automatic schema migration between versions:

```dart
// Migrate contract to current version
final migratedData = ContractMigrator.migrate(contractData);

// Validate migrated contract
final errors = ContractMigrator.validateMigratedContract(migratedData);
```

## Legacy Demo (Original Implementation)

The original JSON-driven UI demo is still available:

- Run with: `flutter run`
- Edit UI in `assets/config.json` and hot reload
- Features bottom navigation with Home, Feed, and Media tabs
- Demonstrates remote data loading from JSONPlaceholder API

---

**Note**: This framework demonstrates a production-grade approach to JSON-driven application development. The canonical contract serves as the single source of truth, enabling rapid development, easy maintenance, and seamless evolution of complex applications.

## 💾 State Persistence

- Global and page state can be persisted automatically based on the contract.
- Add `persistence` on state fields in `assets/canonical_contract.json`:

```json
{
  "state": {
    "global": {
      "theme": {
        "type": "string",
        "default": "system",
        "persistence": "local"
      },
      "authToken": { "type": "string", "persistence": "secure" }
    },
    "pages": {
      "profile": {
        "showEmail": {
          "type": "boolean",
          "default": true,
          "persistence": "local"
        },
        "volume": { "type": "double", "default": 0.5 }
      }
    }
  }
}
```

- Persistence policy values:

  - `local` / `device`: stored via `shared_preferences`.
  - `secure`: stored via `flutter_secure_storage` (encrypted where supported).
  - `session` / `memory` / omitted: not persisted; lives for app session only.

- Behavior:
  - On app start, state hydrates from storage before defaults are applied.
  - Writes to state automatically sync to the configured storage.
  - Clearing global or page state also clears persisted values.

No changes are required in UI components; they bind state as usual.

## ✅ Validation

- Field-level validation keys: `required`, `email`, `minLength`, `maxLength`, `pattern`, `message`
- Validates on change and shows inline errors with themed color
- Example:

```json
{
  "type": "textField",
  "label": "Email",
  "keyboardType": "email",
  "validation": {
    "required": true,
    "email": true,
    "message": "Please enter a valid email"
  }
}
```

## 🛠️ Development

- Run `dart analyze` to ensure zero lints
- Run `flutter run` (iOS, Android, or Web) to validate UI
