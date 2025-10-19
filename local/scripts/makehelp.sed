#n
###############################################################
##  makehelp.sed                                             ##
##                                                           ##
##  Auto-generates help text from a Makefile by looking for  ##
##  comments after the 'target:' lines, like so:             ##
##                                                           ##
##    target: deps  # builds target from deps                ##
##        recipe                                             ##
##                                                           ##
##  Usage:    sed -f help.sed Makefile                       ##
##  Author:   Kevin Ernst <ernstki -at- mail.uc.edu>         ##
##  Date:     11 Oct 2025                                    ##
##  License:  ISC                                            ##
###############################################################
1i\

/^TITLE/ {
    s/^TITLE.*=[[:space:]]*\(.*\)/\1/; h
    # bold underline
    s/\(.*\)/  \x1b[1m\x1b[4m\1\x1b[0m/p
    # alternatively, dashed underline, no ANSI color
    #s/^/  /p; g
    #s/./-/g; s/^/  /p
    a\

}

/^\(HOMEPAGE\|SOURCE\) *=/ {
    # store off the first letter of the variable name
    h; s/\(.\).*/\1/; x
    # lower case the rest and put the URL on its own line
    s/.\([^ ][^ ]*\) *= *\(.*\)/\1:\n      \2/
    y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/
    # get the first character back, append the rest, remove the internal newline
    x; s/\(.\).*/    \1/; G; s/\n//; p
    a\

}

# targets
/^[-_[:alnum:]][-_[:alnum:]]*:.*#  */ {
    /^help:/ i\
    Makefile targets:

    # save the target description for later
    h; s/\([^:]*\):.*# *\(.*\)/\2/; x
    # get the target name
    s/\([^:]*\):.*/\1/
    :a
    # add spaces to the right until the pattern is 14 characters long
    s/^.\{1,13\}$/ &/; ta
    # move the right padding to the left; print in ANSI bold blue
    s/\( *\)\(.*\)/      \x1b[34;1m\2\x1b[0m\1/
    # or, without ANSI colors
    #s/\( *\)\(.*\)/      \2\1/
    # restore the description and remove the embedded newline
    G; s/\n//; p
}

$ a\

