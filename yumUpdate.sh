#!/bin/sh
case "$1" in
OK)
	# The service just came back up, so don't do anything...
	;;
WARNING)
	# We don't really care about warning states, since the service is probably still running...
	;;
UNKNOWN)
	# We don't know what might be causing an unknown error, so don't do anything...
	;;
CRITICAL)
	case "$2" in

	# We're in a "soft" state, meaning that Nagios is in the middle of retrying the
	# check before it turns into a "hard" state and contacts get notified...
	SOFT)

		case "$3" in
		3)
			echo -n "Running Yum Update (3rd soft critical state)..."
			sudo /usr/bin/yum -y update
			;;
			esac
		;;

	HARD)
		echo -n "Running Yum Update (3rd soft critical state)..."
		sudo /usr/bin/yum -y update
		;;
	esac
	;;
esac
exit 0
