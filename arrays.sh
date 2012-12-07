#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

### Arrays.

function array-push {
    local arrayName="$1"; shift
    required-arg arrayName
    while [ $# -gt 0 ]; do
        local element="$1"; shift
        eval "$arrayName=(\"$element\" \"\${$arrayName[@]}\")"
    done
}

function array-pop {
    local arrayName="$1"; shift
    required-arg arrayName
    local resultName
    while [ $# -gt 0 ]; do
        resultName="$1"; shift
        if test -n "$resultName"; then
            eval "$resultName=\${$arrayName[0]}"
        fi
        eval "$arrayName=(\"\${$arrayName[@]:1}\")"
    done
}
