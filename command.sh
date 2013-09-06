#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

require-module usage
require-module file

### Commands.

# require-command [-d <description>] [-v <var>] [commands...]
#
# Verifies that at least one of the command alternatives exists.
#
# -v: Define <var> as the first found command alternative.
# -d: Command description, in case of error.
#
function require-command {
    eval "$(preamble)"
    for command in ${commands[@]}; do
        if [ "${command:1}" = "/" ]; then
            # Absolute command path given.
            [ -x "$command" ] || continue
        else
            # Relative command path given.
            command="$(which "$command")"
            [ $? -eq 0 ] || continue
        fi
        [ "${var+given}" ] && declare -g "$var"="$command"
        return
    done
    scripting-error "Missing ${description-command}"
}
