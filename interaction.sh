#### bash-on: Reusable shell scripting code.

# To test this module, try
# bash -c "source interaction.sh; show-sample-messages"

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return
require-module colors

### Configuration.

messagesFD=2 # error file descriptor by default

### Main interaction colors.

if [ -t $messagesFD ]; then
    # Define only if output is to a terminal.
    plainColor="${termPlain}"
    highlightColor="${termBold}"
    emphasisColor="${termBold}"
    if [ -n "$TERM" ]; then
        errorColor="$(tput setaf 1)"
        successColor="$(tput setaf 2)"
        warnColor="$(tput setaf 3)"
        stepColor="$(tput setaf 4)"
        metaColor="$(tput setaf 5)"
        debugColor="$(tput setaf 6)"
        infoColor="$(tput setaf 7)"
    fi
fi

### Derived interaction colors.

if [ -t $messagesFD ]; then
    # Define only if output is to a terminal.
    warnColor="${warnColor}${highlightColor}" # redefine
    errorColor="${errorColor}${highlightColor}" # redefine
    noticeColor="${infoColor}${emphasisColor}"
fi

### Main interaction labels.

debugLabel="[${debugColor}Debug${plainColor}] "
infoLabel="[${infoColor}Info${plainColor}] "
noticeLabel="[${noticeColor}Notice${plainColor}] "
warningLabel="[${warnColor}Warn${plainColor}] "
errorLabel="[${errorColor}Error${plainColor}] "
stepLabel="[${stepColor}Step${plainColor}] "
successLabel="[${successColor}OK${plainColor}] "

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
}

function debug-message {
    generic-message -l "${debugLabel}" "$@"
}

function info-message {
    generic-message -l "${infoLabel}" "$@"
}

function notice-message {
    generic-message -l "${noticeLabel}" "$@"
}

function warning-message {
    generic-message -l "${warningLabel}" -p "Continue?" -e 1 "$@"
}

function error-message {
    generic-message -l "${errorLabel}" -e 1 "$@"
}

function success-message {
    generic-message -l "${successLabel}" "$@"
}

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

function yesno-message {
    local answer prompt="$1"; shift
    remaining-args "$@"
    while [[ ! "$answer" =~ ^(y|yes|n|no)$ ]]; do
        [ -n "$answer" ] && warning "Valid answers are: yes y no n"
        read -p "$prompt" answer
        answer=$(tr '[:upper:]' '[:lower:]' <<<"$answer")
    done
    [[ "$answer" =~ ^(y|yes)$ ]]
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
