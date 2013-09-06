#### bash-on: Reusable shell scripting code.

# TODO:
#
# - Handling of spurious (unrecognized) signature elements.

# LIMITATIONS
#
# - Default option values cannot contain single quotes.
#
# - Option arguments are simply assigned to an associative
#   array. Hence, there is no way of handling multiple occurrences of
#   a same option (perhaps with different arguments each).

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

require-module text

### Usage declarations.

# usage
#
# Reads a sequence of usage specifications from standard input, each
# separated by a line consisting solely of the $usageEndMarker.
#
function usage {
    eval "$(usage-parse)"
}

function usage-parse {
    unused-arguments "$@"
    awk 'BEGIN{RS=""}{if(NR==1){print"usage-signature<<\"END\"\n"$0}if(NR==2){print"END\nusage-purpose<<\"END\"\n"$0};if(NR==3){print"END\nusage-description<<\"END\"\n"$0;RS="\n\n"};if(NR>3){print$0}}END{print"END";if(NR>0){print"\nusage-end;"}}'
}

function usage-signature {
    unused-arguments "$@"
    eval "$(usage-parse-signature)"
}

function usage-parse-signature {
    unused-arguments "$@"
    local opt='\[ *([^]=]+)(=([^]]*))? *\]'
    local req='< *([^>]+) *>'
    local sw='-([^[:space:]])'
    sed -E \
      -e "s/ *([^[<{ ]+)/ signature-begin '\1';/" \
      -e "s/\[ *$sw *\]/ signature-option '\1';/g" \
      -e "s/\[ *$sw *$req *\]/ signature-option '\1' '\2';/g" \
      -e "s/\[ *$sw *$opt *\]/ signature-option '\1' '\2' '\4';/g" \
      -e "s/\[ *([^].]+)\.\.\. *\]/ signature-remaining '\1';/g" \
      -e "s/$opt/ signature-argument '\1' '\3';/g" \
      -e "s/$req/ signature-argument '\1';/g"
}

function usage-purpose {
    unused-arguments "$@"
    signature-open
    commandPurpose["$signatureName"]="$(cat)"
}

function usage-description {
    unused-arguments "$@"
    signature-open
    commandDescription["$signatureName"]="$(cat)"
}

function usage-end {
    signature-end
}

### Command signatures.

declare -g signatureName argumentCode optionValueCode
declare -gA signatureOptions

declare -gA commandPreamble commandPurpose commandDescription

# signature-begin <command name>
#
# Declares the beginning of a command signature specification.
#
function signature-begin {
    signatureName="${1:-$(missing-argument "command name")}"; shift
    unused-arguments "$@"
    commandPreamble["$signatureName"]=""
    commandPurpose["$signatureName"]=""
}

# signature-open
#
# Tests whether a signature is currently being defined.
#
function signature-open {
    unused-arguments "$@"
    [ -n "$signatureName" ] || scripting-error "Not defining any signature"
}

# signature-option <name> [argument] [value]
#
# Declares a command option, which can optionally have an argument and
# a default value.
#
function signature-option {
    local name="$(trim ${1-$(missing-argument "name")})" && shift
    [ "${1+given}" ] && local argument="$(trim "$1")" && shift
    [ "${1+given}" ] && local value="$1" && shift
    unused-arguments "$@"
    signature-open
    signatureOptions["$name"]="$argument"
    if [ "${value+given}" ]; then
        optionValueCode+="[\"$name\"]=\"${value/\"/\\\"}\""
    fi
}

# signature-argument <name> [value]
#
# Declares a positional argument.
# If a default value is specified, it means the argument is optional.
#
function signature-argument {
    local name="$(trim ${1-$(missing-argument "name")})"; shift
    [ "${1+given}" ] && local value="$1" && shift
    unused-arguments "$@"
    signature-open
    [ -z "$value" ] && argumentCode+='[ "${1+given}" ] && '
    argumentCode+="local $(make-varname $name)="
    if [ "${value+given}" ]; then
        if [ -n "$value" ]; then
            argumentCode+='"${1-'"${value/\"/\\\"}"'}"'
        else
            argumentCode+='"$1"'
        fi
    else
        argumentCode+='"${1-$(missing-argument "'"$name"'")}"'
    fi
    argumentCode+=';shift;'
}

