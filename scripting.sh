#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

require-module interaction
require-module text

### Scripting colors.

if [ -t $messagesFD ]; then
    scriptingColor="$(tput setaf 5)"
fi

### Scripting variables.

declare -ig scriptingMetaLevel=0

### Scripting messages.

declare -g scriptingLabel="[${scriptingColor}Scripting${termPlain}] "

function scripting-error {
    (( scriptingMetaLevel++ ))
    # Process options.
    local -i delta=1
    OPTIND=1
    while getopts :d: opt; do
        case $opt in
            (d) delta="$OPTARG";;
            (\?) ((OPTIND--)); break;; # pass on to error-message
            (:) missing-option-argument;;
        esac
    done
    shift $((OPTIND-1))
    # Retrieve caller information.
    local _ traceInfo calledFunc callerLine callerFile
    read _ calledFunc _ <<<$(caller $scriptingMetaLevel)
    read callerLine _ callerFile <<<$(caller $(($scriptingMetaLevel+$delta)))
    if [ -n "$callerFile" ]; then
        traceInfo="$callerFile"
        [ -n "$callerLine" ] && traceInfo="$traceInfo line $callerLine"
        traceInfo="$traceInfo: "
    fi
    [ -n "$calledFunc" ] && \
        [ "$calledFunc" != "main" ] && \
            traceInfo="$traceInfo$calledFunc: "
    # Core functionality.
    error-message -l "$scriptingLabel$traceInfo" -e 1 "$@"
    (( scriptingMetaLevel-- ))
}

### Argument handling.

# unused-arguments [arguments...]
#
# Raises an error if unprocessed arguments remain.
#
function unused-arguments {
    (( scriptingMetaLevel++ ))
    (( $# == 0 )) || scripting-error "Unexpected argument${2+s}: $*"
    (( scriptingMetaLevel-- ))
}

# missing-argument <description>
#
# Rasies an error due to a missing argument.
#
function missing-argument {
    (( scriptingMetaLevel++ ))
    local description="$1"; shift
    unused-arguments "$@"
    scripting-error "Missing $description"
    (( scriptingMetaLevel-- ))
}

# Define projector functions that simply echo their nth argument.
for ((i = 0; i < 10; i++ )); do
    eval "function $(ordinal $i)-argument { printf '%s' \"\$$i\"; }"
done

### Option handling.

declare -gA options

# unknown-option [option name]
#
# Reports an unknown command option.
#
function unknown-option {
    (( scriptingMetaLevel++ ))
    local optionName="${1:-$OPTARG}"; shift
    unused-arguments "$@"
    scripting-error "Unknown option -$optionName"
    (( scriptingMetaLevel-- ))
}

# missing-option-argument [option name]
#
# Reports a missing argument for a command option.
#
function missing-option-argument {
    (( scriptingMetaLevel++ ))
    local optionName="${1:-$OPTARG}"; shift
    unused-arguments "$@"
    scripting-error "Missing argument for option -$optionName"
    (( scriptingMetaLevel-- ))
}

### Meta.

function make-varname {
    local first="$1"; shift
    echo "$first$(camelcase-join "$@")"
}
