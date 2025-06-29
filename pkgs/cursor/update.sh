#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq coreutils common-updater-scripts gnused
set -eu -o pipefail
set -x

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
DEFAULT_NIX_FILE="$SCRIPT_DIR/default.nix"

currentVersion=$(grep 'version = "' "$DEFAULT_NIX_FILE" | head -n1 | cut -d '"' -f 2)

declare -A platforms=( [x86_64-linux]='linux-x64' [aarch64-linux]='linux-arm64' [x86_64-darwin]='darwin-x64' [aarch64-darwin]='darwin-arm64' )
declare -A updates=( )
first_version=""

for platform in "${!platforms[@]}"; do
    api_platform=${platforms[$platform]}
    result=$(curl -s "https://api2.cursor.sh/updates/api/download/stable/${api_platform}/cursor")
    version=$(echo ${result} | jq -r '.version')
    if [[ "$version" == "$currentVersion" ]]; then
      exit 0
    fi
    if [[ -z "$first_version" ]]; then
      first_version=$version
      first_platform=$platform
    elif [[ "$version" != "$first_version" ]]; then
      >&2 echo "Multiple versions found: $first_version ($first_platform) and $version ($platform)"
      exit 1
    fi
    url=$(echo ${result} | jq -r '.downloadUrl')
    # Exits with code 22 if not downloadable
    curl --output /dev/null --silent --head --fail "$url"
    updates+=( [$platform]="$result" )
done

sed -i "/^\s*version\s*=/ s|\".*\"|\"${first_version}\"|" "${DEFAULT_NIX_FILE}"

# Install updates
for platform in "${!updates[@]}"; do
  result=${updates[$platform]}

  version=$(echo ${result} | jq -r '.version')
  url=$(echo ${result} | jq -r '.downloadUrl')

  source=$(nix-prefetch-url "$url" --name "cursor-$version")
  hash=$(nix-hash --to-sri --type sha256 "$source")

  echo "Updating $platform to $version $url"

  sed -i "/${platform}\.url/ s|\".*\"|\"${url}\"|" "${DEFAULT_NIX_FILE}"
  sed -i "/${platform}\.hash/ s|\".*\"|\"${hash}\"|" "${DEFAULT_NIX_FILE}"
done
