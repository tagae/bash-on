#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return
require-module interaction
load-module $(uname)/files

### File names.

# relative-filename [-c] [-b <base>] <filename>
#
# Prints <filename> relative to directory <base>.
#
# If <base> is omitted, it is assumed to be the current directory.
#
# If <filename> is not under the <base> hierarchy, print an error
# message and exit with a failure.
#
# With -c, print <filename> without modification, and return false
# (rather than exiting).
#
function relative-filename {
    # Process options.
    local base="$PWD" fail=true
    OPTIND=1
    while getopts :b:c opt; do
        case $opt in
            (b) base="$OPTARG";;
            (c) fail=false;;
            (\?) unknown-option;;
            (:) missing-option-argument;;
        esac
    done
    shift $(($OPTIND-1))
    # Process arguments.
    local filename="$1"; shift
    required-arg filename "file name"
    remaining-args "$@"
    # Relativise filename.
    if [[ $(absolute-filename "$filename") =~ ^$base/(.+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        if $fail; then
            error-message "$filename does not reside in $base."
        else
            echo "$filename"
            return false
        fi
    fi
}

### Commands.

function command-available {
    # Process options.
    local command="$1"; shift
    required-arg command
    remaining-args "$@"
    which "$command" > /dev/null
}

function ensure-dir {
    local directory="$1"; shift
    required-arg directory
    remaining-args "$@"
    test -d "$directory" || mkdir -p "$directory"
}

### Informed actions.

function informed-symlink {
    local source="$1"; shift
    local target="$1"; shift
    required-arg source
    required-arg target
    remaining-args "$@"

    informed-step "Symlink $1 to $2${3:+ in $3}" ln -s "$1" "$2"
}

function informed-remove {
    informed-step "Remove symlink $1" rm "$1"
}
