# Family Game Score Tracker
## Complete Project Specification v1.0

A cross-platform score tracking app for families and friends with real-time sync across **Web**, **iOS**, and **Android**. Supports multiple family profiles, rich match history, custom game templates, offline mode, achievements, and deep links/NFC to jump straight into a game.

---

## Project Overview

### Goals
- **Zero-friction scoring** during play, beautiful stats after
- **One codebase** across Web/iOS/Android using Flutter
- **Multiple families/households** with shared libraries of players and games
- **Extensible game templates** so new games can be added without code changes
- **Works offline**, syncs when online
- **Privacy by default** with row-level security

### Key Features
- Create/join **Family Profiles** with invite links/QR codes
- Game Library with templates (Uno, Catan, Carcassonne) + custom rules
- **Live Match Sessions** with drag-to-order players and quick scoring
- **Rich History** per family, game, and player with date/season filters
- **Per-match notes & photos**
- **Seasonal leaderboards** (monthly/annual/custom)
- **Achievements & Badges** system
- **Head-to-head rivalries** tracking
- **Deep links/NFC** to launch specific games or resume sessions
- **PWA** support for installation

---

## Architecture Overview

```
┌─────────────────────────────────────┐
│        Flutter App                  │
│    (Web/iOS/Android)                │
│                                     │
│  ┌─────────────┐  ┌───────────────┐ │
│  │ UI Widgets  │  │ State Mgmt    │ │
│  │             │  │ (Riverpod)    │ │
│  └─────────────┘  └───────────────┘ │
│                                     │
│  ┌─────────────┐  ┌───────────────┐ │
│  │ Local DB    │  │ Sync Engine   │ │
│  │ (Isar)      │  │               │ │
│  └─────────────┘  └───────────────┘ │
└─────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────┐
│            Supabase                 │
│                                     │
│  ┌─────────────┐  ┌───────────────┐ │
│  │ Auth        │  │ Postgres DB   │ │
│  │             │  │ + RLS         │ │
│  └─────────────┘  └───────────────┘ │
│                                     │
│  ┌─────────────┐  ┌───────────────┐ │
│  │ Realtime    │  │ Object        │ │
│  │ Channels    │  │ Storage       │ │
│  └─────────────┘  └───────────────┘ │
│                                     │
│  ┌─────────────┐                    │
│  │ Edge        │                    │
│  │ Functions   │                    │
│  └─────────────┘                    │
└─────────────────────────────────────┘
```

**Architecture Rationale:**
- **Flutter**: Single codebase, polished animations, PWA support
- **Supabase**: Postgres + Realtime + Storage + RLS, SQL flexibility
- **Isar**: Local database for offline-first experience
- **Riverpod**: Reactive state management with dependency injection

---

## Tech Stack

### Frontend
- **Flutter 3.x** with Dart 3.x
- **Riverpod** for state management
- **GoRouter** for navigation and deep linking
- **Isar** for local database (offline storage)
- **Supabase Flutter SDK** for backend integration
- **image_picker** for photo attachments
- **share_plus** for match sharing
- **nfc_manager** for NFC functionality (mobile only)

### Backend
- **Supabase** managed cloud platform
  - **PostgreSQL** with Row Level Security (RLS)
  - **Realtime** for live synchronization
  - **Authentication** with social logins
  - **Object Storage** for photos
  - **Edge Functions** for server-side logic

### Development Tools
- **Melos** for monorepo management
- **very_good_analysis** for linting
- **Mason** for code scaffolding
- **Fastlane** for release automation
- **GitHub Actions** for CI/CD

---

## Monorepo Structure

```
family-score-tracker/
├── apps/
│   └── mobile/                 # Main Flutter app (targets all platforms)
│       ├── lib/
│       │   ├── main.dart
│       │   ├── app/           # App-level configuration
│       │   ├── features/      # Feature modules
│       │   └── shared/        # Shared utilities
│       ├── web/               # Web-specific assets
│       ├── ios/               # iOS configuration
│       └── android/           # Android configuration
├── packages/
│   ├── core_models/           # Data models and DTOs
│   ├── data_access/           # Repository pattern, Supabase client
│   ├── ui_kit/                # Shared widgets and theming
│   ├── features/
│   │   ├── auth/              # Authentication feature
│   │   ├── families/          # Family management
│   │   ├── games/             # Game templates and variants
│   │   ├── sessions/          # Live scoring sessions
│   │   ├── history/           # Match history and stats
│   │   └── achievements/      # Badge system
│   └── analytics/             # Telemetry abstraction
├── supabase/
│   ├── migrations/            # Database schema migrations
│   ├── policies/              # Row Level Security policies
│   └── functions/             # Edge functions
├── tools/
│   ├── scripts/               # Development and CI scripts
│   └── mason_bricks/          # Code generation templates
├── melos.yaml                 # Monorepo configuration
└── README.md
```

---

## Database Schema

### Core Tables

