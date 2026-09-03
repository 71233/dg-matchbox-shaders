#!/usr/bin/env bash
# DIGITAL GARDEN Matchbox installer (Rocky Linux + macOS)
# Installs encrypted .mx packages into Flame preset Matchbox folders.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_SHADERS="${DG_DIST_SHADERS:-$ROOT/dist/shaders}"
MANIFEST="${DG_MANIFEST:-$ROOT/dist/manifest.json}"
# Flame versions below this are skipped (2025.2.7 feature set → 2025.1+).
MIN_VERSION="${DG_MIN_FLAME_VERSION:-2025.1.0}"
DRY_RUN=0
VENDOR_DIR="DG"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--dry-run] [--min-version X.Y.Z] [--dist-shaders DIR]

Install DIGITAL GARDEN encrypted Matchbox .mx files into:
  /opt/Autodesk/presets/<version>/matchbox/shaders/${VENDOR_DIR}/

Options:
  --dry-run          Print actions without copying
  --min-version VER  Skip presets older than VER (default: ${MIN_VERSION})
  --dist-shaders DIR Source directory of .mx files
  -h, --help         Show this help

Environment:
  DG_MIN_FLAME_VERSION  Same as --min-version
  DG_DIST_SHADERS       Same as --dist-shaders
EOF
}

log() { printf '%s\n' "$*"; }
err() { printf 'error: %s\n' "$*" >&2; }

version_ge() {
  # Return 0 if $1 >= $2 (numeric dotted versions, missing parts = 0).
  local a="$1" b="$2"
  local IFS=.
  # shellcheck disable=SC2206
  local -a aa=($a) bb=($b)
  local i ai bi
  for i in 0 1 2 3; do
    ai="${aa[$i]:-0}"
    bi="${bb[$i]:-0}"
    ai="${ai%%[!0-9]*}"
    bi="${bi%%[!0-9]*}"
    ai="${ai:-0}"
    bi="${bi:-0}"
    if ((10#$ai > 10#$bi)); then return 0; fi
    if ((10#$ai < 10#$bi)); then return 1; fi
  done
  return 0
}

extract_version() {
  # From a presets path segment like "2025.2.7" or "flame_2025.2.7".
  local name="$1"
  if [[ "$name" =~ (20[0-9]{2}(\.[0-9]+){0,3}) ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --min-version) MIN_VERSION="${2:?}"; shift 2 ;;
    --dist-shaders) DIST_SHADERS="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) err "unknown option: $1"; usage; exit 2 ;;
  esac
done

if [[ ! -d "$DIST_SHADERS" ]]; then
  err "dist shaders directory not found: $DIST_SHADERS"
  exit 1
fi

shopt -s nullglob
mx_files=("$DIST_SHADERS"/*.mx)
if [[ ${#mx_files[@]} -eq 0 ]]; then
  err "no .mx files in $DIST_SHADERS"
  err "publish validated packages to dist/shaders/ before installing"
  exit 1
fi

presets_root="/opt/Autodesk/presets"
if [[ ! -d "$presets_root" ]]; then
  err "Flame presets root not found: $presets_root"
  exit 1
fi

log "DIGITAL GARDEN Matchbox installer"
log "  source:      $DIST_SHADERS (${#mx_files[@]} .mx)"
log "  min version: $MIN_VERSION"
log "  manifest:    $MANIFEST"
[[ -f "$MANIFEST" ]] || log "  (manifest missing — installing all .mx files)"
[[ "$DRY_RUN" -eq 1 ]] && log "  mode:        dry-run"

installed_targets=0
skipped_targets=0

for preset_dir in "$presets_root"/*; do
  [[ -d "$preset_dir" ]] || continue
  base="$(basename "$preset_dir")"
  ver="$(extract_version "$base" || true)"
  if [[ -z "${ver:-}" ]]; then
    log "skip (no version): $preset_dir"
    skipped_targets=$((skipped_targets + 1))
    continue
  fi
  if ! version_ge "$ver" "$MIN_VERSION"; then
    log "skip (< $MIN_VERSION): $preset_dir ($ver)"
    skipped_targets=$((skipped_targets + 1))
    continue
  fi

  matchbox_shaders="$preset_dir/matchbox/shaders"
  if [[ ! -d "$matchbox_shaders" ]]; then
    log "skip (no matchbox/shaders): $preset_dir"
    skipped_targets=$((skipped_targets + 1))
    continue
  fi

  dest="$matchbox_shaders/$VENDOR_DIR"
  log "install → $dest"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    for f in "${mx_files[@]}"; do
      log "  would copy $(basename "$f")"
    done
    installed_targets=$((installed_targets + 1))
    continue
  fi

  if [[ ! -w "$matchbox_shaders" ]] && [[ ! -w "$dest" ]]; then
    if [[ ! -d "$dest" ]]; then
      err "cannot create $dest (permission denied). Re-run as a user that can write Flame presets."
      exit 1
    fi
  fi

  mkdir -p "$dest" || {
    err "failed to create $dest"
    exit 1
  }

  for f in "${mx_files[@]}"; do
    name="$(basename "$f")"
    # Remove conflicting older loose files for the same shader stem (mx-only policy).
    stem="${name%.mx}"
    for old in "$dest/$stem" "$dest/$stem".*; do
      [[ -e "$old" ]] || continue
      [[ "$old" == "$dest/$name" ]] && continue
      rm -f "$old" || {
        err "failed removing conflict: $old"
        exit 1
      }
    done
    cp -f "$f" "$dest/$name" || {
      err "failed copying $name → $dest"
      exit 1
    }
    log "  copied $name"
  done
  installed_targets=$((installed_targets + 1))
done

log "done. targets updated: $installed_targets, skipped: $skipped_targets"
if [[ "$installed_targets" -eq 0 ]]; then
  err "no eligible Flame preset directories were updated"
  exit 1
fi
