#!/bin/bash

# copybin.sh -- a ssh pastebin without the "paste"
# see http://github.com/anotherkamila/copybin

# TODO support whole paths, not just plain filenames

# runs the given function iff it is defined
runif() { [[ `type -t $1` == function ]] && $1 ; }
usage() { # {{{
cat << EOF
usage: $0 options file(s)

Copy files using scp, creating neat pastebin-like HTML along the way

OPTIONS/TODOs:
  -h		Shows this message
  -u USER:PASS	password-protect the file with HTTP basic auth (.htpasswd),
		allowing only user USER with pw PASS to access it (a new user
		is created in .htpasswd)
		(not implemented yet)
  -u USER	password-protect the file with HTTP basic auth (.htpasswd),
		USER must already be present in the existing .htpasswd file
		(not implemented yet)
  -a		password-protect the file with HTTP basic auth (.htpasswd),
		using the 'Require valid-user' directive to allow all defined
		users to access it
  -s SERVER	specify the server string to be used with scp (ex.:
		user@example.com:~/public_html/copybin/)
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

# defaults {{{
if [[ -f "$COPYBIN_CONFIG_FILE" ]]; then
	CONFIG_FILE="$COPYBIN_CONFIG_FILE"
else
	CONFIG_FILE="$HOME/.config/copybinrc"
fi

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
shift $((OPTIND-1)) # leaves non-option arguments (i.e. files) in $@

htpasswd() { # {{{
	USER=$1; PASS=$2;
	# create .htaccess if it doesn't exist {{{
read -d '' HTACCESSCONTENT << "EOF"
AuthType Basic
AuthName \"Copybin: Authorization required\"
AuthUserFile \"$HTPASSWD\"
EOF
read -d '' CMD << EOF
if [ ! -f ${SERVER#*:}/.htaccess ]; then 
	echo "$HTACCESSCONTENT" > ${SERVER#*:}/.htaccess
fi
EOF
	# }}}

	if [[ -n $PASS ]]; then
		CMD="$CMD; htpasswd -bc ${SERVER#*:}/$HTPASSWD $USER $PASS"
	fi

	ssh ${SERVER%:*} "$CMD"
} # }}}
htaccess() { # {{{
ssh ${SERVER%:*} "[ -z \`grep $f ${SERVER#*:}/.htaccess\` ] && echo -e '<FilesMatch \"^$f(\.html)?$\">\n\tRequire $REQUIRE\n</FilesMatch>' >> ${SERVER#*:}/.htaccess"
} # }}}
process() { # {{{
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

	if [[ -n $PASSWDPROTECT ]]; then
		htpasswd $USER $PASS
		if [[ -n "$USER" ]]; then
			REQUIRE="user $USER"
		else
			REQUIRE='valid-user'
		fi
		htaccess $f $REQUIRE

		[[ -n $VERBOSE ]] && echo "Protecting with Require $REQUIRE"
	fi

	rm -f $TMPNAME
} # }}}

runif beforeall
for f in $@; do
	runif beforefile $f
	process "$f"
	runif afterfile $f
done
runif afterall

[[ -n $VERBOSE ]] && echo "Done."
