#### bash-on: Reusable shell scripting code.

# This file does not contain a module on its own; rather, it is a
# platform-specific part of the module with the same name.

function _readable-arg-name {
    # Unfortunately `tr` will also lowercase acronyms, for example
    # "printGNUVersion" results in "print gnu version".
    sed -E -e 's/([A-Z][a-z])/ \1/g' -e 's/([A-Z][A-Z]+)/ \1/g' <<<"$1" | \
        tr '[:upper:]' '[:lower:]'
}