```sql
-- User profiles (extends Supabase auth.users)
CREATE TABLE profiles (
    id UUID REFERENCES auth.users PRIMARY KEY,
    display_name TEXT NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Family/household groups
CREATE TABLE families (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    invite_code TEXT UNIQUE NOT NULL DEFAULT encode(gen_random_bytes(6), 'base64'),
    created_by UUID REFERENCES profiles(id) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Family membership with roles
CREATE TABLE family_members (
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member', 'child')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (family_id, profile_id)
);

-- Game definitions with extensible scoring
CREATE TABLE games (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    scoring_type TEXT NOT NULL CHECK (scoring_type IN ('points', 'rounds', 'custom')),
    min_players INTEGER DEFAULT 2,
    max_players INTEGER DEFAULT 8,
    default_rules JSONB DEFAULT '{}',
    is_template BOOLEAN DEFAULT FALSE,
    is_shared BOOLEAN DEFAULT FALSE,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Extensible game configuration fields
CREATE TABLE game_fields (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    field_key TEXT NOT NULL,
    label TEXT NOT NULL,
    field_type TEXT NOT NULL CHECK (field_type IN ('number', 'text', 'boolean', 'select')),
    options JSONB, -- For select fields
    required BOOLEAN DEFAULT FALSE,
    sort_order INTEGER DEFAULT 0,
    UNIQUE(game_id, field_key)
);

-- Game variants (rule modifications)
CREATE TABLE game_variants (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    rules_delta JSONB DEFAULT '{}',
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Match sessions
CREATE TABLE sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    family_id UUID REFERENCES families(id) ON DELETE CASCADE,
    game_id UUID REFERENCES games(id),
    variant_id UUID REFERENCES game_variants(id),
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    notes TEXT,
    created_by UUID REFERENCES profiles(id),
    session_data JSONB DEFAULT '{}' -- Game-specific data
);

-- Players in a session
CREATE TABLE session_players (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES profiles(id),
    seat_order INTEGER NOT NULL,
    team TEXT,
    final_score INTEGER DEFAULT 0,
    placement INTEGER, -- Final ranking (1st, 2nd, etc.)
    player_data JSONB DEFAULT '{}' -- Player-specific game data
);

-- Individual scoring events (append-only log)
CREATE TABLE score_events (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    player_id UUID REFERENCES session_players(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('score', 'bonus', 'penalty', 'round')),
    delta INTEGER NOT NULL,
    reason TEXT,
    round_number INTEGER,
    event_data JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES profiles(id)
);

-- Achievement definitions
CREATE TABLE achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    key TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    criteria_sql TEXT NOT NULL, -- SQL query to check achievement
    points INTEGER DEFAULT 0,
    category TEXT DEFAULT 'general',
    is_active BOOLEAN DEFAULT TRUE
);

-- Earned achievements
CREATE TABLE earned_achievements (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    profile_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    achievement_id UUID REFERENCES achievements(id),
    session_id UUID REFERENCES sessions(id),
    awarded_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(profile_id, achievement_id, session_id)
);

-- File attachments (photos, etc.)
CREATE TABLE attachments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES sessions(id) ON DELETE CASCADE,
    storage_path TEXT NOT NULL,
    filename TEXT NOT NULL,
    mime_type TEXT NOT NULL,
    file_size INTEGER,
    uploaded_by UUID REFERENCES profiles(id),
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Indexes and Performance

```sql
-- Performance indexes
CREATE INDEX idx_sessions_family_id ON sessions(family_id);
CREATE INDEX idx_sessions_started_at ON sessions(started_at DESC);
CREATE INDEX idx_score_events_session_id ON score_events(session_id);
CREATE INDEX idx_score_events_created_at ON score_events(created_at);
CREATE INDEX idx_family_members_profile_id ON family_members(profile_id);

-- Composite indexes for common queries
CREATE INDEX idx_sessions_family_game ON sessions(family_id, game_id);
CREATE INDEX idx_earned_achievements_profile ON earned_achievements(profile_id, awarded_at DESC);
```

---

## Row Level Security Policies

```sql
-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_fields ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_variants ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE score_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE earned_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;

-- Profiles: Users can only see/edit their own profile
CREATE POLICY "Users can view own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Family members: Only family members can see each other
CREATE POLICY "Family members can view members" ON family_members
    FOR SELECT USING (
        profile_id = auth.uid() OR
        family_id IN (
            SELECT family_id FROM family_members 
            WHERE profile_id = auth.uid()
        )
    );

-- Families: Only members can view/edit
CREATE POLICY "Family members can view family" ON families
    FOR SELECT USING (
        id IN (
            SELECT family_id FROM family_members 
            WHERE profile_id = auth.uid()
        )
    );

-- Sessions: Only family members can access
CREATE POLICY "Family members can access sessions" ON sessions
    FOR ALL USING (
        family_id IN (
            SELECT family_id FROM family_members 
            WHERE profile_id = auth.uid()
        )
    );

-- Score events: Only family members can access
CREATE POLICY "Family members can access score events" ON score_events
    FOR ALL USING (
        session_id IN (
            SELECT s.id FROM sessions s
            JOIN family_members fm ON s.family_id = fm.family_id
            WHERE fm.profile_id = auth.uid()
        )
    );
```

---

## Real-time Synchronization

### Supabase Realtime Channels
- Subscribe to family-specific channels: `family:{family_id}`
- Real-time events for:
  - `sessions` table changes
  - `score_events` insertions
  - `session_players` updates

### Offline-First Sync Strategy
1. **Local-first**: All mutations saved to Isar immediately
2. **Background sync**: Queue pending changes with retry logic
3. **Conflict resolution**: Server timestamp wins for score events
4. **Idempotency**: Client-generated UUIDs prevent duplicates

### Sync Engine Implementation
```dart
class SyncEngine {
  final IsarDatabase _localDb;
  final SupabaseClient _supabase;
  final RealtimeChannel _channel;

  // Push local changes to server
  Future<void> syncPendingChanges() async {
    final pendingEvents = await _localDb.scoreEvents
        .where()
        .syncStatusEqualTo(SyncStatus.pending)
        .findAll();
    
    for (final event in pendingEvents) {
      try {
        await _supabase.from('score_events').insert(event.toJson());
        event.syncStatus = SyncStatus.synced;
        await _localDb.writeTxn(() => _localDb.scoreEvents.put(event));
      } catch (e) {
        // Handle retry logic with exponential backoff
      }
    }
  }

