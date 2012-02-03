#!/bin/bash

# copybin.sh -- a ssh pastebin without the "paste"
# see http://github.com/anotherkamila/copybin

# TODO support whole paths, not just plain filenames

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
check_config() { # {{{
	if [[ -z $SERVER || -z $HL_PROG || -z $TMPL ]]; then
		echo "Required config options not present; exiting!" >&2
		exit 127
	fi
	[[ $VERBOSE ]] && echo "Using config from file: $CONFIG_FILE"
} # }}}

# defaults
if [[ -f "$COPYBIN_CONFIG_FILE" ]]; then
	CONFIG_FILE="$COPYBIN_CONFIG_FILE"
else
	CONFIG_FILE="$HOME/.config/copybinrc"
fi

. $CONFIG_FILE

# options parsing
while getopts ":hc:p:dsrv" OPTION; do
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
		s)
			[[ -n "$OPTARG" ]] && SERVER="$OPTARG"
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
check_config

shift $((OPTIND-1)) # leaves non-option arguments (i.e. files) in $@

process() {
	f="$1"
	if [[ "$f" == */* ]]; then
		echo "$f: Supporting paths is a TODO. For now skipping."
		return 127
	fi

	TMPNAME="/tmp/copybin_${RANDOM}_${f}"
	awk "{if(\$0==\"!CONTENT\"){system(\"$HL_PROG '$f'\")}else{print}}" "$TMPL" > "$TMPNAME"
	sed -i -e "s/!NAME/$f/g" "$TMPNAME"

	scp "$f" "$SERVER/$f"
	scp "$TMPNAME" "$SERVER/$f.html"

	# TODO pw

	rm -f $TMPNAME
}

for f in $@; do
	process "$f"
done
