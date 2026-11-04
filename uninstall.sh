#!/bin/sh
# Remove what install.sh created. Skills it did not create are kept.
# Usage: sh uninstall.sh [--agents <list>] [--dry-run] [--home <dir>]
set -eu
HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
exec sh "$HERE/install.sh" --uninstall "$@"
