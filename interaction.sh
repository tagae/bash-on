#### bash-on: Reusable shell scripting code.

# To test this module, try
# bash -c "source interaction.sh; show-sample-messages"

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return
require-module colors

### Configuration.

declare -ig messagesFD=2 # error file descriptor by default

### Main interaction colors.

plainColor="${termPlain}"
highlightColor="${termBold}"
emphasisColor="${termBold}"

if [ -t $messagesFD ]; then
    # Define only if output is to a terminal.
    errorColor="$(tput setaf 1)"
    successColor="$(tput setaf 2)"
    warnColor="$(tput setaf 3)"
    stepColor="$(tput setaf 4)"
    metaColor="$(tput setaf 5)"
    debugColor="$(tput setaf 6)"
    infoColor="$(tput setaf 7)"
fi

### Derived interaction colors.

warnColor="${warnColor}${highlightColor}" # redefine
errorColor="${errorColor}${highlightColor}" # redefine
noticeColor="${infoColor}${emphasisColor}"

### Main interaction labels.

debugLabel="[${debugColor}Debug${plainColor}] "
infoLabel="[${infoColor}Info${plainColor}] "
noticeLabel="[${noticeColor}Notice${plainColor}] "
warningLabel="[${warnColor}Warn${plainColor}] "
errorLabel="[${errorColor}Error${plainColor}] "
stepLabel="[${stepColor}Step${plainColor}] "
successLabel="[${successColor}OK${plainColor}] "

### Message levels.

declare -Ag messageLevelPriority=(
    # Extra levels can be added dynamically if needed.
    [interact]=0
    [error]=1
    [warning]=2
    [notice]=3
    [info]=4
    [trace]=5
    [debug]=6
)

declare -g currentMessageLevel=info maxMessageLevel=info

### Interaction messages.

function generic-message {
    local label prompt attrs keepline continue=false emptylines=false
    local -i exitCode
    OPTIND=1
    while getopts :l:p:e:bcnk opt; do
        case $opt in
            (l) label="$label$OPTARG";;
            (p) prompt="$OPTARG";;
            (e) exitCode="$OPTARG";;
            (b) attrs="$attrs$highlightColor";;
            (c) continue=true;;
            (n) emptylines=true;;
            (k) keepline="-n";;
            (\?) unknown-option;;
            (:)
                case $OPTARG in
                    (e)
                        exitCode=0;;
                    (*)
                        missing-option-argument;;
                esac;;
        esac
    done
    shift $(($OPTIND-1))
    if [ "$exitCode" -o \
            ${messageLevelPriority[$currentMessageLevel]} -le \
                ${messageLevelPriority[${maxMessageLevel}]} ]; then
        while (( $# > 0 )); do
            { test -n "$1" || "$emptylines"; } && \
                echo $keepline "${label}${attrs}$1" >&$messagesFD
            shift
        done
        if $continue; then
            true
        else
            if [ -n "$prompt" ]; then
                yesno-message "${label}${prompt} (y/n) " || {
                    test "$exitCode" && exit $exitCode
                }
            else
                test "$exitCode" && exit $exitCode
                true
            fi
        fi
    else
        false
    fi
}

function yesno-message {
    local prompt="$1"; shift
    local answer
    while [[ ! "$answer" =~ ^(y|yes|n|no)$ ]]; do
        [ -n "$answer" ] && warning-message -c "Valid answers are: yes y no n"
        read -p "$prompt" answer
        answer=$(tr '[:upper:]' '[:lower:]' <<<"$answer")
    done
    [[ "$answer" =~ ^(y|yes)$ ]]
}

function debug-message {
    currentMessageLevel=debug generic-message -l "${debugLabel}" "$@"
}

function info-message {
    currentMessageLevel=info generic-message -l "${infoLabel}" "$@"
}

function notice-message {
    currentMessageLevel=notice generic-message -l "${noticeLabel}" "$@"
}

function warning-message {
    currentMessageLevel=warning generic-message -l "${warningLabel}" -p "Continue?" -e 1 "$@"
}

function error-message {
    currentMessageLevel=error generic-message -l "${errorLabel}" -e 1 "$@"
}

function success-message {
    currentMessageLevel=info generic-message -l "${successLabel}" "$@"
}

### Steps.

function step-message {
    generic-message -l "${stepLabel}" -p "Proceed?" "$@"
}

interactiveSteps=false

function informed-step {
    local message="$1"; shift
    { if $interactiveSteps; then step-message "$message"; else true; fi } && \
        "$@" && { $interactiveSteps || success-message "$message"; }
}

### Testing.

function show-sample-messages {
    generic-message "This is a generic interaction message."
    debug-message "This is a debugging message."
    info-message "This is an informational message."
    info-message -b "This is a highlighted informational message."
    notice-message "This is a notice message."
    warning-message -c "This is a warning message."
    error-message -c "This is an error message."
    step-message -c "This is a step message."
    success-message "This is a success message."
}
