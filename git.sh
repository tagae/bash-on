#### bash-lib: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return
require-module interaction

### Git utilities

## Query

function git-is-repo {
    # Process options.
    OPTIND=1
    while getopts :f opt; do
        case $opt in
            (f) fail=true;;
            (\?) unknown-option "$OPTARG";;
            (:) missing-option-argument "$OPTARG";;
        esac
    done
    shift $(($OPTIND-1))
    # Check branch.
    remaining-args "$@"
    git rev-parse > /dev/null 2>&1 || {
        $fail && error-message "$PWD is not under version control"
    }
}

function git-is-current-branch {
    # Process options.
    OPTIND=1
    while getopts :f opt; do
        case $opt in
            (f) fail=true;;
            (\?) unknown-option "$OPTARG";;
            (:) missing-option-argument "$OPTARG";;
        esac
    done
    shift $(($OPTIND-1))
    # Check branch.
    branch="$1"; shift
    remaining-args "$@"
    test "$(git-current-branch)" = "refs/heads/$branch" || {
        $fail && error-message "Current branch in $PWD is not $branch"
    }
}

function git-committed-files {
    id="${1:-HEAD}"; shift
    remaining-args "$@"
    git diff-tree -r --name-only --no-commit-id "$id"
}

function git-current-branch {
    remaining-args "$@"
    git symbolic-ref HEAD 2>/dev/null
}
