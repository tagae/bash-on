#### bash-on: Reusable shell scripting code.

# This file does not contain a module on its own; rather, it is a
# platform-specific part of the module with the same name.

function -absolute-dirname {
    if pushd "$1" > /dev/null 2>&1; then
        pwd
        popd > /dev/null
    else
        echo "$1"
    fi
}

function -absolute-filename {
    echo "$(-absolute-dirname "$(dirname "$1")")/$(basename "$1")"
}
