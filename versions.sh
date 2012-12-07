#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

### Versions.

function flat-version-number {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d", $1,$2,$3,$4); }';
}

function major-version-number {
    echo "$@" | awk -F. '{ print $1 }';
}

function minor-version-number {
    echo "$@.0" | awk -F. '{ print $2 }';
}

function revision-number {
    echo "$@.0.0" | awk -F. '{ print $3 }';
}
