#!/bin/bash

# Family Game Score Tracker - Project Setup Script (Cross-platform)
# Works on Windows (Git Bash/WSL), macOS, and Linux

PROJECT_NAME="family_score_tracker"
echo "🎯 Setting up $PROJECT_NAME project structure..."

# Detect OS
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OS" == "Windows_NT" ]]; then
    IS_WINDOWS=true
    echo "🪟 Detected Windows environment"
else
    IS_WINDOWS=false
    echo "🐧 Detected Unix-like environment"
fi

# Create root directory structure
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create main directories (works cross-platform)
mkdir -p apps/mobile apps/web
mkdir -p packages/core_models packages/data_access packages/features packages/ui_kit packages/analytics
mkdir -p supabase/migrations supabase/policies supabase/functions
mkdir -p tools/scripts tools/mason_bricks

echo "📁 Created directory structure"

# Root configuration files
cat > pubspec.yaml << 'EOF'
name: family_score_tracker
description: A cross-platform score tracking app for families
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dev_dependencies:
  melos: ^3.2.0
  very_good_analysis: ^5.1.0

dependency_overrides:
  # Add local package overrides here when needed
EOF

cat > melos.yaml << 'EOF'
name: family_score_tracker
repository: https://github.com/your-org/family-score-tracker

packages:
  - apps/**
  - packages/**

command:
  version:
    releaseUrl: true
    workspaceChangelog: true
  
  bootstrap:
    runPubGetInParallel: false
    
scripts:
  analyze:
    run: flutter analyze
    exec:
      concurrency: 1
      
  test:
    run: flutter test --coverage
    exec:
      concurrency: 1
      
  format:
    run: dart format --set-exit-if-changed .
    exec:
      concurrency: 1

  build:web:
    run: flutter build web --release
    exec:
      concurrency: 1
    packageFilters:
      dirExists: web
EOF

cat > analysis_options.yaml << 'EOF'
include: package:very_good_analysis/analysis_options.yaml

analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "**/*.config.dart"
    - "build/**"
    - "lib/generated/**"

linter:
  rules:
    public_member_api_docs: false
    lines_longer_than_80_chars: false
EOF

cat > .gitignore << 'EOF'
# Miscellaneous
*.class
*.log
*.pyc
*.swp
.DS_Store
.atom/
.buildlog/
.history
.svn/
migrate_working_dir/

# IntelliJ related
*.iml
*.ipr
*.iws
.idea/

# VSCode related
.vscode/

# Flutter/Dart/Pub related
**/doc/api/
**/ios/Flutter/.last_build_id
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
/build/

# Symbolication related
app.*.symbols

# Obfuscation related
app.*.map.json

# Android Studio will place build artifacts here
/android/app/debug
/android/app/profile
/android/app/release

# Environment variables
.env
.env.local
.env.development
.env.production

# Supabase
supabase/.branches
supabase/.temp
supabase/config.toml

# Coverage
coverage/
*.lcov

