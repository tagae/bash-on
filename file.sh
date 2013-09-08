#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

require-module runtime
require-module usage
require-module text

require-module $(uname)/files

### File names.

# absolute-dirname <name>
#
# Returns the absolute path of the given directory <name>.
#
function absolute-dirname {
    eval "$(preamble)"
    -absolute-dirname "$name"
}

# absolute-filename <name>
#
# Returns the absolute path of the given file <name>.
#
function absolute-filename {
    eval "$(preamble)"
    -absolute-filename "$name"
}

# absolute-path <path>
#
# Converts the given relative <path> into absolute.
#
function absolute-path {
    eval "$(preamble)"
    if  [ -d "$path" ]; then
        -absolute-dirname "$path"
    elif [ -e "$path" ]; then
        -absolute-filename "$path"
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

### File properties.

# file-size <name>
#
# Echoes the size of the file with the given <name>.
#
function file-size {
    eval "$(preamble)"
    -file-size "$name"
}

# require-file [-v] <name>
#
# Checks whether a file exists.
#
# -v: Interpret <name> as a variable name.
#
function require-file {
    eval "$(preamble)"
    if [ "${options[v]+given}" ]; then
        [ -e "${!name}" ] || error-message \
            "Missing $(split-camelcase "$name") file"
    else
        [ -e "${name}" ] || error-message "Missing file: $name"
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
# -d: Create a directory instead of a file.
#
function temp-file {
    # This function should not use the $(preamble) mechanism, because
    # it is used to test the 'usage' module itself.
    OPTIND=1
    while getopts :cp:v:d opt; do
        case $opt in
            (c) local continue="$OPTARG";;
            (p) local prefix="$OPTARG";;
            (v) local var="$OPTARG";;
            (d) local diropt="-d";;
            (\?) unknown-option;;
            (:) missing-option-argument;;
        esac
    done
    shift $(($OPTIND-1))
    unused-arguments "$@"
    local file="$(mktemp $diropt -t "${prefix-$(split-camelcase -s - "${var-tempFile}")}")"
    if [ $? -eq 0 ]; then
        add-trap "debug-message 'Removing $file'; rm -r '$file'" EXIT
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

### File operations.

# wipe-file <target>
#
# Zeroes and removes the file with the given name.
#
function wipe-file {
    eval "$(preamble)"
    if [ -e "$target" ]; then
        local log="$(mktemp -t "dd-log")"
        for (( i=0; i < 5; i++ )); do
            dd if=/dev/zero of="$target" \
                count=1 bs=$(file-size "$target") 2>"${log:-&2}"
            if [ $? -ne 0 ]; then
                warning-message "Failed to zero $target${log:+:$'\n'$(cat "$log")}"
                break
            fi
        done
        rm -f "$target" "$log"
    fi
}

function files-symlink {
    local source="$1"; shift
    local target="$1"; shift
    required-arg source
    required-arg target
    remaining-args "$@"

    informed-step "Symlink $1 to $2${3:+ in $3}" ln -s "$1" "$2"
}

function files-remove {
    informed-step "Remove symlink $1" rm "$1"
}

function ensure-dir {
    local directory="$1"; shift
    required-arg directory
    remaining-args "$@"
    test -d "$directory" || mkdir -p "$directory"
}
