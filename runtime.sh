#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

require-module interaction
require-module usage

### Signal traps.

# add-trap [-p] <code> <signal>
#
# The `trap' builtin overwrites the current trap command.
# This function overcomes this limitation.
#
# Note that traps are inherited by subshells, such as those created by
# $(command substitutions). Hence, a subshell will add the given trap
# _on top of already existing traps from the parent_. In particular,
# an EXIT trap will be executed twice: when the subshell finishes, and
# again when the parent finishes.
#
function add-trap {
    local p=false
    OPTIND=1
    while getopts :p opt; do
        case $opt in
            (p) p=true;;
            (\?) unknown-option;;
            (:) missing-option-argument;;
        esac
    done
    shift $((OPTIND-1))
    local code="${1:-$(missing-argument "code")}"; shift
    local signal="${1:-$(missing-argument "signal")}"; shift
    unused-arguments "$@"
    local append prepend sep
    if $p; then
        prepend="$code"
    else
        append="$code"
    fi
    local current="$(eval "third-argument $(trap -p "${signal}")")"
    [ "${current:+${prepend:+nonempty}}" ] && sep=$'\n'
    [ "${current:+${append:+nonempty}}" ] && sep=$'\n'
    trap -- "$prepend$sep$current$sep$append" "$signal" \
        || error-message "Unable to set trap for signal ${signal}"
}
