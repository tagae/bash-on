#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return
require-module interaction
require-module $(uname)/scripting

### Scripting colors.

if [ -t $messagesFD ]; then
    scriptingColor="$(tput setaf 5)"
fi

### Scripting labels.

scriptingLabel="[${scriptingColor}Scripting${termPlain}] "

### Scripting variables.

declare -i scriptingTraceLevel=0

### Scripting messages.

function scripting-error-message {
    # Retrieve caller information.
    local _ traceInfo calledFunc callerLine callerFile
    read _ calledFunc _ <<<$(caller $scriptingTraceLevel)
    read callerLine _ callerFile <<<$(caller $(($scriptingTraceLevel+1)))
    if [ -n "$callerFile" ]; then
        traceInfo="$callerFile"
        test -n "$callerLine" && traceInfo="$traceInfo line $callerLine"
        traceInfo="$traceInfo: "
    fi
    test -n "$calledFunc" && traceInfo="$traceInfo$calledFunc: "
    # Core functionality.
    error-message -l "$scriptingLabel$traceInfo" -e 1 "$@"
}

### Scripting utilities.

# required-arg <variable> [<description>]
#
# Issue an error if the given variable name is empty in the current
# environment.
#
# Unless an explicit <description> is given, the error message will
# report the given variable name split into different words according
# to CamelCase separation.
#
function required-arg {
    # Process arguments.
    # These local variable names must not exist in the caller's environment.
    local __argument="$1"; shift
    local __description="${1:-$(_readable-arg-name "$__argument")}"; shift
    remaining-args "$@"
    # Core functionality.
    if [ -n "$__argument" ]; then
        test -n "${!__argument}" || \
            scriptingTraceLevel=$(($scriptingTraceLevel+1)) scripting-error-message "Missing $__description"
    else
        required-arg argument # how meta :-P
    fi
}

function required-args {
    for arg in "$@"; do
        scriptingTraceLevel=$(($scriptingTraceLevel+1)) required-arg $arg
    done
}

function remaining-args {
    test $# -gt 0 && \
        IFS=, scriptingTraceLevel=$(($scriptingTraceLevel+1)) scripting-error-message "Unused arguments: $*"
}

function unknown-option {
    # Process arguments.
    local option="${1:-$OPTARG}"; shift
    required-arg option "option name"
    remaining-args "$@"
    # Core functionality.
    scriptingTraceLevel=$(($scriptingTraceLevel+1)) scripting-error-message "Unknown option: -$option"
}

function missing-option-argument {
    # Process arguments.
    local option="${1:-$OPTARG}"; shift
    required-arg option "option name"
    remaining-args "$@"
    # Core functionality.
    scriptingTraceLevel=$(($scriptingTraceLevel+1)) scripting-error-message "Option -$option: missing argument"
}