# signature-remaining <name>
#
# Declares a tail of zero or more positional arguments.
#
function signature-remaining {
    local name="$(trim ${1-$(missing-argument "name")})"; shift
    unused-arguments "$@"
    signature-open
    local name="$(make-varname $name)"
    #echo "while (( \$# > 0 )); do $name+=("\$1"); shift; done"
    argumentCode+="declare -a $name=("'$@);shift $#;'
}

# signature-end
#
# Finishes a command signature specification.
#
function signature-end {
    unused-arguments "$@"
    signature-open
    local optionCode="local -A options=();"
    [ "${optionValueCode:+nonempty}" ] && \
        optionCode+="local -A defaults=($optionValueCode);"
    if (( ${#signatureOptions[*]} > 0 )); then
        local optstring
        for name in ${!signatureOptions[*]}; do
            optstring+="$name${signatureOptions[$name]:+:}"
        done
        optionCode+='OPTIND=1;'
        optionCode+='while getopts :'"$optstring"' opt; do '
        optionCode+='case $opt in '
        optionCode+='(\?) unknown-option;;'
        optionCode+='(:) options[$OPTARG]="${defaults[$OPTARG]-missing-option-argument}";;'
        optionCode+='(*) options[$opt]="$OPTARG";;'
        optionCode+='esac;'
        optionCode+='done;'
        optionCode+='shift $((OPTIND-1));'
    fi
    argumentCode+='unused-arguments "$@"'
    commandPreamble["$signatureName"]+="$optionCode$argumentCode"
    signatureName=""
    argumentCode=""
    optionArgumentCode=""
    optionValueCode=""
    signatureOptions=()
}

### Execution support.

# preamble
#
# Prints the preamble code associated to the calling command.
#
function preamble {
    local callerName
    read _ callerName _ <<<"$(caller 0)"
    echo "${commandPreamble[$callerName]:-load-signature && eval \"\${commandPreamble[$callerName]:-undefined-signature\}\"}"
}

# load-signature [name] [file] [line]
#
# Retrieves the documented signature of the specified function.
#
function load-signature {
    local name="$1"; shift
    local file="$1"; shift
    local -i line="$1"; shift
    [ -z "$name" ] && read line name file <<<"$(caller 0)"
    usage <<<"$(comment-signature "$name" "$file" "$line")"
}

# comment-signature <name> [file] [line]
#
# Reads the signature corresponding to the function with the given
# <name>. If the function has already been loaded, there is no need to
# specify the <source> file. The <line> argument is just a hint to
# speed things slightly.
#
function comment-signature {
    local name="${1:-$(missing-argument "function name")}"; shift
    local file="$1"; shift
    local -i line="${1:-0}"; shift
    unused-arguments "$@"
    if [ -z "$file" ]; then
        if declare -f "$name" > /dev/null; then
            local shoptState="$(shopt -p extdebug)"
            shopt -s extdebug
            read _ line file <<<"$(declare -F "$name")"
            eval "$shoptState"
            [ -e "$file" ] || \
                error-message "Could not determine source of function '$name'"
        else
            error-message \
                "Cannot determine source of undefined function '$name'." \
                "Either define it or pass the source file name explicitly."
        fi
    fi
    local hsp="[ \t]*"
    local nocmt="\n$hsp([^#\n].*)?\n"
    local cmt="[^#\n]*#$hsp"
    local pre="$nocmt($cmt\n)*"
    local sig="$cmt$name.*\n"
    local rest="($cmt.*\n)*"
    local post="(?=\s*function\s+$name[ ({])"
    { echo; head -n "$line" "$file"; } \
        | grep -Poz "$pre$sig$rest$post" \
        | sed -E -n "s/^[^#\n]*#(.*)/\1/p"
}

# undefined-signature
#
# Signals an error due to an undefined signature.
#
function undefined-signature {
    scripting-error -d 0 "Unknown command signature"
}

### Command documentation.

# command-purpose <name>
#
# Prints the documented purpose of the command with the given <name>.
#
function command-purpose {
    local name="${1:-$(missing-argument "name")}"; shift
    unused-arguments "$@"
    [ "${commandPurpose[$name]-undefined}" ] && load-signature "$name"
    echo "${commandPurpose[$name]}"
}

# command-description <name>
#
# Prints the additional description of the command with the given <name>.
#
function command-description {
    local name="${1:-$(missing-argument "name")}"; shift
    unused-arguments "$@"
    [ "${commandDescription[$name]-undefined}" ] && load-signature "$name"
    echo "${commandDescription[$name]}"
}