  // Handle real-time updates
  void _handleRealtimeEvent(RealtimeMessage message) {
    switch (message.table) {
      case 'score_events':
        _syncScoreEvent(ScoreEvent.fromJson(message.new_record));
        break;
    }
  }
}
```

---

## Feature Modules

### 1. Authentication & Profiles
**Files**: `packages/features/auth/`

- Email/password authentication
- Social logins (Apple, Google)
- Profile creation and management
- Avatar upload functionality

**Key Components**:
- `AuthRepository` - Supabase auth wrapper
- `ProfileRepository` - Profile CRUD operations
- `AuthBloc` - Authentication state management

### 2. Family Management
**Files**: `packages/features/families/`

- Create and join families
- Invite system with QR codes
- Member role management
- Family settings

**Key Components**:
- `FamilyRepository` - Family and member operations
- `InviteService` - Generate and process invites
- `FamilyBloc` - Family state management

### 3. Game Templates
**Files**: `packages/features/games/`

- Built-in game templates (Uno, Catan, etc.)
- Custom game creation
- Extensible scoring field definitions
- Game variant management

**Key Components**:
- `GameRepository` - Game CRUD operations
- `GameTemplateService` - Pre-built templates
- `GameBloc` - Game library state

### 4. Live Sessions
**Files**: `packages/features/sessions/`

- Start new match sessions
- Player selection and ordering
- Real-time score tracking
- Session completion and finalization

**Key Components**:
- `SessionRepository` - Session operations
- `ScoreEventRepository` - Score tracking
- `LiveSessionBloc` - Active session state
- `ScoreEventBloc` - Score event management

### 5. Match History & Statistics
**Files**: `packages/features/history/`

- Session history browsing
- Player and game statistics
- Seasonal leaderboards
- Head-to-head comparisons

**Key Components**:
- `HistoryRepository` - Historical data queries
- `StatsService` - Statistical calculations
- `HistoryBloc` - History and stats state

### 6. Achievements System
**Files**: `packages/features/achievements/`

- Achievement definitions and criteria
- Badge earning logic
- Achievement progress tracking
- Achievement notifications

**Key Components**:
- `AchievementRepository` - Achievement operations
- `AchievementEngine` - Criteria evaluation
- `AchievementBloc` - Achievement state

---

## User Interface Design

### Design System
- **Color Scheme**: Modern, accessible palette with dark mode support
- **Typography**: Clean, readable fonts with proper hierarchy
- **Icons**: Lucide React icon set for consistency
- **Spacing**: 8px grid system
- **Components**: Reusable UI kit with theme support

### Key Screens

**1. Family Dashboard**
- Family member list with avatars
- Quick access to recent games
- Start new session button
- Statistics overview

**2. Game Library**
- Grid of game templates
- Search and filter functionality
- Create custom game option
- Game details modal

**3. Live Session**
- Player list with current scores
- Large score adjustment buttons (+/-1, +/-5, +/-10)
- Round indicator
- Quick actions (undo, notes, photo)

**4. Session History**
- Chronological list of completed sessions
- Filter by game, player, date range
- Session detail view with final scores
- Statistics and achievements earned

**5. Player Profile**
- Personal statistics dashboard
- Achievement gallery
- Recent activity feed
- Win/loss record by game

### Responsive Design
- **Mobile-first** approach
- Tablet-optimized layouts
- Desktop PWA support
- Adaptive navigation (bottom tabs on mobile, sidebar on desktop)

---

## Development Workflow

### 1. Environment Setup
```bash
# Prerequisites
flutter --version  # 3.x required
dart --version     # 3.x required

# Clone and setup
git clone <repository>
cd family-score-tracker
flutter pub get

# Install melos for monorepo management
dart pub global activate melos
melos bootstrap

# Supabase setup
supabase login
supabase link --project-ref <YOUR_PROJECT_REF>
supabase db push  # Apply migrations
```

### 2. Local Development
```bash
# Start Supabase locally (optional)
supabase start

# Run app with hot reload
flutter run -d chrome  # Web
flutter run -d ios     # iOS simulator
flutter run -d android # Android emulator

# Generate code (after model changes)
dart run build_runner build --delete-conflicting-outputs
```

### 3. Testing Strategy
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests with golden files
flutter test --update-goldens

# Code coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### 4. Code Quality
- **Linting**: `very_good_analysis` package
- **Formatting**: `dart format` with 80-character line limit
- **Import sorting**: Automatic with VS Code extension
- **Documentation**: Comprehensive dartdoc comments

---

## Build and Deployment

### Android Build
```bash
# Debug APK
flutter build apk --debug

# Release AAB (for Play Store)
flutter build appbundle --release

# Fastlane automation
cd android
bundle exec fastlane beta  # Internal testing
bundle exec fastlane production  # Play Store release
```

### iOS Build
```bash
# Debug build
flutter build ios --debug

# Release build
flutter build ipa --release

