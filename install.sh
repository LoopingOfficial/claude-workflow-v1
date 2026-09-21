#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SOURCE_DIR="$ROOT_DIR/.claude/commands"

usage() {
  cat <<'EOF'
Usage:
  ./install.sh --global
  ./install.sh --project /path/to/project

Options:
  --global          Install commands into ~/.claude/commands
  --project PATH    Install commands into PATH/.claude/commands
  -h, --help        Show this help
EOF
}

if [ "$#" -eq 0 ]; then
  usage
  exit 2
fi

case "$1" in
  --global)
    [ "$#" -eq 1 ] || { usage; exit 2; }
    DEST_DIR="$HOME/.claude/commands"
    ;;
  --project)
    [ "$#" -eq 2 ] || { usage; exit 2; }
    DEST_DIR="$2/.claude/commands"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

for file in audit.md spec.md build.md review.md architect.md; do
  [ -f "$SOURCE_DIR/$file" ] || {
    echo "Missing source command: $SOURCE_DIR/$file" >&2
    exit 1
  }
done

mkdir -p "$DEST_DIR"

for file in audit.md spec.md build.md review.md architect.md; do
  cp "$SOURCE_DIR/$file" "$DEST_DIR/$file"
done

echo "Installed Claude Code workflow commands in: $DEST_DIR"