# Generated files
**/*.g.dart
**/*.freezed.dart
**/*.config.dart
EOF

cat > README.md << 'EOF'
# Family Game Score Tracker

A cross-platform score tracking app for families and friends with real-time sync across Web, iOS, and Android.

## Quick Start

### Prerequisites
- Flutter SDK 3.x
- Dart 3.x
- Supabase CLI
- Melos (optional but recommended)

### Setup
```bash
# Install melos globally
dart pub global activate melos

# Bootstrap the monorepo
melos bootstrap

# Start Supabase locally
supabase start

# Run the mobile app
cd apps/mobile
flutter run
```

## Project Structure
```
family-score/
├── apps/
│   ├── mobile/                # Flutter app for iOS/Android/Web
│   └── web/                   # Optional separate web shell
├── packages/
│   ├── core_models/           # DTOs, json_serializable
│   ├── data_access/           # Supabase client, repositories
│   ├── features/              # Feature modules
│   ├── ui_kit/                # Shared widgets, theming
│   └── analytics/             # Telemetry abstraction
├── supabase/
│   ├── migrations/            # SQL migrations
│   ├── policies/              # RLS policies
│   └── functions/             # Edge functions
└── tools/
    ├── scripts/               # CI scripts, codegen
    └── mason_bricks/          # App scaffolds
```

## Development Commands
```bash
# Analyze all packages
melos analyze

# Test all packages
melos test

# Format code
melos format

# Build web version
melos build:web
```

For detailed setup instructions, see the full README in the architecture document.
EOF

echo "🔧 Setting up core packages..."

# Core Models Package
cat > packages/core_models/pubspec.yaml << 'EOF'
name: core_models
description: Core data models and DTOs for the Family Score Tracker
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  freezed_annotation: ^2.4.1
  json_annotation: ^4.8.1
  equatable: ^2.0.5

dev_dependencies:
  build_runner: ^2.4.8
  freezed: ^2.4.7
  json_serializable: ^6.7.1
  test: ^1.24.0
EOF

mkdir -p packages/core_models/lib/src/{models,enums}
cat > packages/core_models/lib/core_models.dart << 'EOF'
/// Core data models and DTOs for the Family Score Tracker
library core_models;

export 'src/models/models.dart';
export 'src/enums/enums.dart';
EOF

cat > packages/core_models/lib/src/models/models.dart << 'EOF'
export 'profile.dart';
export 'family.dart';
export 'game.dart';
export 'session.dart';
export 'achievement.dart';
EOF

cat > packages/core_models/lib/src/enums/enums.dart << 'EOF'
export 'scoring_type.dart';
export 'family_role.dart';
export 'session_status.dart';
EOF

# Data Access Package
cat > packages/data_access/pubspec.yaml << 'EOF'
name: data_access
description: Data access layer with Supabase integration and offline sync
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  core_models:
    path: ../core_models
  supabase_flutter: ^2.0.0
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  connectivity_plus: ^5.0.0
  rxdart: ^0.27.7

dev_dependencies:
  build_runner: ^2.4.8
  isar_generator: ^3.1.0
  test: ^1.24.0
EOF

mkdir -p packages/data_access/lib/src/{repositories,sync,local,remote}
cat > packages/data_access/lib/data_access.dart << 'EOF'
/// Data access layer with Supabase integration and offline sync
library data_access;

export 'src/repositories/repositories.dart';
export 'src/sync/sync.dart';
export 'src/local/local.dart';
export 'src/remote/remote.dart';
EOF

# Features Package
cat > packages/features/pubspec.yaml << 'EOF'
name: features
description: Feature modules for the Family Score Tracker
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  core_models:
    path: ../core_models
  data_access:
    path: ../data_access
  ui_kit:
    path: ../ui_kit
  flutter_riverpod: ^2.4.9
  go_router: ^12.1.3
  image_picker: ^1.0.4
  share_plus: ^7.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
EOF

mkdir -p packages/features/lib/src/{auth,families,games,sessions,stats,achievements}
cat > packages/features/lib/features.dart << 'EOF'
/// Feature modules for the Family Score Tracker
library features;

export 'src/auth/auth.dart';
export 'src/families/families.dart';
export 'src/games/games.dart';
export 'src/sessions/sessions.dart';
export 'src/stats/stats.dart';
export 'src/achievements/achievements.dart';
EOF

# UI Kit Package
cat > packages/ui_kit/pubspec.yaml << 'EOF'
name: ui_kit
description: Shared UI components and theming
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0
  flutter_animate: ^4.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  golden_toolkit: ^0.15.0
EOF

mkdir -p packages/ui_kit/lib/src/{theme,widgets,utils}
cat > packages/ui_kit/lib/ui_kit.dart << 'EOF'
/// Shared UI components and theming
library ui_kit;

export 'src/theme/theme.dart';
export 'src/widgets/widgets.dart';
export 'src/utils/utils.dart';
EOF

# Analytics Package
cat > packages/analytics/pubspec.yaml << 'EOF'
name: analytics
description: Analytics and telemetry abstraction layer
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  test: ^1.24.0
EOF

mkdir -p packages/analytics/lib/src
cat > packages/analytics/lib/analytics.dart << 'EOF'
/// Analytics and telemetry abstraction layer
library analytics;

export 'src/analytics_service.dart';
export 'src/analytics_event.dart';
EOF

echo "📱 Setting up mobile app..."

# Mobile App
cat > apps/mobile/pubspec.yaml << 'EOF'
name: family_score_mobile
description: Family Game Score Tracker - Mobile App
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: ">=3.16.0"

dependencies:
  flutter:
    sdk: flutter
  
  # Local packages
  core_models:
    path: ../../packages/core_models
  data_access:
    path: ../../packages/data_access
  features:
    path: ../../packages/features
  ui_kit:
    path: ../../packages/ui_kit
  analytics:
    path: ../../packages/analytics
  
  # External dependencies
  flutter_riverpod: ^2.4.9
  go_router: ^12.1.3
  supabase_flutter: ^2.0.0
  shared_preferences: ^2.2.2
  flutter_native_splash: ^2.3.8
  flutter_launcher_icons: ^0.13.1
  url_launcher: ^6.2.1
  package_info_plus: ^4.2.0
  device_info_plus: ^9.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.8
  mocktail: ^1.0.0
  integration_test:
    sdk: flutter

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
  
flutter_launcher_icons:
  android: "ic_launcher"
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_background: "#FF6B35"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"

flutter_native_splash:
  color: "#FF6B35"
  image: "assets/icons/splash_icon.png"
  android_12:
    color: "#FF6B35"
    image: "assets/icons/splash_icon.png"
EOF

mkdir -p apps/mobile/lib/src/{app,config,router}
mkdir -p apps/mobile/assets/{images,icons}
mkdir -p apps/mobile/android/app/src/main/res/values
mkdir -p apps/mobile/ios/Runner

cat > apps/mobile/lib/main.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/app/app.dart';
import 'src/config/config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  
  runApp(
    const ProviderScope(
      child: FamilyScoreApp(),
    ),
  );
}
EOF

cat > apps/mobile/lib/src/app/app.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit/ui_kit.dart';
import '../router/app_router.dart';

class FamilyScoreApp extends ConsumerWidget {
  const FamilyScoreApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'Family Score Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
EOF

echo "🗄️ Setting up Supabase configuration..."

# Supabase configuration
cat > supabase/config.toml << 'EOF'
# A string used to distinguish different Supabase projects on the same machine.
project_id = "family-score-tracker"

[api]
enabled = true
port = 54321
schemas = ["public", "graphql_public"]
extra_search_path = ["public", "extensions"]
max_rows = 1000

[db]
port = 54322
shadow_port = 54320
major_version = 15

[studio]
enabled = true
port = 54323
api_url = "http://127.0.0.1:54321"

[inbucket]
enabled = true
port = 54324
smtp_port = 54325
pop3_port = 54326

[storage]
enabled = true
file_size_limit = "50MiB"
image_transformation = {enabled = true}

[auth]
enabled = true
site_url = "http://localhost:3000"
additional_redirect_urls = ["https://localhost:3000"]
jwt_expiry = 3600
enable_signup = true

[auth.email]
enable_signup = true
double_confirm_changes = true
enable_confirmations = false

[auth.sms]
enable_signup = true
enable_confirmations = false
test_otp = "123456"

[realtime]
enabled = true
ip_version = "ipv4"
EOF

# Initial migration
cat > supabase/migrations/001_initial_schema.sql << 'EOF'
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table
CREATE TABLE profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create families table
CREATE TABLE families (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    created_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create family_members table
CREATE TABLE family_members (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member', 'child')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(family_id, profile_id)
);

-- Create games table
CREATE TABLE games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    scoring_type TEXT NOT NULL DEFAULT 'points' CHECK (scoring_type IN ('points', 'rounds', 'time', 'placement')),
    default_rules JSONB DEFAULT '{}',
    is_shared BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create game_variants table
CREATE TABLE game_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    rules_delta JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create game_fields table
CREATE TABLE game_fields (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    key TEXT NOT NULL,
    label TEXT NOT NULL,
    field_type TEXT NOT NULL CHECK (field_type IN ('number', 'text', 'boolean', 'select')),
    options JSONB DEFAULT '{}',
    required BOOLEAN DEFAULT false,
    sort_order INTEGER DEFAULT 0
);

-- Create sessions table
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_id UUID NOT NULL REFERENCES families(id) ON DELETE CASCADE,
    game_id UUID NOT NULL REFERENCES games(id),
    title TEXT,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    created_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create session_players table
CREATE TABLE session_players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id),
    seat_order INTEGER NOT NULL DEFAULT 0,
    team TEXT,
    final_score INTEGER DEFAULT 0,
    UNIQUE(session_id, profile_id)
);

-- Create score_events table
CREATE TABLE score_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    profile_id UUID NOT NULL REFERENCES profiles(id),
    delta INTEGER NOT NULL,
    reason TEXT,
    round_number INTEGER,
    event_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID NOT NULL REFERENCES profiles(id)
);

-- Create achievements table
CREATE TABLE achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    criteria_sql TEXT,
    icon TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create earned_achievements table
CREATE TABLE earned_achievements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id),
    achievement_id UUID NOT NULL REFERENCES achievements(id),
    session_id UUID REFERENCES sessions(id),
    awarded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(profile_id, achievement_id)
);

-- Create attachments table
CREATE TABLE attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    mime_type TEXT,
    file_size INTEGER,
    metadata JSONB DEFAULT '{}',
    uploaded_by UUID NOT NULL REFERENCES profiles(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_family_members_family_id ON family_members(family_id);
CREATE INDEX idx_family_members_profile_id ON family_members(profile_id);
CREATE INDEX idx_games_family_id ON games(family_id);
CREATE INDEX idx_sessions_family_id ON sessions(family_id);
CREATE INDEX idx_sessions_game_id ON sessions(game_id);
CREATE INDEX idx_session_players_session_id ON session_players(session_id);
CREATE INDEX idx_score_events_session_id ON score_events(session_id);
CREATE INDEX idx_score_events_profile_id ON score_events(profile_id);
CREATE INDEX idx_earned_achievements_profile_id ON earned_achievements(profile_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_families_updated_at BEFORE UPDATE ON families
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_games_updated_at BEFORE UPDATE ON games
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sessions_updated_at BEFORE UPDATE ON sessions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EOF

echo "🔒 Setting up RLS policies..."

# RLS Policies
cat > supabase/policies/001_enable_rls.sql << 'EOF'
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE score_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE earned_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;
EOF

cat > supabase/policies/002_profiles_policies.sql << 'EOF'
-- Profiles policies
CREATE POLICY "Users can view all profiles" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);
EOF

echo "🚀 Setting up CI/CD configuration..."

# GitHub Actions
mkdir -p .github/workflows
cat > .github/workflows/ci.yml << 'EOF'
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          cache: true
      
      - name: Get dependencies
        run: |
          dart pub global activate melos
          melos bootstrap
      
      - name: Analyze
        run: melos analyze
      
      - name: Format check
        run: melos format --set-exit-if-changed
      
      - name: Test
        run: melos test

  build-web:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          cache: true
      
      - name: Get dependencies
        run: |
          dart pub global activate melos
          melos bootstrap
      
      - name: Build web
        run: |
          cd apps/mobile
          flutter build web --release
      
      - name: Upload web artifacts
        uses: actions/upload-artifact@v3
        with:
          name: web-build
          path: apps/mobile/build/web/
EOF

echo "🛠️ Setting up development tools..."

# Development scripts
mkdir -p tools/scripts
# Create setup script for Unix/Linux/macOS
cat > tools/scripts/setup_dev.sh << 'EOF'
#!/bin/bash
set -e

echo "🔧 Setting up development environment..."

# Check prerequisites
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    exit 1
fi

if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI is not installed. Installing..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install supabase/tap/supabase
    else
        echo "Please install Supabase CLI manually: https://supabase.com/docs/guides/cli"
        exit 1
    fi
fi

# Install melos
dart pub global activate melos

# Bootstrap packages
echo "📦 Bootstrapping packages..."
melos bootstrap

# Generate code
echo "🏗️ Generating code..."
melos run build_runner

# Setup Supabase
echo "🗄️ Setting up Supabase..."
if [ ! -f "supabase/config.toml" ]; then
    supabase init
fi

supabase start
supabase db push

echo "✅ Development environment ready!"
echo ""
echo "Next steps:"
echo "1. Copy .env.example to .env and fill in your values"
echo "2. Run 'cd apps/mobile && flutter run' to start the app"
EOF

if [ "$IS_WINDOWS" = false ]; then
    chmod +x tools/scripts/setup_dev.sh
fi

# Create Windows batch script
cat > tools/scripts/setup_dev.bat << 'EOF'
@echo off
echo 🔧 Setting up development environment for Windows...

REM Check prerequisites
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter is not installed. Please install Flutter first.
    echo Download from: https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

where supabase >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Supabase CLI is not installed.
    echo Please install from: https://supabase.com/docs/guides/cli
    echo Or use Scoop: scoop install supabase
    pause
    exit /b 1
)

REM Install melos
dart pub global activate melos

REM Bootstrap packages
echo 📦 Bootstrapping packages...
melos bootstrap

REM Generate code
echo 🏗️ Generating code...
melos run build_runner

REM Setup Supabase
echo 🗄️ Setting up Supabase...
if not exist "supabase\config.toml" (
    supabase init
)

supabase start
supabase db push

echo ✅ Development environment ready!
echo.
echo Next steps:
echo 1. Copy .env.example to .env and fill in your values
echo 2. Run 'cd apps/mobile && flutter run' to start the app
pause
EOF

cat > tools/scripts/codegen.sh << 'EOF'
#!/bin/bash
set -e

echo "🏗️ Running code generation..."

# Run build_runner for all packages that need it
melos exec --depends-on="build_runner" -- dart run build_runner build --delete-conflicting-outputs

echo "✅ Code generation complete!"
EOF

if [ "$IS_WINDOWS" = false ]; then
    chmod +x tools/scripts/codegen.sh
fi

# Windows batch version of codegen
cat > tools/scripts/codegen.bat << 'EOF'
@echo off
echo 🏗️ Running code generation...

REM Run build_runner for all packages that need it
melos exec --depends-on="build_runner" -- dart run build_runner build --delete-conflicting-outputs

echo ✅ Code generation complete!
pause
EOF

# Environment template
cat > .env.example << 'EOF'
# Supabase Configuration
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Optional: Analytics
SENTRY_DSN=your_sentry_dsn_here

# Optional: Development
SUPABASE_LOCAL_URL=http://localhost:54321
SUPABASE_LOCAL_ANON_KEY=your_local_anon_key_here
EOF

echo "✅ Project structure created successfully!"
echo ""
echo "📁 Created the following structure:"
echo "   ├── apps/mobile/           # Flutter app"
echo "   ├── packages/              # Shared packages"
echo "   │   ├── core_models/       # Data models"
echo "   │   ├── data_access/       # Repositories & sync"
echo "   │   ├── features/          # Feature modules"
echo "   │   ├── ui_kit/            # UI components"
echo "   │   └── analytics/         # Analytics layer"
echo "   ├── supabase/              # Database & backend"
echo "   ├── tools/                 # Development tools"
echo "   └── .github/workflows/     # CI/CD"
echo ""
echo "🚀 Next steps:"
echo "1. cd $PROJECT_NAME"
if [ "$IS_WINDOWS" = true ]; then
    echo "2. Run setup: .\\tools\\scripts\\setup_dev.bat"
else
    echo "2. Run setup: ./tools/scripts/setup_dev.sh"
fi
echo "3. Copy .env.example to .env and configure"
echo "4. Start developing: cd apps/mobile && flutter run"
echo ""
if [ "$IS_WINDOWS" = true ]; then
    echo "💡 Windows users can also use:"
    echo "   - Git Bash for Unix commands"
    echo "   - Windows Subsystem for Linux (WSL)"
    echo "   - Use .bat files for Windows-native experience"
    echo ""
fi
echo "📚 For more details, check the README.md file."
