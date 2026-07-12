# SpecForge Engineering Team v2.0.2

**Release date:** 2026-07-12  
**Type:** Patch (release signing + verify path)  
**Previous:** [v2.0.1](https://github.com/sushilti80/specforge-engineering-team/releases/tag/v2.0.1)

## Summary

Hardens the GitHub Release signing flow for CI and aligns `specforge.sh` verification with offline (non-Rekor) cosign signatures. Documents how consumers verify release artifacts.

## Changes

- **Release workflow:** `cosign sign-blob --yes --tlog-upload=false` so Actions is non-interactive (no Sigstore ToS prompt).
- **CLI verify:** `verify_cosign` uses `--insecure-ignore-tlog` with `SPECFORGE_COSIGN_PUBKEY` for key-based detached `.sig` files.
- **Docs:** README Option F — download from Releases, SHA256 + cosign verify examples; points at committed `cosign.pub`.

## Verify

```bash
export SPECFORGE_COSIGN_PUBKEY=/path/to/cosign.pub
cosign verify-blob --insecure-ignore-tlog --key "$SPECFORGE_COSIGN_PUBKEY" \
  --signature specforge-content-2.0.2.tar.gz.sig \
  specforge-content-2.0.2.tar.gz
```
