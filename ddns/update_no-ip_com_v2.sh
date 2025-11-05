#
#.Distributed under the terms of the GNU General Public License (GPL) version 2.0
#
# script for sending updates to no-ip.com / noip.com
#.2014-2015 Christian Schoenebeck <christian dot schoenebeck at gmail dot com>
#
# This script is parsed by dynamic_dns_functions.sh inside send_update() function
#
# provider did not reactivate records, if no IP change was recognized
# so we send a dummy (localhost) and a seconds later we send the correct IP addr
#
local __DUMMY
local __UPDURL6="http://dynupdate6.no-ip.com/nic/update?hostname=[DOMAIN]&myip=[IP]"
local __UPDURL="http://dynupdate.no-ip.com/nic/update?hostname=[DOMAIN]&myip=[IP]"
# inside url we need username and password
[ -z "$username" ] && write_log 14 "Service section not configured correctly! Missing 'username'"
[ -z "$password" ] && write_log 14 "Service section not configured correctly! Missing 'password'"

# set IP version dependend dummy (localhost)
[ $use_ipv6 -eq 0 ] && __DUMMY="127.0.0.1" || __DUMMY="::1"
[ $use_ipv6 -eq 0 ] && __UPDURL=$__UPDURL || __UPDURL=$__UPDURL6

# lets do DUMMY transfer
#write_log 7 "sending dummy IP to 'no-ip.com'"
#__URL=$(echo $__UPDURL | sed -e "s#\[USERNAME\]#$URL_USER#g" -e "s#\[PASSWORD\]#$URL_PASS#g" \
#			       -e "s#\[DOMAIN\]#$domain#g" -e "s#\[IP\]#$__DUMMY#g")
#[ $use_https -ne 0 ] && __URL=$(echo $__URL | sed -e 's#^http:#https:#')

#do_transfer_mod "$__URL" || return 1

#write_log 7 "'no-ip.com' answered:${N}$(cat $DATFILE)"
# analyse provider answers
# "good [IP_ADR]"	= successful
# "nochg [IP_ADR]"	= no change but OK
#grep -E "good|nochg" $DATFILE >/dev/null 2>&1 || return 1

# lets wait a seconds
sleep 1

# now send the correct data
write_log 7 "sending real IP to 'no-ip.com'"
__URL=$(echo $__UPDURL | sed -e "s#\[USERNAME\]#$URL_USER#g" -e "s#\[PASSWORD\]#$URL_PASS#g" \
			       -e "s#\[DOMAIN\]#$domain#g" -e "s#\[IP\]#$__IP#g")
[ $use_https -ne 0 ] && __URL=$(echo $__URL | sed -e 's#^http:#https:#')

do_transfer_mod "$__URL" || return 1

write_log 7 "'no-ip.com' answered:${N}$(cat $DATFILE)"
# analyse provider answers
# "good [IP_ADR]"	= successful
# "nochg [IP_ADR]"	= no change but OK
grep -E "good|nochg" $DATFILE >/dev/null 2>&1
return $?	# "0" if "good" or "nochg" found

