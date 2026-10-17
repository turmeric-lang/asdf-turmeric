# Shared helpers for the asdf-turmeric plugin.
#
# The plugin downloads release artifacts from
# https://github.com/turmeric-lang/turmeric and consumes the existing
# release contract:
#
#   - asset name:       turmeric-vX.Y.Z-<os>-<arch>.tar.gz
#   - checksum file:    sha256sums.txt  (combined; one line per asset)
#   - extracted layout: tur (binary), stdlib/, include/turi/*.h, libturi.a
#
# `tvm` consumes the same artifacts; see tvm/tvm.sh in the turmeric repo.

TURMERIC_REPO="${TURMERIC_REPO:-turmeric-lang/turmeric}"
TURMERIC_API_URL="${TURMERIC_API_URL:-https://api.github.com/repos/${TURMERIC_REPO}}"
TURMERIC_RELEASE_BASE="${TURMERIC_RELEASE_BASE:-https://github.com/${TURMERIC_REPO}/releases/download}"

# Resolve the <os>-<arch> target string the release workflow publishes.
turmeric_target() {
  local os arch
  case "$(uname -s)" in
    Linux)  os=linux ;;
    Darwin) os=macos ;;
    *) echo "asdf-turmeric: unsupported OS: $(uname -s)" >&2; return 1 ;;
  esac
  case "$(uname -m)" in
    x86_64|amd64)  arch=x86_64 ;;
    arm64|aarch64) arch=$([ "$os" = macos ] && echo arm64 || echo aarch64) ;;
    *) echo "asdf-turmeric: unsupported arch: $(uname -m)" >&2; return 1 ;;
  esac
  echo "${os}-${arch}"
}

turmeric_asset_name() {  # version (bare, no leading v), target
  echo "turmeric-v${1}-${2}.tar.gz"
}

turmeric_release_url() {  # version, target
  echo "${TURMERIC_RELEASE_BASE}/v${1}/$(turmeric_asset_name "$1" "$2")"
}

turmeric_sums_url() {  # version
  echo "${TURMERIC_RELEASE_BASE}/v${1}/sha256sums.txt"
}

turmeric_curl() {
  local args=(--fail --location --silent --show-error)
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    args+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
  fi
  curl "${args[@]}" "$@"
}

turmeric_download() {  # url, dest
  turmeric_curl -o "$2" "$1"
}

turmeric_sha256() {  # file -> prints hex digest
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    echo "asdf-turmeric: no sha256 tool found (need sha256sum or shasum)" >&2
    return 1
  fi
}

# Verify file against the combined sha256sums.txt contents passed on stdin.
# Args: file, asset-name. Returns 0 on match, 1 on mismatch, 2 if asset is
# absent from the sums file (caller decides whether absence is fatal).
turmeric_verify_from_sums() {
  local file="$1" asset="$2" want got
  want="$(grep -E "[[:space:]]\*?${asset}\$" | head -n1 | awk '{print $1}')"
  [ -n "$want" ] || return 2
  got="$(turmeric_sha256 "$file")" || return 1
  if [ "$want" != "$got" ]; then
    echo "asdf-turmeric: sha256 mismatch for $asset" >&2
    echo "  expected $want" >&2
    echo "  got      $got" >&2
    return 1
  fi
  return 0
}
