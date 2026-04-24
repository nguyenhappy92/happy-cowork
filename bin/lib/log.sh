#!/usr/bin/env bash
# Structured logging for cowork. All logs go to stderr so stdout
# stays clean for pipelines.

if [[ -t 2 ]]; then
  COWORK_C_G=$'\033[1;32m'
  COWORK_C_Y=$'\033[1;33m'
  COWORK_C_R=$'\033[1;31m'
  COWORK_C_B=$'\033[1;34m'
  COWORK_C_DIM=$'\033[2m'
  COWORK_C_X=$'\033[0m'
else
  COWORK_C_G="" COWORK_C_Y="" COWORK_C_R="" COWORK_C_B="" COWORK_C_DIM="" COWORK_C_X=""
fi

cowork::log()  { printf '%s==>%s %s\n' "$COWORK_C_G" "$COWORK_C_X" "$*" >&2; }
cowork::info() { printf '%s-->%s %s\n' "$COWORK_C_B" "$COWORK_C_X" "$*" >&2; }
cowork::warn() { printf '%s!!%s  %s\n' "$COWORK_C_Y" "$COWORK_C_X" "$*" >&2; }
cowork::die()  { printf '%sxx%s  %s\n' "$COWORK_C_R" "$COWORK_C_X" "$*" >&2; exit 1; }
cowork::dim()  { printf '%s%s%s\n'     "$COWORK_C_DIM" "$*" "$COWORK_C_X" >&2; }