do_transfer_mod() {
	# $1	# URL to use
	local __URL="$1"
	local __ERR=0
	local __CNT=0	# error counter
	local __PROG  __RUNPROG
  local __AUTH=' -H "Authorization: Basic (BASE64 user:pass)" -A "MX4300/OpenWRT" '

	[ $# -ne 1 ] && write_log 12 "Error in 'do_transfer()' - wrong number of parameters"

	# Use ip_network as default for bind_network if not separately specified
	[ -z "$bind_network" ] && [ "$ip_source" = "network" ] && [ "$ip_network" ] && bind_network="$ip_network"

	# lets prefer GNU Wget because it does all for us - IPv4/IPv6/HTTPS/PROXY/force IP version
	if [ -n "$WGET_SSL" ] && [ $USE_CURL -eq 0 ]; then 			# except global option use_curl is set to "1"
		__PROG="$WGET --hsts-file=/tmp/.wget-hsts -nv -t 1 -O $DATFILE -o $ERRFILE"	# non_verbose no_retry outfile errfile
		# force network/ip to use for communication
		if [ -n "$bind_network" ]; then
			local __BINDIP
			# set correct program to detect IP
			[ $use_ipv6 -eq 0 ] && __RUNPROG="network_get_ipaddr" || __RUNPROG="network_get_ipaddr6"
			eval "$__RUNPROG __BINDIP $bind_network" || \
				write_log 13 "Can not detect current IP using '$__RUNPROG $bind_network' - Error: '$?'"
			write_log 7 "Force communication via IP '$__BINDIP'"
			__PROG="$__PROG --bind-address=$__BINDIP"
		fi
		# force ip version to use
		if [ $force_ipversion -eq 1 ]; then
			[ $use_ipv6 -eq 0 ] && __PROG="$__PROG -4" || __PROG="$__PROG -6"	# force IPv4/IPv6
		fi
		# set certificate parameters
		if [ $use_https -eq 1 ]; then
			if [ "$cacert" = "IGNORE" ]; then	# idea from Ticket #15327 to ignore server cert
				__PROG="$__PROG --no-check-certificate"
			elif [ -f "$cacert" ]; then
				__PROG="$__PROG --ca-certificate=${cacert}"
			elif [ -d "$cacert" ]; then
				__PROG="$__PROG --ca-directory=${cacert}"
			elif [ -n "$cacert" ]; then		# it's not a file and not a directory but given
				write_log 14 "No valid certificate(s) found at '$cacert' for HTTPS communication"
			fi
		fi
		# disable proxy if no set (there might be .wgetrc or .curlrc or wrong environment set)
		[ -z "$proxy" ] && __PROG="$__PROG --no-proxy"

		# user agent string if provided
		if [ -n "$user_agent" ]; then
			# replace single and double quotes
			user_agent=$(echo $user_agent | sed "s/'/ /g" | sed 's/"/ /g')
			__PROG="$__PROG --user-agent='$user_agent'"
		fi

		__RUNPROG="$__PROG '$__URL'"	# build final command
		__PROG="GNU Wget"		# reuse for error logging

	# 2nd choice is cURL IPv4/IPv6/HTTPS
	# libcurl might be compiled without Proxy or HTTPS Support
	elif [ -n "$CURL" ]; then
		__PROG="$CURL -RsS -o $DATFILE --stderr $ERRFILE"
		# check HTTPS support
		[ -z "$CURL_SSL" -a $use_https -eq 1 ] && \
			write_log 13 "cURL: libcurl compiled without https support"
		# force network/interface-device to use for communication
		if [ -n "$bind_network" ]; then
			local __DEVICE
			network_get_device __DEVICE $bind_network || \
				write_log 13 "Can not detect local device using 'network_get_device $bind_network' - Error: '$?'"
			write_log 7 "Force communication via device '$__DEVICE'"
			__PROG="$__PROG --interface $__DEVICE"
		fi
		# force ip version to use
		if [ $force_ipversion -eq 1 ]; then
			[ $use_ipv6 -eq 0 ] && __PROG="$__PROG -4" || __PROG="$__PROG -6"	# force IPv4/IPv6
		fi
		# set certificate parameters
		if [ $use_https -eq 1 ]; then
			if [ "$cacert" = "IGNORE" ]; then	# idea from Ticket #15327 to ignore server cert
				__PROG="$__PROG --insecure"	# but not empty better to use "IGNORE"
			elif [ -f "$cacert" ]; then
				__PROG="$__PROG --cacert $cacert"
			elif [ -d "$cacert" ]; then
				__PROG="$__PROG --capath $cacert"
			elif [ -n "$cacert" ]; then		# it's not a file and not a directory but given
				write_log 14 "No valid certificate(s) found at '$cacert' for HTTPS communication"
			fi
		fi
		# disable proxy if no set (there might be .wgetrc or .curlrc or wrong environment set)
		# or check if libcurl compiled with proxy support
		if [ -z "$proxy" ]; then
			__PROG="$__PROG --noproxy '*'"
		elif [ -z "$CURL_PROXY" ]; then
			# if libcurl has no proxy support and proxy should be used then force ERROR
			write_log 13 "cURL: libcurl compiled without Proxy support"
		fi

		__RUNPROG="$__PROG '$__AUTH' '$__URL'"	# build final command
		__PROG="cURL"			# reuse for error logging

	# uclient-fetch possibly with ssl support if /lib/libustream-ssl.so installed
	elif [ -n "$UCLIENT_FETCH" ]; then
		# UCLIENT_FETCH_SSL not empty then SSL support available
		UCLIENT_FETCH_SSL=$(find /lib /usr/lib -name libustream-ssl.so* 2>/dev/null)
		__PROG="$UCLIENT_FETCH -q -O $DATFILE"
		# force network/ip not supported
		[ -n "$__BINDIP" ] && \
			write_log 14 "uclient-fetch: FORCE binding to specific address not supported"
		# force ip version to use
		if [ $force_ipversion -eq 1 ]; then
			[ $use_ipv6 -eq 0 ] && __PROG="$__PROG -4" || __PROG="$__PROG -6"       # force IPv4/IPv6
		fi
		# https possibly not supported
		[ $use_https -eq 1 -a -z "$UCLIENT_FETCH_SSL" ] && \
			write_log 14 "uclient-fetch: no HTTPS support! Additional install one of ustream-ssl packages"
		# proxy support
		[ -z "$proxy" ] && __PROG="$__PROG -Y off" || __PROG="$__PROG -Y on"
		# https & certificates
		if [ $use_https -eq 1 ]; then
			if [ "$cacert" = "IGNORE" ]; then
				__PROG="$__PROG --no-check-certificate"
			elif [ -f "$cacert" ]; then
				__PROG="$__PROG --ca-certificate=$cacert"
			elif [ -n "$cacert" ]; then		# it's not a file; nothing else supported
				write_log 14 "No valid certificate file '$cacert' for HTTPS communication"
			fi
		fi
		__RUNPROG="$__PROG '$__URL' 2>$ERRFILE"		# build final command
		__PROG="uclient-fetch"				# reuse for error logging

	# Busybox Wget or any other wget in search $PATH (did not support neither IPv6 nor HTTPS)
	elif [ -n "$WGET" ]; then
		__PROG="$WGET -q -O $DATFILE"
		# force network/ip not supported
		[ -n "$__BINDIP" ] && \
			write_log 14 "BusyBox Wget: FORCE binding to specific address not supported"
		# force ip version not supported
		[ $force_ipversion -eq 1 ] && \
			write_log 14 "BusyBox Wget: Force connecting to IPv4 or IPv6 addresses not supported"
		# https not supported
		[ $use_https -eq 1 ] && \
			write_log 14 "BusyBox Wget: no HTTPS support"
		# disable proxy if no set (there might be .wgetrc or .curlrc or wrong environment set)
		[ -z "$proxy" ] && __PROG="$__PROG -Y off"

		__RUNPROG="$__PROG '$__URL' 2>$ERRFILE"		# build final command
		__PROG="Busybox Wget"				# reuse for error logging

	else
		write_log 13 "Neither 'Wget' nor 'cURL' nor 'uclient-fetch' installed or executable"
	fi

	while : ; do
		write_log 7 "#> $__RUNPROG"
		eval $__RUNPROG			# DO transfer
		__ERR=$?			# save error code
		[ $__ERR -eq 0 ] && return 0	# no error leave
		[ -n "$LUCI_HELPER" ] && return 1	# no retry if called by LuCI helper script

		write_log 3 "$__PROG Error: '$__ERR'"
		write_log 7 "$(cat $ERRFILE)"		# report error

		[ $VERBOSE -gt 1 ] && {
			# VERBOSE > 1 then NO retry
			write_log 4 "Transfer failed - Verbose Mode: $VERBOSE - NO retry on error"
			return 1
		}

		__CNT=$(( $__CNT + 1 ))	# increment error counter
		# if error count > retry_max_count leave here
		[ $retry_max_count -gt 0 -a $__CNT -gt $retry_max_count ] && \
			write_log 14 "Transfer failed after $retry_max_count retries"

		write_log 4 "Transfer failed - retry $__CNT/$retry_max_count in $RETRY_SECONDS seconds"
		sleep $RETRY_SECONDS &
		PID_SLEEP=$!
		wait $PID_SLEEP	# enable trap-handler
		PID_SLEEP=0
	done
	# we should never come here there must be a programming error
	write_log 12 "Error in 'do_transfer_mod()' - program coding error"
}
