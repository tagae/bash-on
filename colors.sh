#### bash-lib: Reusable shell scripting code.

### Module preamble.

source "$(dirname "${BASH_SOURCE[0]}")/modules.sh"
provide-module || return

### Display modifiers.

if [ -n "$TERM" ]; then
    termUnderline=$(tput sgr 0 1)
    termBold=$(tput bold)
    termStrong=$(tput smso)
    termPlain=$(tput sgr0)
fi

# See http://linuxtidbits.wordpress.com/2008/08/11/output-color-on-bash-scripts/

function show-term-colors {
    for i in $(seq 1 7); do
        echo \
            "$(tput setaf $i)Text$termPlain" \
            "$termBold$(tput setaf $i)Text$termPlain" \
            "$termUnderline$(tput setaf $i)Text$termPlain" \
            "\$(tput setaf $i)"
    done
}
