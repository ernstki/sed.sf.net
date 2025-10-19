#!/bin/bash
# htmlize.sh - by Aurelio Jargas, since 2002
#
# Use sedsed to convert sed scripts to colored HTML files.
# The original sed script URL is also added to the HTML footer.
#
# Usage: ./htmlize.sh path/to/script.sed

url_database="index2html.sed"
output_extension="html"

declare -A unsupported=(
    [local/games/sedermind.sed]="invalid SED command 'Q' at line 84 (unsupported by sedsed)"
    [local/scripts/html2iso.sed]="sed: RE error: illegal byte sequence"
    [local/scripts/html_lc.sed]="sed: RE error: illegal byte sequence"
    [local/scripts/html_uc.sed]="sed: RE error: illegal byte sequence"
    [local/scripts/indexhtml.sed]="can't handle linefeed as delimiter (unsupported by sedsed)"
    [local/scripts/iso2html.sed]="sed: RE error: illegal byte sequence"
    [local/scripts/makehelp.sed]="improper conversion of {a,i}\\ syntax (sedsed bug?)"
    [local/scripts/sodelnum.sed]="sed: RE error: illegal byte sequence"
    [local/scripts/untroff.sed]="sed: RE error: illegal byte sequence"
)

get_script_url() {
	local label="$1"

	# Label exceptions: displayed script name is different from the file name
	case "$label" in
		hanoi           ) label='towers of hanoi';;
		tictactoe       ) label='tic tac toe';;
		pong1player     ) label='pong (1 player)';;
		pong2players    ) label='pong (2 players)';;
		99-green-bottles) label='99 green bottles';;
		sedermind       ) label='my mastermind';;
		path            ) label='path solver';;
	esac

	# Extract sed script URL from the database
	sed -n '
		# Sample line: s|^foo.sed$|http://sed.sf.net/foo.sed|; t url
		/^s|^'"$label"'\(\.sed\)\{0,1\}\$|/ {
			s///
			s/|.*//
            h
		}
        /^s|^homepage\$|/ {
            # Trim any extra slashes, and append a final one
            s/^s|^homepage\$|\(.*\)\/*|.*/\1\//
            x
            # Prepend the homepage URL for local scripts (relative paths)
            /^http/! {
                H; g; s/\n//
            }
            p
        }
		' "$url_database"
}


message() {
    local c1=10
    local c2=50
    if [[ $# -lt 2 ]]; then set -- INFO "${1:?message() needs an argument}"; fi
    printf "%-${c1}s %-${c2}s %s\n" "[$1]" "$2" "${3:-}"
}
skipped() { message SKIPPED "$@" >&2; }
saved()   { message SAVED "$@"; }
error()   { message ERROR "$@"; exit 1; }


main() (
    (( TRACE )) && set -x
    set -euo pipefail

    while (( $# ))
    do
        input_path="$1"
        output_path="$input_path".$output_extension
        # Remove the current file name from the to-do list
        shift

        # Get the script URL
        input_basename=$(basename "$input_path" .sed)
        url=$(get_script_url "$input_basename")
        if [[ -z $url ]]; then
            error "No URL found for script '$input_basename'"
        fi

	    # Skip this script if it's unsupported
        reason=${unsupported[$input_path]:-}
        if [[ $reason ]]; then
            skipped "Unsupported script '$input_basename'" "reason: $reason"
            continue
        fi

        # Convert to HTML and add original URL to the footer
        if ! sedsed --htmlize -f "$input_path" |
            sed "/>### colorized by/ s,</b>,\\
### original script: <a href=\"$url\">$url</a>&," > "$output_path"
        then
            error "Error htmlizing '$input_path'" "→ $url"
        fi

        saved "htmlized '$input_path'" "→ $output_path"
    done
)

# run 'main' unless sourced ($0 is '-bash' when sourced)
if [[ $0 == "$BASH_SOURCE" ]]; then main "${@}"; fi

