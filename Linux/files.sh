#### bash-on: Reusable shell scripting code.

# This file does not contain a module on its own; rather, it is a
# platform-specific part of the module with the same name.

function -absolute-dirname {
    dirname "$(_absolute-filename "$1")"
}

function -absolute-filename {
    readlink -m "$1"
}
