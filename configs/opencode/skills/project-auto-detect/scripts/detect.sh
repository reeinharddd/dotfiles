#!/usr/bin/env bash
set -euo pipefail

# project-auto-detect: detect language, framework, tools of the current project
# Output: JSON to stdout

CWD="${1:-$(pwd)}"
cd "$CWD"

PROJECT_NAME=$(basename "$CWD")

# --- Language detection ---
LANG=""
FRAMEWORKS="[]"
TEST_RUNNER=""
PKG_MANAGER=""
BUILD_TOOL=""
SKILLS="[]"
HAS_AGENTS=false
HAS_DOCKER=false
HAS_CI=false

# Priority order: Rust > Go > Python > Node > Java > C# > Ruby > PHP > Dart > Swift
if [ -f "Cargo.toml" ]; then
  LANG="rust"
  TEST_RUNNER="cargo test"
  PKG_MANAGER="cargo"
  BUILD_TOOL="cargo"
  SKILLS='["rust-engineer"]'
  # Check for Dockerfile or compose
  [ -f "Dockerfile" ] && HAS_DOCKER=true
  [ -f "docker-compose.yml" ] || [ -f "compose.yml" ] || [ -f "docker-compose.yaml" ] && HAS_DOCKER=true
  [ -d ".github/workflows" ] && HAS_CI=true

elif [ -f "go.mod" ]; then
  LANG="go"
  TEST_RUNNER="go test"
  PKG_MANAGER="go"
  MODULE=$(head -1 go.mod | awk '{print $2}')
  SKILLS='["golang-pro"]'
  [ -f "Makefile" ] && BUILD_TOOL="make"
  [ -f "Dockerfile" ] && HAS_DOCKER=true
  [ -d ".github/workflows" ] && HAS_CI=true

elif [ -f "pyproject.toml" ]; then
  LANG="python"
  # Detect package manager
  if [ -f "uv.lock" ]; then
    PKG_MANAGER="uv"
  elif [ -f "poetry.lock" ]; then
    PKG_MANAGER="poetry"
  elif [ -f "Pipfile" ]; then
    PKG_MANAGER="pipenv"
  else
    PKG_MANAGER="pip"
  fi
  TEST_RUNNER="pytest"
  BUILD_TOOL=""
  SKILLS='["python-pro"]'

  # Detect frameworks
  if grep -qi "fastapi" pyproject.toml 2>/dev/null; then
    FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["fastapi"]')
    SKILLS=$(echo "$SKILLS" | jq '. + ["fastapi-expert"]')
  fi
  if grep -qi "django" pyproject.toml 2>/dev/null; then
    FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["django"]')
    SKILLS=$(echo "$SKILLS" | jq '. + ["django-expert"]')
  fi
  if [ -f "manage.py" ]; then
    FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["django"]')
    SKILLS=$(echo "$SKILLS" | jq '. + ["django-expert"]')
  fi
  # Always add sql-pro for Python backends
  SKILLS=$(echo "$SKILLS" | jq '. + ["sql-pro"]')
  [ -f "Dockerfile" ] && HAS_DOCKER=true
  [ -d ".github/workflows" ] && HAS_CI=true

elif [ -f "package.json" ]; then
  LANG="javascript"
  # Detect package manager
  if [ -f "yarn.lock" ]; then
    PKG_MANAGER="yarn"
  elif [ -f "pnpm-lock.yaml" ]; then
    PKG_MANAGER="pnpm"
  elif [ -f "bun.lock" ]; then
    PKG_MANAGER="bun"
  else
    PKG_MANAGER="npm"
  fi
  # Detect TypeScript
  if [ -f "tsconfig.json" ]; then
    LANG="typescript"
    SKILLS='["typescript-pro"]'
  else
    SKILLS='["javascript-pro"]'
  fi
  # Test runner
  if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
    TEST_RUNNER=$(jq -r '.scripts.test' package.json)
  else
    TEST_RUNNER=""
  fi
  # Build tool
  [ -f "tsconfig.json" ] && BUILD_TOOL="tsc"
  [ -f "vite.config.ts" ] || [ -f "vite.config.js" ] && BUILD_TOOL="vite"
  [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ] && BUILD_TOOL="next"

  # Detect frameworks
  if [ -f "next.config.js" ] || [ -f "next.config.ts" ] || [ -f "next.config.mjs" ]; then
    FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["nextjs"]')
    SKILLS=$(echo "$SKILLS" | jq '. + ["nextjs-developer", "react-expert"]')
  elif [ -f "nuxt.config.ts" ] || [ -f "nuxt.config.js" ]; then
    FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["nuxt"]')
    SKILLS=$(echo "$SKILLS" | jq '. + ["vue-expert"]')
  elif [ -f "angular.json" ]; then
    FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["angular"]')
    SKILLS=$(echo "$SKILLS" | jq '. + ["angular-architect"]')
  elif [ -f "nest-cli.json" ]; then
    FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["nestjs"]')
    SKILLS=$(echo "$SKILLS" | jq '. + ["nestjs-expert"]')
  else
    # Check deps for react/vue
    if jq -e '.dependencies.react' package.json >/dev/null 2>&1 || jq -e '.devDependencies.react' package.json >/dev/null 2>&1; then
      FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["react"]')
      SKILLS=$(echo "$SKILLS" | jq '. + ["react-expert"]')
    fi
    if jq -e '.dependencies.vue' package.json >/dev/null 2>&1; then
      FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["vue"]')
      SKILLS=$(echo "$SKILLS" | jq '. + ["vue-expert"]')
    fi
  fi
  [ -f "Dockerfile" ] && HAS_DOCKER=true
  [ -d ".github/workflows" ] && HAS_CI=true

