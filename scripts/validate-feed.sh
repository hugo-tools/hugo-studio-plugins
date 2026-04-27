#!/usr/bin/env bash
# Validate the marketplace JSON feed: required fields, types, semver
# shape, known extension points, plausible URLs.
#
# Builds the site fresh (no caching of stale output), then walks
# `public/plugins/index.json` with jq. Exits non-zero on the first
# pluginthat fails so CI gives a useful error instead of a wall of
# noise.

set -euo pipefail

SITE_DIR="${SITE_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
HUGO="${HUGO:-hugo}"

cd "$SITE_DIR"

if ! command -v "$HUGO" >/dev/null 2>&1; then
  echo "error: hugo binary not on PATH (set HUGO=...)" >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq not on PATH" >&2
  exit 2
fi

echo "==> building site (clean)"
rm -rf public
"$HUGO" --minify --gc --quiet

FEED="public/plugins/index.json"
if [[ ! -f "$FEED" ]]; then
  echo "error: $FEED not produced by hugo build" >&2
  exit 1
fi

echo "==> validating $FEED"

# Whole-feed envelope.
FEED_VERSION=$(jq -r '.feedVersion // empty' "$FEED")
if [[ "$FEED_VERSION" != "1" ]]; then
  echo "error: unsupported feedVersion '$FEED_VERSION' (expected 1)" >&2
  exit 1
fi
if [[ "$(jq -r '.plugins | type' "$FEED")" != "array" ]]; then
  echo "error: .plugins must be an array" >&2
  exit 1
fi

# Per-plugin checks. Use jq's `--arg/--argjson` to keep the validator
# in one place and bash readable.
ERRORS=0
KNOWN_EXTENSION_POINTS='["panel","fieldRenderer","dataFormat","shortcode"]'
SEMVER_RE='^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.-]+)?$'
URL_RE='^https?://'

COUNT=$(jq '.plugins | length' "$FEED")
echo "    found $COUNT plugin(s)"

for i in $(seq 0 $((COUNT - 1))); do
  PLUGIN=$(jq -c ".plugins[$i]" "$FEED")
  NAME=$(jq -r '.name // empty' <<<"$PLUGIN")
  : "${NAME:=<#$i>}"

  fail() {
    echo "  ✗ $NAME: $1" >&2
    ERRORS=$((ERRORS + 1))
  }

  for field in name title version author repo installUrl extensionPoints minStudioVersion detailUrl; do
    if [[ "$(jq -r --arg f "$field" '.[$f] // empty' <<<"$PLUGIN")" == "" ]]; then
      fail "missing required field '$field'"
    fi
  done

  VERSION=$(jq -r '.version // ""' <<<"$PLUGIN")
  [[ "$VERSION" =~ $SEMVER_RE ]] || fail "version '$VERSION' is not semver"

  MIN=$(jq -r '.minStudioVersion // ""' <<<"$PLUGIN")
  [[ "$MIN" =~ $SEMVER_RE ]] || fail "minStudioVersion '$MIN' is not semver"

  REPO=$(jq -r '.repo // ""' <<<"$PLUGIN")
  [[ "$REPO" =~ $URL_RE ]] || fail "repo '$REPO' does not look like a URL"

  INSTALL_URL=$(jq -r '.installUrl // ""' <<<"$PLUGIN")
  [[ "$INSTALL_URL" =~ $URL_RE ]] || fail "installUrl '$INSTALL_URL' does not look like a URL"

  if [[ "$(jq -r '.extensionPoints | type' <<<"$PLUGIN")" != "array" ]]; then
    fail "extensionPoints must be an array"
  else
    if [[ "$(jq -r '.extensionPoints | length' <<<"$PLUGIN")" == "0" ]]; then
      fail "extensionPoints is empty (declare at least one)"
    fi
    UNKNOWN=$(jq -r --argjson known "$KNOWN_EXTENSION_POINTS" \
      '.extensionPoints - $known | join(",")' <<<"$PLUGIN")
    if [[ -n "$UNKNOWN" ]]; then
      fail "unknown extensionPoint(s): $UNKNOWN (allowed: $(jq -r 'join(",")' <<<"$KNOWN_EXTENSION_POINTS"))"
    fi
  fi

  if [[ "$ERRORS" == "0" ]]; then
    echo "  ✓ $NAME ($VERSION)"
  fi
done

if [[ "$ERRORS" -gt 0 ]]; then
  echo "==> validation failed with $ERRORS error(s)" >&2
  exit 1
fi

echo "==> $COUNT plugin(s) ok"
