#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return
require-module interaction
require-module $(uname)/scripting

### Scripting interaction.

scriptingColor="$(tput setaf 5)"
scriptingLabel="[${scriptingColor}Scripting${termPlain}] "

function scripting-error-message {
    # Process options.
    local -i frame=1
    OPTIND=1
    while getopts :t: opt; do
        case $opt in
            (t) frame=$(($frame + $OPTARG));;
            (\?) unknown-option;;
            (:) missing-option-argument;;
        esac
    done
    shift $(($OPTIND-1))
    # Retrieve caller information.
    local callerLine callerFunc callerFile callerInfo
    read callerLine callerFunc callerFile <<< $(caller "$frame")
    if [ -n "$callerFile" ]; then
        callerInfo="$callerFile"
        test -n "$callerLine" && callerInfo="$callerInfo line $callerLine"
        callerInfo="$callerInfo: "
    fi
    test -n "$callerFunc" && callerInfo="$callerInfo$callerFunc: "
    # Core functionality.
    error-message -l "$scriptingLabel$callerInfo" -e 1 "$@"
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
            scripting-error-message -t 1 "Missing $__description"
    else
        required-arg argument # how meta :-P
    fi
}

function remaining-args {
    test $# -gt 0 && \
        IFS=, scripting-error-message -t 1 "Unused arguments: $*"
}

function unknown-option {
    # Process arguments.
    local option="${1:-$OPTARG}"; shift
    required-arg option "option name"
    remaining-args "$@"
    # Core functionality.
    scripting-error-message -t 1 "Unknown option: -$option"
}

function missing-option-argument {
    # Process arguments.
    local option="${1:-$OPTARG}"; shift
    required-arg option "option name"
    remaining-args "$@"
    # Core functionality.
    scripting-error-message -t 1 "Option -$option: missing argument"
}
