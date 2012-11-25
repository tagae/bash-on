#### bash-lib: Reusable shell scripting code.

# To test this module, try
# bash -c "source interaction.sh; show-sample-messages; show-term-colors"

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return
require-module colors

### Main colors.

debugColor=$(tput setaf 6)
infoColor=$(tput setaf 7)
noticeColor=$(tput setaf 7)
warnColor=$(tput setaf 3)
errorColor=${termBold}$(tput setaf 1)
stepColor=$(tput setaf 4)
internalColor=$(tput setaf 5)
successColor=$(tput setaf 2)

highlightColor=$(tput setaf 7)

### Main labels.

debugLabel="[${debugColor}Debug${termPlain}] "
infoLabel="[${infoColor}Info${termPlain}] "
noticeLabel="[${termUnderline}${noticeColor}Notice${termPlain}] "
warningLabel="[${warnColor}Warn${termPlain}] "
errorLabel="[${errorColor}Error${termPlain}] "
stepLabel="[${stepColor}Step${termPlain}] "
internalLabel="[${internalColor}Internal${termPlain}] "
successLabel="[${successColor}OK${termPlain}] "

### Generic messages.

function generic-message {
    local label prompt exit="false" attrs continue=false
    OPTIND=1
    while getopts :l:p:e:bc opt; do
        case $opt in
            (l) label="$label$OPTARG";;
            (p) prompt="$OPTARG";;
            (e) exit="exit $OPTARG";;
            (b) attrs="$attrs$termBold";;
            (c) continue=true;;
            (\?) unknown-option "$OPTARG";;
            (:) missing-option-argument "$OPTARG";;
        esac
    done
    shift $(($OPTIND-1))
    while test $# -gt 0; do
        echo "${label}${attrs}$1" >&2
        shift
    done
    if $continue; then
        true
    else
        if [ -n "$prompt" ]; then
            yesno-message "${label}${prompt} (y/n) " || $exit
        else
            $exit || true
        fi
    fi
}

### Messages.

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

function scripting-error-message {
    error-message -l "${internalLabel}" -e 1 "$@"
}

function success-message {
    generic-message -l "${successLabel}" "$@"
}

function step-message {
    generic-message -l "${stepLabel}" -p "Proceed?" "$@"
}

interactiveSteps=false

function informed-step {
    message="$1"; shift
    { if $interactiveSteps; then step-message "$message"; else true; fi } && \
        "$@" && \
            { $interactiveSteps || success-message "$message"; }
}

function yesno-message {
    local answer prompt="$1"; shift
    remaining-args "$@"
    while [[ ! "$answer" =~ ^(y|yes|n|no)$ ]]; do
        [ -n "$answer" ] && warning "Valid answers are: yes y no n"
        read -p "$prompt" answer
        answer=$(tr '[:upper:]' '[:lower:]' <<<"$answer")
    done
    [[ $answer =~ ^(y|yes)$ ]]
}

### Testing.

function show-sample-messages {
    generic-message "This is a generic message."
    debug-message "This is a debugging message."
    info-message "This is an informational message."
    info-message -b "This is a highlighted informational message."
    notice-message "This is a notice message."
    warning-message -c "This is a warning message."
    error-message -c "This is an error message."
    step-message -c "This is an step message."
    scripting-error-message -c "This is an scripting error message."
    success-message "This is a success message."
}
