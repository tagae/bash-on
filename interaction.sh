#### bash-on: Reusable shell scripting code.

# To test this module, try
# bash -c "source interaction.sh; show-sample-messages"

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return
require-module colors
require-module arrays

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

declare -Ag messageLevel
messageLevel[interact]=0
messageLevel[error]=1
messageLevel[warning]=2
messageLevel[notice]=3
messageLevel[info]=4
messageLevel[debug]=5

declare -ag maxMessageLevel

function push-message-level {
    local level="$1"; shift
    required-arg level
    remaining-args "$@"
    array-push maxMessageLevel ${messageLevel[$level]}
}

function restore-message-level {
    local _
    array-pop maxMessageLevel _
}

push-message-level info # default level

declare -ig currentMessageLevel=${maxMessageLevel[0]}

### Interaction messages.

function generic-message {
    local label prompt exitCode attrs continue=false
    OPTIND=1
    while getopts :l:p:e:bc opt; do
        case $opt in
            (l) label="$label$OPTARG";;
            (p) prompt="$OPTARG";;
            (e) exitCode="$OPTARG";;
            (b) attrs="$attrs$highlightColor";;
            (c) continue=true;;
            (\?) unknown-option "$OPTARG";;
            (:)
                case $OPTARG in
                    (e)
                        exitCode=0;;
                    (*)
                        missing-option-argument;;
                esac
                ;;
        esac
    done
    shift $(($OPTIND-1))
    # User input (-p) forces output irrespective of current message level.
    if [ -n "$prompt" -o $currentMessageLevel -le ${maxMessageLevel[0]} ]; then
        while test $# -gt 0; do
            echo "${label}${attrs}$1" >&$messagesFD
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
    required-arg prompt
    remaining-args "$@"
    local answer
    while [[ ! "$answer" =~ ^(y|yes|n|no)$ ]]; do
        [ -n "$answer" ] && warning-message -c "Valid answers are: yes y no n"
        read -p "$prompt" answer
        answer=$(tr '[:upper:]' '[:lower:]' <<<"$answer")
    done
    [[ "$answer" =~ ^(y|yes)$ ]]
}

function debug-message {
    currentMessageLevel=${messageLevel[debug]} generic-message -l "${debugLabel}" "$@"
}

function info-message {
    currentMessageLevel=${messageLevel[info]} generic-message -l "${infoLabel}" "$@"
}

function notice-message {
    currentMessageLevel=${messageLevel[notice]} generic-message -l "${noticeLabel}" "$@"
}

function warning-message {
    currentMessageLevel=${messageLevel[warning]} generic-message -l "${warningLabel}" -p "Continue?" -e 1 "$@"
}

function error-message {
    currentMessageLevel=${messageLevel[error]} generic-message -l "${errorLabel}" -e 1 "$@"
}

function success-message {
    currentMessageLevel=${messageLevel[info]} generic-message -l "${successLabel}" "$@"
}

### Steps.

function step-message {
    generic-message -l "${stepLabel}" -p "Proceed?" "$@"
}

interactiveSteps=false

function informed-step {
    local message="$1"; shift
    remaining-args "$@"
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
