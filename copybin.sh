#!/bin/bash

# copybin.sh -- a ssh pastebin without the "paste"
# see http://github.com/anotherkamila/copybin

# TODO support whole paths, not just plain filenames

runif() { [[ `type -t $1` == function ]] && $1 ; }
usage() { # {{{
cat << EOF
usage: $0 options file(s)

Copy files using scp, creating neat pastebin-like HTML along the way

OPTIONS/TODOs:
  -h		Shows this message
  -u USER:PASS	password-protect the file with HTTP basic auth (.htpasswd),
		allowing only user USER with pw PASS to access it
  -u USER	password-protect the file with HTTP basic auth (.htpasswd),
		allowing only user USER to access it (.htaccess is not updated)
  -a		password-protect the file with HTTP basic auth (.htpasswd),
		allowing all defined users to access it
  -s SERVER	specify the server string to be used with scp (ex.:
		user@example.com:~/public_html/copybin/)
  -v		Verbose
EOF
} # }}}
check_config() { # {{{
	[[ $VERBOSE ]] && echo "Using config from file: $CONFIG_FILE"
	if [[ -z $SERVER || -z $HL_PROG || -z $TMPL ]]; then
		echo "Required config options not present; exiting!" >&2
		exit 127
	fi
} # }}}

# defaults {{{
# if the env var $COPYBIN_CONFIG_FILE contains a valid file, use that instead of
# the default
if [[ -f "$COPYBIN_CONFIG_FILE" ]]; then
	export CONFIG_FILE="$COPYBIN_CONFIG_FILE"
else
	export CONFIG_FILE="$HOME/.config/copybinrc"
fi

# `$CONFIG_FILE' can be used inside $CONFIG_FILE, because we have exported it
. $CONFIG_FILE
# }}}

# options parsing {{{
while getopts ":hu:as:v" OPTION; do
	case $OPTION in
		h)
			usage
			exit 1
			;;
		u)
			PASSWDPROTECT=1; USER=${OPTARG%:*}
			if [[ $OPTARG == *:* ]]; then PASS=${OPTARG#*:}; else PASS=''; fi
			;;
		a)
			PASSWDPROTECT=1; USER=''
			;;
		s)
			SERVER="$OPTARG"
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
done # }}}
check_config
# setup variables {{{
shift $((OPTIND-1)) # leaves non-option arguments (i.e. files) in $@
REMOTE="${SERVER%:*}"
DIR="${SERVER#*:}"
# }}}

htaccess() { # {{{
	f="$1"; REQUIRE="$2"
	if [[ -z `ssh "$REMOTE" "test -f $DIR/.htaccess && echo 1"` ]]; then
		[[ -n $VERBOSE ]] && echo ".htaccess not found on remote machine, copying template"
		cp "$HTACCESS_TMPL_FILENAME" /tmp/copybin-htaccess
		echo "AuthUserFile $HTPASSWD" >> /tmp/copybin-htaccess
		scp /tmp/copybin-htaccess "$SERVER/.htaccess"
		rm -f /tmp/copybin-htaccess
	fi

	ssh $REMOTE "[ -z \"\`grep $f $DIR/.htaccess\`\" ] && echo -e '<FilesMatch \"^$f(\.html)?$\">\n\tRequire $REQUIRE\n</FilesMatch>' >> $DIR/.htaccess"
} # }}}
htpasswd() { # {{{
	USER="$1"; PASS="$2"
	if [[ -n $PASS ]]; then
		ssh "$REMOTE" "htpasswd -bc $HTPASSWD $USER $PASS; chmod 644 $HTPASSWD"
	fi
} # }}}
process() { # {{{
	f="$1"
	if [[ "$f" == */* ]]; then
		echo "$f: Supporting paths is a TODO. For now skipping."
		return 127
	fi

	if [[ -n $PASSWDPROTECT ]]; then
		htpasswd $USER $PASS
		if [[ -n $USER ]]; then
			REQUIRE="user $USER"
		else
			REQUIRE='valid-user'
		fi
		htaccess "$f" "$REQUIRE"

		[[ -n $VERBOSE ]] && echo "Protecting with Require $REQUIRE"
	fi

	TMPNAME="/tmp/copybin_${RANDOM}_${f}"
	awk "{if(\$0==\"!CONTENT\"){system(\"$HL_PROG '$f'\")}else{print}}" "$TMPL" > "$TMPNAME"
	sed -i -e "s/!NAME/$f/g" "$TMPNAME"

	scp "$f" "$SERVER/$f"
	scp "$TMPNAME" "$SERVER/$f.html"

	rm -f "$TMPNAME"
} # }}}

runif beforeall
for f in $@; do
	runif beforefile "$f"
	process "$f"
	runif afterfile "$f"
done
runif afterall

[[ -n $VERBOSE ]] && echo "Done."
