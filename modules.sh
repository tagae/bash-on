#### bash-lib: Reusable shell scripting code.

# Avoid including this module twice, through other means than the
# module management code itself.
type -t require-module | egrep -q 'function' && return

### Modules.

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null
modulesHome=$PWD
popd > /dev/null

function remaining-args {
    true # no-op until redefined by 'scripting' module
}

function provide-module {
    module=$1; shift
    remaining-args $@
    test -n "$module" || module=$(basename ${BASH_SOURCE[1]} .sh)
    local scriptId=bash_module_$module
    # Return true if not loaded.
    test -z "${!scriptId}" && export "$scriptId"=$modulesHome/$module.sh
}

function require-module {
    module=$1; shift
    remaining-args $@
    source "$modulesHome/$module.sh"
}

require-module scripting # used internally (e.g. remaining-args)