# Upload to App Store Connect
xcrun altool --upload-app -f build/ios/ipa/*.ipa -u <email> -p <app-password>
```

### Web Deployment
```bash
# Build PWA
flutter build web --release --pwa-strategy offline-first

# Deploy to hosting (example: Firebase Hosting)
firebase deploy --only hosting

# Configure for PWA
# - Service worker for offline functionality
# - Web app manifest for installation
# - Proper caching headers
```

### CI/CD Pipeline
```yaml
# .github/workflows/ci.yml
name: CI/CD
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.x'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3

  build-web:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Build web
        run: flutter build web --release
      
      - name: Deploy to preview (PR only)
        if: github.event_name == 'pull_request'
        run: |
          # Deploy to preview environment
          
  build-mobile:
    needs: test
    if: startsWith(github.ref, 'refs/tags/')
    strategy:
      matrix:
        platform: [android, ios]
    runs-on: ${{ matrix.platform == 'ios' && 'macos-latest' || 'ubuntu-latest' }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      
      - name: Build ${{ matrix.platform }}
        run: |
          if [ "${{ matrix.platform }}" = "android" ]; then
            flutter build appbundle --release
          else
            flutter build ipa --release
          fi
      
      - name: Upload to stores
        run: |
          # Use Fastlane to upload to stores
```

---

## Deep Linking and NFC

### Deep Link Structure
- `scoretracker://family/{familyId}` - Open family dashboard
- `scoretracker://game/{gameId}` - Quick start game template
- `scoretracker://session/{sessionId}` - Resume active session
- `scoretracker://join/{inviteCode}` - Join family via invite

### Universal Links Configuration
**iOS** (`ios/Runner/Info.plist`):
```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:scoretracker.app</string>
</array>
```

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https"
          android:host="scoretracker.app" />
</intent-filter>
```

### NFC Integration
```dart
class NFCService {
  Future<void> writeGameNFC(String gameId) async {
    if (!await NfcManager.instance.isAvailable()) return;
    
    await NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      final ndef = Ndef.from(tag);
      if (ndef == null) return;
      
      final record = NdefRecord.createUri(
        Uri.parse('scoretracker://game/$gameId')
      );
      
      await ndef.write(NdefMessage([record]));
      await NfcManager.instance.stopSession();
    });
  }
  
  void startNFCListener() {
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      final ndef = Ndef.from(tag);
      if (ndef == null) return;
      
      final message = await ndef.read();
      if (message.records.isNotEmpty) {
        final uri = message.records.first.payload;
        // Handle deep link navigation
        _handleDeepLink(String.fromCharCodes(uri));
      }
    });
  }
}
```

---

## Analytics and Privacy

### Analytics Strategy
- **Privacy-first**: No personal data collection
- **Opt-in**: Users can disable analytics
- **Anonymous**: Events tied to anonymous session IDs
- **Minimal**: Only essential usage patterns

### Tracked Events
- App launches and session duration
- Feature usage (games created, sessions started)
- Performance metrics (load times, crash reports)
- Error tracking for debugging

### Analytics Abstraction
```dart
abstract class AnalyticsService {
  Future<void> initialize();
  Future<void> setUserId(String? userId);
  Future<void> logEvent(String name, Map<String, dynamic>? parameters);
  Future<void> setUserProperty(String name, String value);
}

class SentryAnalyticsService implements AnalyticsService {
  @override
  Future<void> initialize() async {
    await SentryFlutter.init((options) {
      options.dsn = 'YOUR_SENTRY_DSN';
      options.environment = kDebugMode ? 'development' : 'production';
    });
  }
  
  @override
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    Sentry.addBreadcrumb(Breadcrumb(
      message: name,
      data: parameters,
      category: 'user_action',
    ));
  }
}
```

---

## Security Considerations

### Data Protection
- **Encryption**: All data encrypted in transit (HTTPS/WSS)
- **At rest**: Supabase handles database encryption
- **Files**: Object storage with signed URLs
- **Local**: Isar database with optional encryption

### Authentication Security
- **Password requirements**: Strong password enforcement
- **Social logins**: OAuth2 with PKCE flow
- **Session management**: JWT tokens with refresh rotation
- **Multi-device**: Concurrent session support

### Privacy Controls
- **Data minimization**: Only collect necessary information
- **User control**: Delete account and all associated data
- **Export**: Allow users to export their data
- **Audit**: Log access to sensitive operations

### Row-Level Security Best Practices
- **Default deny**: All policies start with restrictive access
- **Principle of least privilege**: Users only see their family's data
- **Input validation**: Server-side validation on all mutations
- **Rate limiting**: Edge functions implement rate limiting

---

## Testing Strategy

### Unit Tests
```dart
// Example: Game repository tests
void main() {
  group('GameRepository', () {
    late GameRepository repository;
    late MockSupabaseClient mockClient;
    
    setUp(() {
      mockClient = MockSupabaseClient();
      repository = GameRepository(mockClient);
    });
    
    test('should fetch games for family', () async {
      // Arrange
      when(() => mockClient.from('games').select().eq('family_id', any()))
          .thenAnswer((_) async => mockGameData);
      
      // Act
      final games = await repository.getGamesForFamily('family-id');
      
      // Assert
      expect(games, hasLength(2));
      expect(games.first.title, equals('Uno'));
    });
  });
}
```

### Widget Tests
```dart
void main() {
  group('ScoreButton', () {
    testWidgets('should increment score when tapped', (tester) async {
      var score = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ScoreButton(
            value: 1,
            onScoreChange: (delta) => score += delta,
          ),
        ),
      );
      
      await tester.tap(find.byType(ScoreButton));
      expect(score, equals(1));
    });
  });
}
```

### Integration Tests
```dart
void main() {
  group('Score Tracking Flow', () {
    testWidgets('should complete full scoring session', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // Navigate to new session
      await tester.tap(find.text('Start New Game'));
      await tester.pumpAndSettle();
      
      // Select game
      await tester.tap(find.text('Uno'));
      await tester.pumpAndSettle();
      
      // Add players
      await tester.tap(find.text('Add Player'));
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      
      // Start session
      await tester.tap(find.text('Start Session'));
      await tester.pumpAndSettle();
      
      // Add scores
      await tester.tap(find.text('+10'));
      await tester.pumpAndSettle();
      
      // Verify score updated
      expect(find.text('10'), findsOneWidget);
    });
  });
}
```

---

## Performance Optimization

### Flutter Performance
- **Widget rebuilds**: Use `const` constructors where possible
- **State management**: Riverpod for efficient rebuilds
- **Images**: Cached network images with proper sizing
- **Lists**: Use `ListView.builder` for large datasets
- **Animations**: 60fps target with `AnimationController`

### Database Performance
- **Indexes**: Proper indexing on frequently queried columns
- **Pagination**: Implement cursor-based pagination
- **Caching**: Local caching with Isar for offline access
- **Queries**: Optimize N+1 queries with proper joins

### Network Optimization
- **Compression**: Enable gzip compression
- **Caching**: HTTP caching headers for static assets
- **Bundling**: Minimize API calls with batch operations
- **Images**: WebP format with size optimization

### Memory Management
- **Dispose**: Properly dispose controllers and streams
- **Weak references**: Use weak references where appropriate
- **Memory leaks**: Regular profiling with Flutter Inspector

---

## Deployment and DevOps

### Environment Configuration

**Development**
- Local Supabase instance with Docker
- Flutter debug builds
- Hot reload enabled
- Detailed logging and debugging

**Staging**
- Supabase staging project
- Flutter profile builds
- Feature flags for testing
- Automated testing deployment

**Production**
- Supabase production project
- Flutter release builds
- Performance monitoring
- Error tracking and alerting

### Monitoring and Observability

**Application Monitoring**
```dart
// Sentry integration for error tracking
Future<void> initializeMonitoring() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = Environment.sentryDsn;
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    },
  );
}
```

**Performance Metrics**
- App startup time
- Screen transition times
- API response times
- Local database query performance
- Memory usage patterns

**Health Checks**
- Database connectivity
- Authentication service status
- Real-time connection health
- File storage accessibility

### Backup and Recovery

**Database Backups**
- Automated daily backups via Supabase
- Point-in-time recovery capability
- Cross-region backup replication
- Regular restore testing

**User Data Recovery**
- Export functionality for user data
- Family data migration tools
- Account recovery workflows
- Data retention policies (GDPR compliance)

---

## Roadmap and Future Enhancements

### Phase 1: MVP (Months 1-2)
**Core Functionality**
- ✅ User authentication and profiles
- ✅ Family creation and management
- ✅ Basic game templates (Uno, Catan, Custom)
- ✅ Live scoring sessions
- ✅ Match history and basic statistics
- ✅ Offline mode with sync
- ✅ Web and mobile app deployment

**Success Metrics**
- 100+ active families
- 1000+ completed sessions
- < 2 second app load time
- 99.9% uptime

### Phase 2: Enhanced Experience (Months 3-4)
**Advanced Features**
- 🔄 Photo attachments and match sharing
- 🔄 Achievement system with badges
- 🔄 Seasonal leaderboards
- 🔄 Advanced statistics and rivalries
- 🔄 Deep linking and NFC support
- 🔄 Push notifications for invites
- 🔄 Export/import data functionality

**Success Metrics**
- 500+ active families
- 50+ achievements earned daily
- Photo attachment usage > 30%
- NFC feature adoption > 10%

### Phase 3: Community Features (Months 5-6)
**Social Enhancements**
- 🎯 Public game template gallery
- 🎯 Tournament mode and brackets
- 🎯 Cross-family challenges
- 🎯 Game recommendation engine
- 🎯 Social sharing integrations
- 🎯 Community-created game templates
- 🎯 Video call integration for remote play

**Success Metrics**
- 1000+ active families
- 100+ community game templates
- Tournament participation > 25%
- Cross-family interactions > 15%

### Phase 4: Advanced Analytics (Months 7-8)
**Data Intelligence**
- 🔮 AI-powered game recommendations
- 🔮 Predictive win probability
- 🔮 Advanced player profiling
- 🔮 Game balance analysis
- 🔮 Automated achievement suggestions
- 🔮 Trend analysis and insights
- 🔮 Personalized coaching tips

**Success Metrics**
- 95% accuracy on game recommendations
- 80% user engagement with insights
- 50% improvement in balanced games
- Advanced analytics usage > 60%

### Phase 5: Platform Expansion (Months 9-12)
**New Platforms and Integrations**
- 🚀 Smart TV app for large group games
- 🚀 Voice assistant integration
- 🚀 Board game publisher partnerships
- 🚀 Physical game component integration
- 🚀 AR features for enhanced gameplay
- 🚀 API for third-party integrations
- 🚀 White-label solutions for publishers

---

## User Stories and Acceptance Criteria

### Epic 1: Family Management

**Story: Create Family**
- As a user, I want to create a family group
- So that I can invite family members to track scores together

*Acceptance Criteria:*
- [ ] User can create a family with a name and description
- [ ] System generates unique invite code
- [ ] Creator becomes family owner with full permissions
- [ ] Family appears in user's family list

**Story: Invite Family Members**
- As a family owner, I want to invite members via link or QR code
- So that family members can easily join without complex setup

*Acceptance Criteria:*
- [ ] Generate shareable invite link
- [ ] Display QR code for mobile scanning
- [ ] Set expiration time for invite links
- [ ] Track pending invitations
- [ ] Send notifications when members join

**Story: Manage Family Roles**
- As a family owner, I want to assign different roles to members
- So that I can control permissions appropriately

*Acceptance Criteria:*
- [ ] Assign roles: Owner, Admin, Member, Child
- [ ] Role-based permissions for creating games and sessions
- [ ] Child accounts have restricted features
- [ ] Transfer ownership capability

### Epic 2: Game Library Management

**Story: Browse Game Templates**
- As a user, I want to browse pre-built game templates
- So that I can quickly start scoring familiar games

*Acceptance Criteria:*
- [ ] Display grid of game templates with icons
- [ ] Search and filter by game type, player count
- [ ] Show game details: rules, scoring, player range
- [ ] Preview scoring interface before starting

**Story: Create Custom Game**
- As a user, I want to create custom games with unique scoring
- So that I can track scores for games not in the template library

*Acceptance Criteria:*
- [ ] Define game name, description, and rules
- [ ] Configure scoring fields (points, rounds, bonuses)
- [ ] Set player count limits
- [ ] Save as template for reuse
- [ ] Share with other families (optional)

**Story: Customize Game Variants**
- As a user, I want to modify existing games with house rules
- So that I can adapt games to our family's preferences

*Acceptance Criteria:*
- [ ] Clone existing game template
- [ ] Modify scoring rules and fields
- [ ] Save as family-specific variant
- [ ] Track which variant was used in each session

### Epic 3: Live Scoring Sessions

**Story: Start New Session**
- As a user, I want to start a new scoring session quickly
- So that I can begin tracking scores without delay

*Acceptance Criteria:*
- [ ] Select game from family library
- [ ] Choose players from family members
- [ ] Drag to reorder player turn sequence
- [ ] Option to add guest players
- [ ] Quick start with recently used player combinations

**Story: Record Scores During Play**
- As a user, I want to easily record score changes during gameplay
- So that scoring doesn't interrupt the game flow

*Acceptance Criteria:*
- [ ] Large, touch-friendly score adjustment buttons
- [ ] Quick increment/decrement (±1, ±5, ±10)
- [ ] Custom score entry for exact amounts
- [ ] Undo last score change
- [ ] Visual feedback for score updates
- [ ] Real-time sync across all devices

**Story: Add Match Context**
- As a user, I want to add photos and notes to matches
- So that I can remember special moments and game details

*Acceptance Criteria:*
- [ ] Take or select photos during/after session
- [ ] Add text notes about the match
- [ ] Tag special events (first game, comeback win)
- [ ] Location tagging (optional)
- [ ] Privacy controls for sharing

### Epic 4: History and Statistics

**Story: View Match History**
- As a user, I want to see all past games and results
- So that I can review our family's gaming history

*Acceptance Criteria:*
- [ ] Chronological list of completed sessions
- [ ] Filter by date range, game, player
- [ ] Search by notes or tags
- [ ] Detailed session view with final scores
- [ ] Quick rematch option

**Story: Personal Statistics**
- As a user, I want to see my gaming statistics
- So that I can track my performance and improvement

*Acceptance Criteria:*
- [ ] Win/loss record overall and by game
- [ ] Average scores and rankings
- [ ] Streak tracking (wins, losses, games played)
- [ ] Progress charts over time
- [ ] Comparison with other family members

**Story: Head-to-Head Rivalries**
- As a user, I want to see detailed matchups against specific players
- So that I can track our competitive history

*Acceptance Criteria:*
- [ ] Win/loss record against each family member
- [ ] Head-to-head statistics by game
- [ ] Recent results and trends
- [ ] "Nemesis" and "Favorite Opponent" identification
- [ ] Challenge functionality for rematches

### Epic 5: Achievements and Gamification

**Story: Earn Achievements**
- As a user, I want to earn badges for gaming milestones
- So that I feel rewarded for my gaming accomplishments

*Acceptance Criteria:*
- [ ] Achievement notifications during/after games
- [ ] Badge collection gallery
- [ ] Progress tracking toward achievements
- [ ] Difficulty levels (bronze, silver, gold)
- [ ] Rare and special event achievements

**Story: Seasonal Competitions**
- As a family, I want seasonal leaderboards and competitions
- So that we can have ongoing friendly competition

*Acceptance Criteria:*
- [ ] Monthly/quarterly/annual leaderboards
- [ ] Multiple competition categories (wins, games played, achievements)
- [ ] Season rewards and recognition
- [ ] Historical season results
- [ ] Custom season creation

### Epic 6: Advanced Features

**Story: Offline Mode**
- As a user, I want to track scores without internet connection
- So that I can use the app anywhere

*Acceptance Criteria:*
- [ ] Full functionality works offline
- [ ] Local data storage and sync queue
- [ ] Automatic sync when connection restored
- [ ] Conflict resolution for concurrent edits
- [ ] Offline indicator in UI

**Story: Deep Link Quick Start**
- As a user, I want to quickly start specific games via links or NFC
- So that I can minimize setup time

*Acceptance Criteria:*
- [ ] Generate deep links for games and sessions
- [ ] NFC tag writing and reading
- [ ] Universal links work from any browser
- [ ] Quick player selection for frequent games
- [ ] Resume interrupted sessions

**Story: Data Export and Backup**
- As a user, I want to export my family's gaming data
- So that I have control over our information

*Acceptance Criteria:*
- [ ] Export data in CSV and JSON formats
- [ ] Include all sessions, scores, and statistics
- [ ] Photo attachments included in export
- [ ] Import data from exported files
- [ ] GDPR compliance for data requests

---

## API Documentation

### Authentication Endpoints

**POST /auth/signup**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "profile": {
    "display_name": "John Doe"
  }
}
```

**POST /auth/signin**
```json
{
  "email": "user@example.com", 
  "password": "securePassword123"
}
```

### Family Management

**GET /api/families**
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "Smith Family",
      "description": "Our gaming group",
      "member_count": 4,
      "role": "owner",
      "created_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

**POST /api/families**
```json
{
  "name": "New Family",
  "description": "Family game night group"
}
```

**POST /api/families/{id}/invite**
```json
{
  "email": "member@example.com",
  "role": "member"
}
```

### Game Library

**GET /api/families/{family_id}/games**
```json
{
  "data": [
    {
      "id": "uuid",
      "title": "Uno",
      "description": "Classic card game",
      "scoring_type": "points",
      "min_players": 2,
      "max_players": 10,
      "is_template": true,
      "created_at": "2024-01-15T10:00:00Z"
    }
  ]
}
```

**POST /api/families/{family_id}/games**
```json
{
  "title": "Custom Card Game",
  "description": "Our family's favorite",
  "scoring_type": "points",
  "min_players": 3,
  "max_players": 6,
  "default_rules": {
    "rounds": 5,
    "bonus_points": true
  },
  "fields": [
    {
      "field_key": "bonus",
      "label": "Bonus Points",
      "field_type": "number",
      "required": false
    }
  ]
}
```

### Session Management

**POST /api/families/{family_id}/sessions**
```json
{
  "game_id": "uuid",
  "players": [
    {
      "profile_id": "uuid",
      "seat_order": 1
    },
    {
      "profile_id": "uuid", 
      "seat_order": 2
    }
  ],
  "session_data": {
    "variant": "house_rules"
  }
}
```

**POST /api/sessions/{session_id}/scores**
```json
{
  "player_id": "uuid",
  "event_type": "score",
  "delta": 10,
  "reason": "Completed round",
  "round_number": 3
}
```

**PUT /api/sessions/{session_id}/complete**
```json
{
  "notes": "Great game! Close finish.",
  "final_scores": [
    {
      "player_id": "uuid",
      "final_score": 87,
      "placement": 1
    },
    {
      "player_id": "uuid",
      "final_score": 82, 
      "placement": 2
    }
  ]
}
```

### Statistics and History

**GET /api/families/{family_id}/sessions**
```json
{
  "data": [
    {
      "id": "uuid",
      "game": {
        "id": "uuid",
        "title": "Uno"
      },
      "started_at": "2024-01-20T19:00:00Z",
      "ended_at": "2024-01-20T20:30:00Z",
      "player_count": 4,
      "winner": {
        "id": "uuid",
        "display_name": "Alice"
      },
      "final_scores": [87, 82, 76, 71]
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 156
  }
}
```

**GET /api/profiles/{profile_id}/statistics**
```json
{
  "overall": {
    "games_played": 89,
    "wins": 23,
    "win_rate": 0.258,
    "average_placement": 2.1,
    "current_streak": {
      "type": "games_played",
      "count": 5
    }
  },
  "by_game": [
    {
      "game_id": "uuid",
      "game_title": "Uno", 
      "games_played": 34,
      "wins": 8,
      "win_rate": 0.235,
      "average_score": 78.5,
      "best_score": 112
    }
  ],
  "achievements": {
    "total_earned": 12,
    "points": 340,
    "recent": [
      {
        "id": "uuid",
        "name": "First Victory",
        "earned_at": "2024-01-20T20:35:00Z"
      }
    ]
  }
}
```

---

## Error Handling and Edge Cases

### Network and Connectivity

**Offline Mode Handling**
```dart
class NetworkAwareRepository {
  Future<T> executeWithFallback<T>(
    Future<T> Function() networkCall,
    Future<T> Function() localFallback,
  ) async {
    try {
      if (await _connectivity.isConnected) {
        return await networkCall();
      } else {
        return await localFallback();
      }
    } catch (e) {
      if (e is NetworkException) {
        return await localFallback();
      }
      rethrow;
    }
  }
}
```

**Sync Conflict Resolution**
```dart
class SyncConflictResolver {
  Future<ScoreEvent> resolveConflict(
    ScoreEvent local,
    ScoreEvent remote,
  ) async {
    // Server timestamp always wins for score events
    if (remote.createdAt.isAfter(local.createdAt)) {
      return remote;
    }
    
    // For simultaneous events, use server-generated ID as tiebreaker
    if (remote.createdAt == local.createdAt) {
      return remote; // Server version wins
    }
    
    return local;
  }
}
```

### Data Validation and Integrity

**Input Validation**
```dart
class SessionValidator {
  static ValidationResult validateSession(SessionRequest request) {
    final errors = <String>[];
    
    if (request.players.length < 2) {
      errors.add('Session must have at least 2 players');
    }
    
    if (request.players.length > 10) {
      errors.add('Session cannot have more than 10 players');
    }
    
    final uniquePlayers = request.players.map((p) => p.profileId).toSet();
    if (uniquePlayers.length != request.players.length) {
      errors.add('Duplicate players are not allowed');
    }
    
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}
```

**Data Corruption Recovery**
```dart
class DataIntegrityChecker {
  Future<void> validateAndRepair() async {
    // Check for orphaned records
    await _cleanupOrphanedScoreEvents();
    
    // Verify score calculations
    await _recalculateFinalScores();
    
    // Check for missing required fields
    await _validateRequiredFields();
  }
  
  Future<void> _cleanupOrphanedScoreEvents() async {
    final orphanedEvents = await _localDb.scoreEvents
        .filter()
        .not()
        .sessionIdProperty(_validSessionIds)
        .findAll();
        
    if (orphanedEvents.isNotEmpty) {
      await _localDb.writeTxn(() => 
        _localDb.scoreEvents.deleteAll(orphanedEvents.map((e) => e.id))
      );
    }
  }
}
```

### User Experience Error Handling

**Graceful Degradation**
```dart
class ResilientImageLoader extends StatelessWidget {
  final String imageUrl;
  final Widget placeholder;
  final Widget errorWidget;
  
  const ResilientImageLoader({
    required this.imageUrl,
    required this.placeholder,
    required this.errorWidget,
  });
  
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) {
        // Log error for debugging
        Logger.warning('Failed to load image: $url', error);
        
        // Show friendly error message
        return errorWidget;
      },
      // Retry logic
      maxHeightDiskCache: 1000,
      maxWidthDiskCache: 1000,
    );
  }
}
```

**User-Friendly Error Messages**
```dart
class ErrorMessageTranslator {
  static String getReadableError(Exception error) {
    if (error is NetworkException) {
      return 'Please check your internet connection and try again';
    }
    
    if (error is AuthException) {
      return 'Please sign in again to continue';
    }
    
    if (error is ValidationException) {
      return error.message; // Already user-friendly
    }
    
    if (error is StorageException) {
      return 'Unable to save changes. Please try again';
    }
    
    // Generic fallback
    return 'Something went wrong. Please try again';
  }
}
```

---

## Accessibility and Internationalization

### Accessibility Features

**Screen Reader Support**
```dart
class AccessibleScoreButton extends StatelessWidget {
  final int delta;
  final VoidCallback onPressed;
  final String playerName;
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Add $delta points to $playerName',
      hint: 'Double tap to add points',
      button: true,
      onTap: onPressed,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(delta > 0 ? '+$delta' : '$delta'),
      ),
    );
  }
}
```

**High Contrast and Font Scaling**
```dart
class AccessibleTheme {
  static ThemeData getTheme(BuildContext context) {
    final platformBrightness = MediaQuery.of(context).platformBrightness;
    final highContrast = MediaQuery.of(context).highContrast;
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    
    return ThemeData(
      brightness: platformBrightness,
      // Increase contrast ratios for accessibility
      primaryColor: highContrast ? Colors.black : Colors.blue,
      backgroundColor: highContrast ? Colors.white : Colors.grey[100],
      // Scale font sizes appropriately
      textTheme: TextTheme(
        bodyText1: TextStyle(
          fontSize: 16 * textScaleFactor.clamp(1.0, 2.0),
        ),
      ),
    );
  }
}
```

**Keyboard Navigation**
```dart
class KeyboardNavigationWrapper extends StatelessWidget {
  final Widget child;
  
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.arrowRight): NextPlayerIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): PreviousPlayerIntent(),
        LogicalKeySet(LogicalKeyboardKey.space): AddPointIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): ConfirmActionIntent(),
      },
      child: Actions(
        actions: {
          NextPlayerIntent: CallbackAction<NextPlayerIntent>(
            onInvoke: (intent) => _selectNextPlayer(),
          ),
          // ... other actions
        },
        child: child,
      ),
    );
  }
}
```

### Internationalization (i18n)

**Supported Languages (Initial)**
- English (en-US) - Primary
- Spanish (es-ES)
- French (fr-FR)
- German (de-DE)
- Italian (it-IT)
- Portuguese (pt-BR)

**Localization Setup**
```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.0

flutter:
  generate: true
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

**Example Localization Files**
```json
// lib/l10n/app_en.arb
{
  "appTitle": "Family Score Tracker",
  "startNewGame": "Start New Game",
  "addPlayer": "Add Player",
  "gameCompleted": "Game Completed!",
  "winner": "{playerName} wins!",
  "@winner": {
    "placeholders": {
      "playerName": {
        "type": "String"
      }
    }
  },
  "scorePoints": "{count, plural, one{1 point} other{{count} points}}",
  "@scorePoints": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}
```

```json
// lib/l10n/app_es.arb
{
  "appTitle": "Marcador Familiar",
  "startNewGame": "Nuevo Juego",
  "addPlayer": "Añadir Jugador",
  "gameCompleted": "¡Juego Completado!",
  "winner": "¡{playerName} gana!",
  "scorePoints": "{count, plural, one{1 punto} other{{count} puntos}}"
}
```

**Usage in Code**
```dart
class GameScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _startNewGame,
            child: Text(l10n.startNewGame),
          ),
          Text(l10n.scorePoints(currentScore)),
        ],
      ),
    );
  }
}
```

---

## Final Implementation Checklist

### Pre-Development Setup
- [ ] Create Supabase project and configure environment
- [ ] Set up Flutter development environment with proper SDK versions
- [ ] Initialize monorepo structure with Melos
- [ ] Configure CI/CD pipeline with GitHub Actions
- [ ] Set up error tracking with Sentry
- [ ] Create development, staging, and production environments

### Core Feature Implementation
- [ ] Authentication system with email and social logins
- [ ] Family management with invite system
- [ ] Game library with templates and custom games
- [ ] Live scoring sessions with real-time sync
- [ ] Match history and basic statistics
- [ ] Offline mode with local database
- [ ] Photo attachments with cloud storage
- [ ] Achievement system with badge mechanics

### Quality Assurance
- [ ] Comprehensive unit test coverage (>80%)
- [ ] Widget tests for all custom components
- [ ] Integration tests for critical user flows
- [ ] Performance testing and optimization
- [ ] Accessibility audit and compliance
- [ ] Security audit and penetration testing
- [ ] Cross-platform compatibility testing

### Deployment Preparation
- [ ] App store metadata and screenshots
- [ ] Privacy policy and terms of service
- [ ] Beta testing program setup
- [ ] Analytics and monitoring configuration
- [ ] Backup and disaster recovery procedures
- [ ] Documentation for users and developers

### Launch Readiness
- [ ] Marketing materials and landing page
- [ ] User onboarding flow optimization
- [ ] Customer support documentation
- [ ] Bug reporting and feedback systems
- [ ] App store submissions (iOS App Store, Google Play)
- [ ] Web deployment with PWA features

---

## Conclusion

This comprehensive specification provides a complete roadmap for building the Family Game Score Tracker application. The architecture balances simplicity with scalability, ensuring the app can grow from a family tool to a community platform while maintaining excellent performance and user experience.

Key success factors:
1. **User-first design** - Every feature prioritizes ease of use during active gameplay
2. **Offline-first architecture** - Works reliably regardless of connectivity
3. **Privacy by design** - Strong security controls and minimal data collection
4. **Extensible foundation** - Game templates and achievement systems allow easy expansion
5. **Cross-platform consistency** - Single codebase ensures feature parity across devices

The modular architecture and comprehensive testing strategy provide confidence in the system's reliability and maintainability as it scales to serve thousands of families tracking millions of game sessions.

**Next Steps:**
1. Review and approve this specification
2. Set up development environment and tooling
3. Begin implementation with MVP features
4. Establish regular sprint cycles and progress reviews
5. Plan beta testing with target families

---

*This specification is a living document and should be updated as requirements evolve and new features are planned.*