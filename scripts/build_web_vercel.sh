#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sdk_dir="${VERCEL_CACHE_DIR:-/tmp}/fabricare-flutter-3.41.4"
expected_revision="ff37bef603469fb030f2b72995ab929ccfc227f0"

if [[ ! -d "$sdk_dir/.git" ]]; then
  git clone --depth 1 --branch 3.41.4 https://github.com/flutter/flutter.git "$sdk_dir"
fi
if [[ "$(git -C "$sdk_dir" rev-parse HEAD)" != "$expected_revision" ]]; then
  echo "Flutter SDK revision does not match the verified 3.41.4 build." >&2
  exit 1
fi

export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true
export PUB_CACHE="${VERCEL_CACHE_DIR:-/tmp}/fabricare-pub-cache"
cd "$repo_dir"
"$sdk_dir/bin/flutter" config --no-analytics
"$sdk_dir/bin/flutter" pub get --enforce-lockfile
"$sdk_dir/bin/flutter" build web --release --no-pub \
  --dart-define=API_BASE_URL=/api --output="$repo_dir/web/dist"
