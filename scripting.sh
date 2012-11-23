#### bash-lib: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return
require-module interaction

### Scripting.

function remaining-args {
    test $# -gt 0 && IFS=, scripting-error-message "unused arguments: $*"
}

function unknown-option {
    option="$1"; shift
    remaining-args "$@"
    scripting-error-message "unknown option: -$option"
}

function missing-option-argument {
    option="$1"; shift
    remaining-args "$@"
    scripting-error-message "option -$option: missing argument"
}
