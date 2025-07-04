#!/usr/bin/env nix-shell
#!nix-shell -i bash -p cacert curl gnused jq nix-prefetch-github prefetch-npm-deps

set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

tags_response=$(curl -s "https://api.github.com/repos/google-gemini/gemini-cli/tags")
latest_version=$(echo "$tags_response" | jq -r '.[0].name' | sed 's/^v//')
latest_rev=$(echo "$tags_response" | jq -r '.[0].commit.sha')

src_hash=$(nix-prefetch-github google-gemini gemini-cli --rev "$latest_rev" | jq -r '.hash')

temp_dir=$(mktemp -d)
curl -s "https://raw.githubusercontent.com/google-gemini/gemini-cli/v$latest_version/package-lock.json" > "$temp_dir/package-lock.json"
npm_deps_hash=$(prefetch-npm-deps "$temp_dir/package-lock.json")
rm -rf "$temp_dir"

sed -i "s|version = \".*\";|version = \"$latest_version\";|" "${DEFAULT_NIX_FILE}"
# TODO: is this needed?
# sed -i "s|rev = \".*\";|rev = \"$latest_rev\";|" "${DEFAULT_NIX_FILE}"
sed -i "/src = fetchFromGitHub/,/};/s|hash = \".*\";|hash = \"$src_hash\";|" "${DEFAULT_NIX_FILE}"
sed -i "/npmDeps = fetchNpmDeps/,/};/s|hash = \".*\";|hash = \"$npm_deps_hash\";|" "${DEFAULT_NIX_FILE}"
