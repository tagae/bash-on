#### bash-on: Reusable shell scripting code.

# This is not a module on its own.
# This is the Linux-specific part of the 'files' module.

function absolute-dirname {
    local dirname=$(dirname "$1"); shift
    required-arg dirname "directory name"
    remaining-args "$@"
    absolute-filename "$dirname"
}

function absolute-filename {
    local filename="$1"; shift
    required-arg filename "file name"
    remaining-args "$@"
    readlink -m "$filename"
}
