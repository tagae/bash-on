#### bash-on: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

### Numbers.

# See http://en.wikipedia.org/wiki/English_numerals

# cardinal <number>
#
function cardinal {
    local -i number="${1-$(missing-argument "number")}" && shift
    unused-arguments "$@"
    local -A cardinals=(
        [0]=zero
        [1]=one
        [2]=two
        [3]=three
        [4]=four
        [5]=five
        [6]=six
        [7]=seven
        [8]=eight
        [9]=nine
        [10]=ten
        [11]=eleven
        [12]=twelve
        [13]=thirteen
        [15]=fifteen
        [18]=eighteen
        [20]=twenty
        [30]=thirty
        [40]=forty
        [50]=fifty
        [80]=eighty
        [100]=hundred
        [1000]=thousand
    )
    (( number < 0 )) && echo -n "minus " && (( number=-number ))
    [ ${cardinals[$number]+defined} ] && echo ${cardinals[$number]} && return
    (( number < 20 )) && echo ${cardinals[$((number%10))]}teen && return
    (( number < 100 && number % 10 == 0 )) && \
        echo $(cardinal $((number/10)))ty && return
    (( number < 100 )) && \
        echo $(cardinal $((number-number%10)))-$(cardinal $((number%10))) && \
        return
    (( number < 1000 )) && \
        echo $(cardinal $((number/100))) hundred\ $(cardinal $((number%100))) \
        && return
    error-message "Cardinals above 1000 not implemented yet"
}

# ordinal <number>
#
function ordinal {
    local -i number="${1-$(missing-argument "number")}" && shift
    unused-arguments "$@"
    local -A ordinals=(
        [1]=first
        [2]=second
        [3]=third
        [5]=fifth
        [8]=eighth
        [9]=ninth
        [12]=twelfth
        [100]=hundredth
    )
    (( number < 0 )) && error-message "Ordinals are never negative"
    [ ${ordinals[$number]+defined} ] && echo ${ordinals[$number]} && return
    (( number < 20 )) && echo $(cardinal $number)th && return
    (( number < 100 && number % 10 == 0 )) && \
        local cardinal=$(cardinal $number) && echo ${cardinal/ty/tieth} && return
    (( number < 100 )) && echo \
        $(cardinal $((number-number%10)))-$(ordinal $((number%10))) && return
    error-message "Ordinals above 100 not implemented yet"
}

### String utilities.

function trim {
    local var="$@"
    var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace
    var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace
    echo -n "$var"
}

# split-camelcase [-s <separator>] [words...]
function split-camelcase {
    OPTIND=1
    while getopts :s: opt; do
        case $opt in
            (s) local separator="$OPTARG";;
            (\?) unknown-option;;
            (:) missing-option-argument;;
        esac
    done
    shift $((OPTIND-1))
    while (($# > 0)); do
        sed -E \
            -e 's/([A-Z][a-z])/ \1/g' \
            -e 's/([A-Z][A-Z]+)/ \1/g' <<<"$1" \
            | { IFS=" "; read -a words;
                IFS="${separator- }"; echo "${words[*],}"; }
        shift
    done
}

function camelcase-join {
    [ $# -eq 0 ] && read -a words && set -- ${words[*]}
    local origIFS="$IFS"; IFS=""; echo "${*^}"; IFS="$origIFS"
}
