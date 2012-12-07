#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return
require-module versions

#### Platform.

function fail-if-bash-older-than {
    local minVersion="$1"; shift
    required-arg minVersion "minimum Bash version"
    remaining-args "$@"
    if [ -n "$BASH_VERSION" ]; then
        debug-message "Running on bash $BASH_VERSION"
        local bashFlatVersion=$(flat-version-number $BASH_VERSION)
        local minFlatVersion=$(flat-version-number $minVersion)
        [ "$bashFlatVersion" -lt "$minFlatVersion" ] && \
            error-message "Bash is too old (expected ${minVersion}+)"
    else
        error-message "Not running under Bash"
    fi
}

## Debian.

function debian-version {
    remaining-args "$@"
    [ -r /etc/debian_version ] && major-version-number `cat /etc/debian_version`
}
