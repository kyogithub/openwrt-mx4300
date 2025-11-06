# Base64 encoding function in BusyBox (no external tools)
base64_encode() {
    input="$1"
    base64chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    i=0
    result=""

    while [ $i -lt $(echo "$input" | wc -c) ]; do
        # Obtener los bytes
        b1=0 b2=0 b3=0
        if [ $i -lt $(echo "$input" | wc -c) ]; then
            b1=$(printf '%d' "'$(echo "$input" | cut -c $((i+1)) | head -c1)")
            i=$((i+1))
        fi
        if [ $i -lt $(echo "$input" | wc -c) ]; then
            b2=$(printf '%d' "'$(echo "$input" | cut -c $((i+1)) | head -c1)")
            i=$((i+1))
        fi
        if [ $i -lt $(echo "$input" | wc -c) ]; then
            b3=$(printf '%d' "'$(echo "$input" | cut -c $((i+1)) | head -c1)")
            i=$((i+1))
        fi

        # Convertir bytes a Base64
        c1=$(( (b1 & 0xFC) >> 2 ))
        c2=$(( ( (b1 & 0x03) << 4 ) | ( (b2 & 0xF0) >> 4 ) ))
        c3=$(( ( (b2 & 0x0F) << 2 ) | ( (b3 & 0xC0) >> 6 ) ))
        c4=$((b3 & 0x3F))

        result=$(echo "$result${base64chars:$c1:1}${base64chars:$c2:1}${base64chars:$c3:1}${base64chars:$c4:1}")
    done

    # Padding
    case $(echo "$input" | wc -c) in
        *[1-9]) # Singularity
            result=$(echo "$result" | sed 's/.$/=/;s/.$/=/')
            ;;
        *[0-9][0-9]|0) # Even length
            result=$(echo "$result" | sed 's/.$/=/')
            ;;
    esac

    echo "$result"
}

[ -z "$CURL" ] && [ -z "$CURL_SSL" ] && write_log 14 "Communication require cURL with SSL support. Please install"
[ -z "$domain" ] && write_log 14 "Service section not configured correctly! Missing domain name as 'Domain'"
[ -z "$username" ] && write_log 14 "Service section not configured correctly! Missing username as 'Username'"
[ -z "$password" ] && write_log 14 "Service section not configured correctly! Missing password as 'Password'"

__CREDENTIALS="$username:$password"

#__CMD="curl -Ss \"http://dynupdate.no-ip.com/nic/update?hostname=${domain}&myip=${__IP}\" -H \"Authorization: Basic $(base64_encode "$__CREDENTIALS")\" -A \"MX4300/OpenWRT\" -w \"%{response_code}\n\" -o $DATFILE 2>$ERRFILE)"
#write_log 6 "Command: $__CMD"

__STATUS=$(curl -Ss "http://dynupdate.no-ip.com/nic/update?hostname=${domain}&myip=${__IP}" \
        -H "Authorization: Basic $(base64_encode "$__CREDENTIALS")" \
        -A "MX4300/OpenWRT" \
        -w "%{response_code}\n" -o $DATFILE 2>$ERRFILE)

if [ $? -ne 0 ]; then
        write_log 14 "Curl failed: $(cat $ERRFILE)"
        return 1
elif [ -z $__STATUS ] || [ $__STATUS != 200 ]; then
        write_log 14 "Curl failed: $__STATUS \NO-IP.com answered: $(cat $DATFILE)"
        return 1
fi


	return 1
fi
