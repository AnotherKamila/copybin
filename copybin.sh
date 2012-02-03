#!/bin/bash

# copybin.sh -- a ssh pastebin without the "paste"
# see http://github.com/anotherkamila/copybin

CONFIG_FILE="$HOME/.config/copybinrc"
# defaults
VERBOSE=0
PASSWDPROTECT=0

usage() { # {{{
cat << EOF
usage: $0 options file(s)

Copy files using scp, creating neat pastebin-like HTML along the way

OPTIONS/TODOs:
  -h		Shows this message
  -p USER:PASS	password-protect the file with HTTP basic auth (.htpasswd)
		(not implemented yet)
  -p USER	password-protect the file with HTTP basic auth (.htpasswd),
		USER must already be present in the existing .htpasswd file
		(not implemented yet)
  -d		password-protect the file with HTTP basic auth (.htpasswd),
		using the default USER and PASS from the config file
  -r		rebuild all HTML documents (use after changing templates)
		(not implemented yet)
  -v		Verbose
		(not implemented yet)
EOF
} # }}}

# options parsing
while getopts ":hc:p:drv" OPTION; do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		p)
			PASSWDPROTECT=1
			USER=${OPTARG%:*}
			if [[ $OPTARG == *:* ]]; then PASS=${OPTARG#*:}; else PASS=''; fi
			;;
		d)
			PASSWDPROTECT=1
			;;
		r)
			echo "TODO"
			;;
		v)
			VERBOSE=1
			;;
		"?")
			echo "Invalid option: -$OPTARG"
			usage
			exit 1
			;;
	esac
done
shift $((OPTIND-1)) # leaves non-option arguments (i.e. files) in $@
