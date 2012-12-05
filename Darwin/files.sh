#### bash-on: Reusable shell scripting code.

# This is not a module on its own.
# This is the Darwin-specific part of the 'files' module.

function absolute-dirname {
    local dirname=$(dirname "$1"); shift
    required-arg dirname "directory name"
    remaining-args "$@"
    if pushd "$dirname" > /dev/null 2>&1; then
        pwd
        popd > /dev/null
    else
        echo "$dirname"
    fi
}

function absolute-filename {
    local filename="$1"; shift
    required-arg filename "file name"
    remaining-args "$@"
    echo "$(absolute-dirname "$filename")/$(basename "$filename")"
}
