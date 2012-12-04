#### bash-lib: Reusable shell scripting code.

# Avoid including this module twice, through other means than the
# module management code itself (bootstrapping measure).
[[ $(type -t require-module) =~ ^function$ ]] && return

### Scripting.

function remaining-args {
    true # no-op until redefined by 'scripting' module
}

function required-arg {
    true # no-op until redefined by 'scripting' module
}

### Modules.

if pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null; then
    modulesHome=$PWD
    popd > /dev/null
else
    exit 1
fi

function provide-module {
    local module="${1:-$(basename ${BASH_SOURCE[1]} .sh)}"; shift
    remaining-args "$@"
    local scriptId="bash_module_$module"
    # Return true if not loaded.
    [ -z "${!scriptId}" ] && declare "$scriptId"="$modulesHome/$module.sh"
}

function require-module {
    local module="$1"; shift
    required-arg module "module name"
    remaining-args "$@"
    source "$modulesHome/$module.sh"
}

require-module scripting # used internally (e.g. remaining-args)
