#!/bin/bash
# Base64 encoding function in pure Bash (no external tools)
base64_encode() {
    local input="$1"
    local base64chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local -i i=0
    local -i j=0
    local -i b=0
    local -i c=0
    local -i d=0
    local result=""

    while [ $i -lt ${#input} ]; do
        # Get 3 chars (24 bits) at a time
        local a1=0 a2=0 a3=0
        printf -v a1 '%d' "'${input:$i:1}" 2>/dev/null || a1=0
        i=$((i+1))
        [ $i -lt ${#input} ] && printf -v a2 '%d' "'${input:$i:1}" 2>/dev/null || a2=0
        i=$((i+1))
        [ $i -lt ${#input} ] && printf -v a3 '%d' "'${input:$i:1}" 2>/dev/null || a3=0
        i=$((i+1))

        # Convert to 4 bytes of 6 bits each
        b=$(( (a1 & 0xFC) >> 2 ))
        c=$(( ( (a1 & 0x03) << 4 ) | ( (a2 & 0xF0) >> 4 ) ))
        d=$(( ( (a2 & 0x0F) << 2 ) | ( (a3 & 0xC0) >> 6 ) ))
        local e=$((a3 & 0x3F))

        # Translate values to Base64 chars
        result+="${base64chars:$b:1}"
        result+="${base64chars:$c:1}"
        result+="${base64chars:$d:1}"
        result+="${base64chars:$e:1}"
    done

    # Manage padding
    case $(( ${#input} % 3 )) in
        1)
            result=${result%????}
            result+="${base64chars:$b:1}=="
            ;;
        2)
            result=${result%??}
            result+="${base64chars:$d:1}="
            ;;
    esac

    echo "$result"
}

[ -z "$CURL" ] && [ -z "$CURL_SSL" ] && write_log 14 "Communication require cURL with SSL support. Please install"
[ -z "$domain" ] && write_log 14 "Service section not configured correctly! Missing domain name as 'Domain'"
[ -z "$username" ] && write_log 14 "Service section not configured correctly! Missing username as 'Username'"
[ -z "$password" ] && write_log 14 "Service section not configured correctly! Missing password as 'Password'"

local __CREDENTIALS
__CREDENTIALS="$username:$password"

__STATUS=$(curl -Ss -X GET "http://dynupdate.no-ip.com/nic/update?hostname=${domain}&myip=${__IP}" \
	-H "Authorization: Basic $(base64_encode "$__CREDENTIALS")" \
	-w "%{response_code}\n" -o $DATFILE 2>$ERRFILE)

if [ $? -ne 0 ]; then
	write_log 14 "Curl failed: $(cat $ERRFILE)"
	return 1
elif [ -z $__STATUS ] || [ $__STATUS != 200 ]; then
	write_log 14 "Curl failed: $__STATUS \NO-IP.com answered: $(cat $DATFILE)"
	return 1
fi
