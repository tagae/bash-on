#### bash-on: Reusable shell scripting code.

# Avoid including this module twice through other means than the
# module management code itself. This is a bootstrapping measure.
[ "$(type -t require-module)" = "function" ] && return

### Scripting

# The following are bootstrapping versions redefined later on by the
# 'scripting' module.

function scripting-error {
    while (( $# > 0 )); do echo "$1" >&2; shift; done
    exit 1
}

function unused-arguments {
    (( $# > 0 )) && scripting-error "Unused arguments"
}

function missing-argument {
    scripting-error "Missing argument"
}

### Modules.

(( BASH_VERSINFO[0] < 4 )) && scripting-error "Error: Bash 4+ required."

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null \
    || scripting-error "Could not determine modules base directory"
modulesBase=$PWD
popd > /dev/null

function provide-module {
    local module="${1:-$(basename ${BASH_SOURCE[1]} .sh)}"; shift
    unused-arguments "$@"
    local scriptId=_${module}_module
    scriptId=${scriptId//[^[:alnum:]_]/_} # make valid variable name
    # Return true if not loaded.
    [ -z "${!scriptId}" ] && declare -rg "$scriptId"="$modulesBase/$module.sh"
}

function require-module {
    local module="${1:-$(missing-argument "module")}"; shift
    unused-arguments "$@"
    if [ ! -e "$modulesBase/$module.sh" ]; then
        scripting-error "Module '$module' not found"
    fi
    source "$modulesBase/$module.sh"
}

provide-module # declare this module as provided
require-module scripting # used internally (e.g. unused-arguments)
