#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

require-module file
require-module text

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

temp-file -v testingActualOutput
temp-file -v testingExpectedOutput
temp-file -v testingMessages
temp-file -v testingCounters

declare -gi testingSuccessCount=0 testingFailureCount=0

# testing-success
#
function testing-success {
    unused-arguments "$@"
    testing-progress -k "$successColor.$termPlain"
    echo '(( testingSuccessCount++ ))' >> "$testingCounters"
}

# testing-failure [messages...]
#
function testing-failure {
    testing-progress -k "$failColor.$termPlain"
    local line file
    read line _ file <<<"$(caller 1)"
    echo "testing-source-report '$file' '$line'" >> "$testingMessages"
    while (( $# > 0 )); do
        printf "testing-failure-report <<'END'\n%s\nEND\n" "$1" \
            >> "$testingMessages"
        shift
    done
    echo '(( testingFailureCount++ ))' >> "$testingCounters"
}

# testing-failure-report
#
function testing-failure-report {
    unused-arguments "$@"
    testing-message -l "$testFailLabel" "$(cat)"
}

# testing-source-report <file> <line>
#
function testing-source-report {
    local file="${1:-$(missing-argument "file")}"; shift
    local -i line="${1:-$(missing-argument "line")}"; shift
    unused-arguments "$@"
    testing-message "At line $line of $file"
}

### Testing framework.

# test-suite <name>
#
function test-suite {
    local name="${1:-$(missing-argument "name")}"; shift
    unused-arguments "$@"
    test-suite-end
    declare -g testSuite="$name"
    testing-message -k "$name: "
}

# test-suite-end
function test-suite-end {
    unused-arguments "$@"
    [ -n "$testSuite" ] || return
    source "$testingCounters"
    testing-progress " ($(countable-noun $testingSuccessCount success), $(countable-noun $testingFailureCount failure))"
    source "$testingMessages"
    debug-message "Finished suite: $testSuite"
    unset testSuite
    echo > "$testingCounters"
    echo > "$testingMessages"
    testingSuccessCount=0
    testingFailureCount=0
}

add-trap -p 'test-suite-end' EXIT

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
