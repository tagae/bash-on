#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

require-module files

### Testing colors.

if [ -t $messagesFD ]; then
    testingColor="$(tput setaf 7)$termBold"
    failColor="$(tput setaf 1)"
    successColor="$(tput setaf 2)"
fi

### Testing messages.

declare -g testingLabel="[${testingColor}Testing${termPlain}] "
declare -g testFailLabel="[${failColor}Fail${termPlain}] "
declare -g testSuccessLabel="[${successColor}OK${termPlain}] "

function testing-message {
    generic-message -l "$testingLabel" "$@"
}

function testing-progress {
    generic-message "$@"
}

### Testing results.

temp-file -v testingResults
temp-file -v testingActualOutput
temp-file -v testingExpectedOutput

# testing-success
#
function testing-success {
    unused-arguments "$@"
    testing-progress -k "$successColor.$termPlain"
    printf "testing-success-report\n" >> "$testingResults"
}

# testing-failure [messages...]
#
function testing-failure {
    testing-progress -k "$failColor.$termPlain"
    local line file
    read line _ file <<<"$(caller 1)"
    while (( $# > 0 )); do
        printf "testing-failure-report '$file' '$line' <<'END'\n%s\nEND\n" "$1" >> "$testingResults"
        shift
    done
}

# testing-success-report
#
function testing-success-report {
    unused-arguments "$@"
}

# testing-failure-report <file> <line>
#
function testing-failure-report {
    local file="${1:-$(missing-argument "file")}"; shift
    local -i line="${1:-$(missing-argument "line")}"; shift
    unused-arguments "$@"
    testing-message -l "$testFailLabel" "At line $line of $file" "$(cat)"
}

### Testing framework.

declare -g testSuite

# test-suite <name>
#
function test-suite {
    local name="${1:-$(missing-argument "name")}"; shift
    unused-arguments "$@"
    test-suite-end
    testSuite="$name"
    testingSuccessCount=0
    testingFailureCount=0
    echo > "$testingResults"
    testing-message -k "$name: "
}

# test-suite-end
function test-suite-end {
    unused-arguments "$@"
    [ -n "$testSuite" ] || return
    unset testSuite
    local -i successes="$(grep testing-success-report < "$testingResults" | wc -l)"
    local -i failures="$(grep testing-failure-report < "$testingResults" | wc -l)"
    testing-progress " ($successes successes, $failures failures)"
    source "$testingResults"
}

add-trap -p 'test-suite-end; info-message "Done testing."' EXIT

### Testing assertions.

# outputs <expected>
#
# Checks whether the content from standard input matches the given argument.
#
function outputs {
    local strict=false
    OPTIND=1
    while getopts :s opt; do
        case $opt in
            (s) strict=true;;
            (\?) unknown-option;;
            (:) missing-option-argument;;
        esac
    done
    shift $(($OPTIND-1))
    local expected="${1-$(missing-argument "expected")}"; shift
    unused-arguments "$@"
    if $strict; then
        cat > "$testingActualOutput"
        echo -n "$expected" > "$testingExpectedOutput"
        local differences="$(diff -a --strip-trailing-cr "$testingActualOutput" "$testingExpectedOutput")"
        if [ -z "$differences" ]; then
            testing-success
        else
            local expectedLabel="${successColor}Expected: ${termPlain}"
            local differenceLabel="${failColor}Difference: ${termPlain}"
            testing-failure "$expectedLabel$expected" "$differenceLabel$differences"
        fi
    else
        local actual="$(cat)"
        if [ "$expected" = "$actual" ]; then
            testing-success
        else
            local expectedLabel="${successColor}Expected: ${termPlain}"
            local actualLabel="${failColor}Actual: ${termPlain}"
            testing-failure "$expectedLabel$expected" "$actualLabel$actual"
        fi
    fi
}

# test-num-equal <actual> <expected>
#
# Checks whether <actual> is numerically equal to <expected>.
#
function test-num-equal {
    local actual="${1-$(missing-argument "actual")}"; shift
    local expected="${1-$(missing-argument "expected")}"; shift
    unused-arguments "$@"
    if (( actual == expected )); then
        testing-success
    else
        testing-failure "Expected: $expected" "Actual: $actual"
    fi
}
