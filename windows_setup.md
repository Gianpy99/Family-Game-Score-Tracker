# Windows Setup Guide for Family Game Score Tracker

## Prerequisites for Windows

### 1. Install Flutter
```powershell
# Option 1: Direct download
# Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows
# Extract to C:\flutter and add to PATH

# Option 2: Using Chocolatey
choco install flutter

# Option 3: Using Scoop
scoop install flutter
```

### 2. Install Git
```powershell
# Using Chocolatey
choco install git

# Using Scoop
scoop install git

# Or download from https://git-scm.com/download/win
```

### 3. Install Supabase CLI
```powershell
# Option 1: Using Scoop (recommended)
scoop install supabase

# Option 2: Using Chocolatey
choco install supabase

# Option 3: Using NPM
npm install -g supabase

# Option 4: Download binary from GitHub releases
# https://github.com/supabase/cli/releases
```

### 4. Install Docker Desktop (for local Supabase)
Download and install from: https://www.docker.com/products/docker-desktop/

## Setup Options for Windows

### Option A: PowerShell/Command Prompt
1. Run the main setup script with Git Bash:
   ```bash
   # Save the script as setup_project.sh
   bash setup_project.sh
   ```

2. Use Windows batch files for development:
   ```cmd
   cd family_score_tracker
   .\tools\scripts\setup_dev.bat
   ```

### Option B: Windows Subsystem for Linux (WSL) - Recommended
1. Install WSL2:
   ```powershell
   # In Administrator PowerShell
   wsl --install
   ```

2. Install Ubuntu from Microsoft Store

3. Run the setup in WSL:
   ```bash
   # Install Flutter in WSL
   sudo snap install flutter --classic
   
   # Install Supabase CLI
   curl -sL https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz | tar -xz
   sudo mv supabase /usr/local/bin/
   
   # Run the setup
   bash setup_project.sh
   ```

### Option C: Git Bash
1. Install Git for Windows (includes Git Bash)
2. Run setup in Git Bash:
   ```bash
   bash setup_project.sh
   ```

## Development Workflow on Windows

### Using Command Prompt/PowerShell
```cmd
# Bootstrap packages
dart pub global activate melos
melos bootstrap

# Run code generation
.\tools\scripts\codegen.bat

# Start development
cd apps\mobile
flutter run
```

### Using Git Bash/WSL
```bash
# Use Unix commands
./tools/scripts/setup_dev.sh
./tools/scripts/codegen.sh

# Start development
cd apps/mobile
flutter run
```

## IDE Setup

### VS Code (Recommended)
1. Install VS Code
2. Install extensions:
   - Flutter
   - Dart
   - Thunder Client (for API testing)
   - GitLens

### Android Studio
1. Install Android Studio
2. Install Flutter plugin
3. Install Dart plugin

## Common Windows Issues & Solutions

### Issue: Flutter not found in PATH
```cmd
# Add Flutter to PATH in System Environment Variables
# Or use full path
C:\flutter\bin\flutter doctor
```

### Issue: PowerShell Execution Policy
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Issue: Supabase Docker issues
```cmd
# Make sure Docker Desktop is running
# Check WSL2 integration in Docker Desktop settings
```

### Issue: Git line endings
```bash
# Configure Git for Windows
git config --global core.autocrlf true
git config --global core.eol crlf
```

## File Structure Notes for Windows
- Use `\` for paths in batch files
- Use `/` for paths in Git Bash/WSL
- Both work in Dart/Flutter code
- The project structure works the same across platforms

## Next Steps
1. Choose your preferred setup method (WSL recommended)
2. Run the appropriate setup script
3. Configure your `.env` file
4. Start developing with `flutter run`

## Performance Tips
- Use SSD storage for better Flutter performance
- Enable Developer Mode in Windows Settings
- Consider using WSL2 for better Unix tool compatibility
- Use Windows Terminal for better command line experience
