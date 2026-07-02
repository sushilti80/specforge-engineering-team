#!/usr/bin/env bash
# Refresh ponytail skills from upstream (MIT) into the harness as real files.
# Usage: bash scripts/sync-ponytail.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UPSTREAM="https://github.com/DietrichGebert/ponytail.git"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Fetching ponytail from $UPSTREAM ..."
git clone --depth 1 --filter=blob:none --sparse "$UPSTREAM" "$TMP/ponytail"
git -C "$TMP/ponytail" sparse-checkout set skills .cursor/rules

COMMIT="$(git -C "$TMP/ponytail" rev-parse --short HEAD)"
VENDOR="$ROOT/vendor/ponytail"
rm -rf "$VENDOR"
mkdir -p "$VENDOR"

for skill in ponytail ponytail-review ponytail-audit ponytail-debt ponytail-gain ponytail-help; do
  rm -rf "$ROOT/skills/$skill"
  cp -R "$TMP/ponytail/skills/$skill" "$ROOT/skills/$skill"
  echo "  copied skills/$skill"
done

cp "$TMP/ponytail/.cursor/rules/ponytail.mdc" "$ROOT/rules/ponytail.mdc"
cp "$TMP/ponytail/.cursor/rules/ponytail.mdc" "$ROOT/templates/spec-driven-app/cursor-overlay/rules/ponytail.mdc"
echo "  copied rules/ponytail.mdc (+ template overlay)"

cp "$TMP/ponytail/LICENSE" "$VENDOR/LICENSE" 2>/dev/null || true
cat > "$VENDOR/SOURCE.md" <<EOF
# Ponytail (vendored)

Upstream: https://github.com/DietrichGebert/ponytail  
License: MIT (see \`LICENSE\`)  
Synced commit: \`$COMMIT\`

Refresh: \`bash scripts/sync-ponytail.sh\`

Harness copies (committed):
- \`skills/ponytail*\` — six skills
- \`rules/ponytail.mdc\` — Cursor always-on rule (plugin + bootstrap template)
EOF

echo "$COMMIT" > "$VENDOR/VERSION"
echo ""
echo "Ponytail sync complete (commit $COMMIT)."
echo "  Skills:  $ROOT/skills/ponytail*"
echo "  Rule:    $ROOT/rules/ponytail.mdc"
echo ""
echo "Re-run platform install to expose globally:"
echo "  bash scripts/install-all.sh"
echo ""
echo "Verify: skill spec-vendor-sync checklist"
