#### bash-lib: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return
require-module interaction

### Files.

function realdir {
    local dir=$(dirname "$1")
    if pushd "$dir" > /dev/null 2>&1; then
        pwd
        popd > /dev/null
    else
        echo "$dir"
    fi
}

function realpath {
    echo "$(realdir "$1")/$(basename "$1")"
}

function command-available {
    which "$1" > /dev/null
}

function ensure-dir {
    local dir=$1
    test -d "$dir" || mkdir -p "$dir"
}

### Informed actions.

function informed-symlink {
    informed-step "Symlink $1 to $2${3:+ in $3}" ln -s "$1" "$2"
}

function informed-remove {
    informed-step "Remove symlink $1" rm "$1"
}
