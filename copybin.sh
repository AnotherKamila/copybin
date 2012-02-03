#!/bin/bash

# copybin.sh -- a ssh pastebin without the "paste"
# see http://github.com/anotherkamila/copybin

# defaults
CONFIG_FILE="$HOME/.config/copybinrc"
VERBOSE=0

usage() { # {{{
cat << EOF
usage: $0 options file(s)

Copy files using scp, creating neat pastebin-like HTML along the way

OPTIONS/TODOs:
  -h		Shows this message
  -c FILE	Read config from FILE instead of default $CONFIG_FILE
  -p USER:PASS	password-protect the file with HTTP basic auth (.htpasswd)
		(not implemented yet)
  -p USER	password-protect the file with HTTP basic auth (.htpasswd),
		USER must already be present in the existing .htpasswd file
		(not implemented yet)
  -d		password-protect the file with HTTP basic auth (.htpasswd),
		using the default USER and PASS from the config file
		(not implemented yet)
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
		c)
			[[ -n "$OPTARG" ]] && CONFIG_FILE="$OPTARG"
			;;
		p)
			echo "u:p $OPTARG"
			;;
		d)
			echo "would encrypt w/ default u:p"
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

echo "CONFIG_FILE: $CONFIG_FILE"
echo "VERBOSE: $VERBOSE"

