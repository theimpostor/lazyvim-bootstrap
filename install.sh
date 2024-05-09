#!/usr/bin/env bash

set -o errexit -o errtrace -o pipefail -o nounset
function warn() {
    >&2 echo "$@"
}

function die() {
    local ec=$?; if (( ec == 0 )); then ec=1; fi
    warn "$@"; warn "died. backtrace:"
    local frame=0; while caller $frame; do ((++frame)); done
    exit $ec
}
trap die ERR

function usage() {
    cat <<EOF
Usage: $0 [options] [--] <DEST_DIR>

Install neovim + lazyvim to <DEST_DIR>

<DEST_DIR> must not exist.

options:
    --help, -h
        Print this message
    --debug, -d
        Enable debug tracing
    --
        Stop parsing options
EOF
}

# MAIN
while (($#)); do
    case $1 in
        --help|-h) usage; exit 0
            ;;
        --debug|-d) set -o xtrace
            ;;
        --) shift; break
            ;;
        -*) warn "Unrecognized argument: $1"; exit 1
            ;;
        *) break
            ;;
    esac; shift
done

# MAIN

DEST_DIR=$1; shift

[[ -e "$DEST_DIR" ]] && die "Destination directory already exists: $DEST_DIR"

mkdir -p "$DEST_DIR/.config"
mkdir -p "$DEST_DIR/.local/share"
mkdir -p "$DEST_DIR/.local/state"
mkdir -p "$DEST_DIR/.cache"
mkdir -p "$DEST_DIR/bin"

case $(uname -s) in
    Darwin)
        NVIM_PKG=nvim-macos
        ;;
    Linux)
        NVIM_PKG=nvim-linux64
        ;;
    *)
        die "Unsupported platform"
        ;;
esac

curl -fsSL https://github.com/neovim/neovim/releases/download/stable/$NVIM_PKG.tar.gz | tar xzfC - "$DEST_DIR/.local"
 
cat > "$DEST_DIR/bin/nvim" <<EOF
#!/usr/bin/env bash

export XDG_CONFIG_HOME="$DEST_DIR/.config"
export XDG_DATA_HOME="$DEST_DIR/.local/share"
export XDG_STATE_HOME="$DEST_DIR/.local/state"
export XDG_CACHE_HOME="$DEST_DIR/.cache"

exec "$DEST_DIR/.local/$NVIM_PKG/bin/nvim" "\$@"
EOF

chmod +x "$DEST_DIR/bin/nvim"

# vim:ft=bash:sw=4:ts=4:expandtab
