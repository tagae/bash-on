#### bash-on: Reusable shell scripting code.

# For testing purposes, try
# bash -c "source colors.sh; show-term-colors"

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

### Display modifiers.

if [ -t 1 -o -t 2 ]; then
    termUnderline=$(tput sgr 0 1)
    termBold=$(tput bold)
    termStrong=$(tput smso)
    termPlain=$(tput sgr0)
fi

# See http://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/

function show-term-colors {
    echo "\$term...         Plain  Bold   Underline"
    for i in $(seq 1 7); do
        printf "\$(tput setaf $i)"
        printf "$(tput setaf $i)%6s$termPlain" "Text"
        printf "$termBold$(tput setaf $i)%7s$termPlain" "Text"
        printf "%3s$termUnderline$(tput setaf $i)%s$termPlain\n" "" "Text"
    done
}