elif [ -f "pom.xml" ]; then
  LANG="java"
  PKG_MANAGER="maven"
  TEST_RUNNER="mvn test"
  BUILD_TOOL="maven"
  SKILLS='["java-architect"]'
  # Check for Spring Boot
  if grep -qi "spring-boot" pom.xml 2>/dev/null; then
    FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["spring-boot"]')
    SKILLS=$(echo "$SKILLS" | jq '. + ["spring-boot-engineer"]')
  fi
  [ -f "Dockerfile" ] && HAS_DOCKER=true

elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  LANG="java"
  PKG_MANAGER="gradle"
  TEST_RUNNER="gradle test"
  BUILD_TOOL="gradle"
  SKILLS='["java-architect"]'
  [ -f "Dockerfile" ] && HAS_DOCKER=true

elif ls *.csproj 2>/dev/null | head -1 >/dev/null 2>&1; then
  LANG="csharp"
  PKG_MANAGER="dotnet"
  TEST_RUNNER="dotnet test"
  BUILD_TOOL="dotnet"
  SKILLS='["csharp-developer"]'
  [ -f "Dockerfile" ] && HAS_DOCKER=true

elif [ -f "Gemfile" ]; then
  LANG="ruby"
  PKG_MANAGER="bundler"
  TEST_RUNNER="bundle exec rspec"
  BUILD_TOOL=""
  SKILLS='["rails-expert"]'
  if grep -qi "rails" Gemfile 2>/dev/null; then
    FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["rails"]')
  fi
  [ -f "Dockerfile" ] && HAS_DOCKER=true

elif [ -f "composer.json" ]; then
  LANG="php"
  PKG_MANAGER="composer"
  TEST_RUNNER="phpunit"
  BUILD_TOOL=""
  SKILLS='["php-pro"]'
  if [ -f "artisan" ]; then
    FRAMEWORKS=$(echo "$FRAMEWORKS" | jq '. + ["laravel"]')
    SKILLS=$(echo "$SKILLS" | jq '. + ["laravel-specialist"]')
  fi
  [ -f "Dockerfile" ] && HAS_DOCKER=true

elif [ -f "pubspec.yaml" ]; then
  LANG="dart"
  PKG_MANAGER="pub"
  TEST_RUNNER="flutter test"
  BUILD_TOOL=""
  SKILLS='["flutter-expert"]'
  [ -f "Dockerfile" ] && HAS_DOCKER=true

elif ls *.xcodeproj 2>/dev/null | head -1 >/dev/null 2>&1 || [ -f "Package.swift" ]; then
  LANG="swift"
  PKG_MANAGER="spm"
  TEST_RUNNER="swift test"
  BUILD_TOOL="swift build"
  SKILLS='["swift-expert"]'
fi

# --- Detect infra tools (always) ---
[ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -f "compose.yml" ] && HAS_DOCKER=true
[ -d ".github/workflows" ] && HAS_CI=true
[ -d "k8s" ] || [ -d "kubernetes" ] && SKILLS=$(echo "$SKILLS" | jq '. + ["kubernetes-specialist", "devops-engineer"]')
[ -f "*.tf" ] || [ -d "terraform" ] && SKILLS=$(echo "$SKILLS" | jq '. + ["terraform-engineer"]')

# --- Check for project AGENTS.md / CLAUDE.md ---
[ -f "AGENTS.md" ] || [ -f "CLAUDE.md" ] && HAS_AGENTS=true

# --- Docker compose not infra but dev ---
[ -f "docker-compose.yml" ] || [ -f "compose.yml" ] && SKILLS=$(echo "$SKILLS" | jq '. + ["devops-engineer"]')

# --- Output ---
jq -n \
  --arg name "$PROJECT_NAME" \
  --arg lang "$LANG" \
  --argjson frameworks "$FRAMEWORKS" \
  --arg test "$TEST_RUNNER" \
  --arg pkg "$PKG_MANAGER" \
  --arg build "$BUILD_TOOL" \
  --argjson skills "$SKILLS" \
  --argjson hasAgents $HAS_AGENTS \
  --argjson hasDocker $HAS_DOCKER \
  --argjson hasCi $HAS_CI \
  '{
    project_name: $name,
    language: $lang,
    frameworks: $frameworks,
    test_runner: $test,
    package_manager: $pkg,
    build_tool: $build,
    skills: $skills,
    has_agents: $hasAgents,
    has_docker: $hasDocker,
    has_ci: $hasCi
  }'
