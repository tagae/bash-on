#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

require-module runtime
require-module usage

require-module $(uname)/files

### File names.

# absolute-dirname <name>
#
# Returns the absolute path of the given directory <name>.
#
function absolute-dirname {
    eval "$(preamble)"
    _absolute-dirname "$name"
}

# absolute-filename <name>
#
# Returns the absolute path of the given file <name>.
#
function absolute-filename {
    eval "$(preamble)"
    _absolute-filename "$name"
}

# absolute-path <path>
#
# Converts the given relative <path> into absolute.
#
function absolute-path {
    eval "$(preamble)"
    if  [ -d "$path" ]; then
        _absolute-dirname "$path"
    elif [ -e "$path" ]; then
        _absolute-filename "$path"
    fi
}

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
    eval "$(preamble)"
    local base="${options[b]-$PWD}"
    if [[ $(absolute-filename "$filename") =~ ^$base/(.+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        if [ "${options[c]-absent}" ]; then
            error-message "$filename does not reside in $base."
        else
            echo "$filename"
            return false
        fi
    fi
}

### Temporary files.

# temp-file [-c] [-p <prefix>] [-v <var>]
#
# Creates a temporary file and prints its file name.
# The file will be automatically deleted upon shell exit.
#
# -p: Use <prefix> instead of the default 'generic'.
# -c: Do not exit upon failure to create the file.
# -v: Assign to global variable <var> instead of printing.
#
function temp-file {
    # This function should not use the $(preamble) mechanism, because
    # it is used to test the 'usage' module itself.
    OPTIND=1
    while getopts :cp:v: opt; do
        case $opt in
            (c) local continue="$OPTARG";;
            (p) local prefix="$OPTARG";;
            (v) local var="$OPTARG";;
            (\?) unknown-option;;
            (:) missing-option-argument;;
        esac
    done
    shift $(($OPTIND-1))
    unused-arguments "$@"
    local file="$(mktemp -t "${prefix-$(split-camelcase -s - "${var-tempFile}")}")"
    if [ $? -eq 0 ]; then
        add-trap "rm '$file'" EXIT
        if [ "${var+given}" ]; then
            eval "declare -g $var='$file'"
        else
            echo "$file"
        fi
    elif [ "${continue-absent}" ]; then
        error-message "Could not create temporary file"
    else
        return $?
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
