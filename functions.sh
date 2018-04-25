#!/bin/bash


function setup_tty()
{
	dev=${1:-/dev/ttyUSB0}
	stty -F $dev 115200 raw -echo
}

function emit()
{
	echo "emit: $@" >&2
}

function get_len_dec()
{
	echo -ne "$1" | wc -c
}

function dec_to_hex2()
{
	len="$1"
	printf '\\x%02X\\x%02X' $(($len >> 8)) $(($len & 0xff))
}
function get_data_len()
{
	dec_to_hex2 $(get_len_dec "$1")
}

function rev()
{
	sed 's/^/\n/;:a; s/^\(.*\n\)\(.\)/\2\1/;/\n$/!ba;s/\n//'
}

function ascii_to_gsm7_map()
{
	# TODO: not implemented yet
	echo -n "$1"
}

function ascii_to_gsm7()
{
	local data=''
	local bin_data=''
	local hex_byte=0
	local byte=0

	for hex_byte in $(echo -n "$1" | xxd -p -u -c 256 | sed 's/\(..\)/\1 /g')
	do
		hex_byte="$(ascii_to_gsm7_map $hex_byte)"
		byte="$(printf "%d" "0x$hex_byte")"
		bits="$(printf '%07d' "$(echo "obase=2;$byte" | bc)" | rev)"
		bin_data="$bin_data$bits"
	done

	pad_bits=$(( 8 - $(echo -n $bin_data | wc -c) % 8 ))
	bin_data="$bin_data$(head -c $pad_bits </dev/zero | tr '\0' '0' )"

	for bits in $(echo $bin_data | sed 's/\(........\)/\1\n/g')
	do
		bits=$(echo "$bits" | rev)
		byte=$(echo "obase=16;ibase=2;$bits" | bc)
		printf '\\x%02X' "0x$byte"
	done
}

function get_fbus_crc()
{
	pkg="$1"
	byte_num=0

	odd=0
	even=0

	for byte in $(echo "$pkg" | tr '\\' ' ')
	do
		((byte_num++))

		dec_byte="$(printf '%d' "0$byte")"
		if [ $(($byte_num & 0x01)) -eq 1 ]
		then
				odd=$(($odd ^ $dec_byte))
		else
				even=$(($even ^ $dec_byte))
		fi
	done

	printf '\\x%02X\\x%02X' $odd $even
}




function build_sms_frame()
{
	# globals $smsc $destnum $message

	# Byte 6 to 8: Start ofthe SMS Frame Header. 0x00, 0x01, 0x00
	# Byte 9 to 11: 0x01, 0x02, 0x00 = Send SMS Message
	sms_frame="\x00\x01\x00\x01\x02\x00"
	
	echo -n "$sms_frame"
}

function fbus_encapsulate()
{
	local sms_frame="$1"

	# Byte 0: Frame ID (0x1E Cable)
	# Byte 1: Destination address. (0x00 Phone)
	# Byte 2: Source address. (0x0C Terminal)
	# Byte 3: Message Type or 'command'. (0x02 SMS Handling).
	local fbus_frame="\x1E\x00\x0C\x02"

	# Byte 4-5: Message length.
	fbus_frame="${fbus_frame}$(get_data_len "$sms_frame")"

	# add payload
	fbus_frame="${fbus_frame}${sms_frame}"

	# padd in case frame length is odd
	fbus_bytes="$(echo -e "$fbus_frame" | wc -c)"
	if [ $(($fbus_bytes & 0x01)) -eq 1 ]
	then
		fbus_frame="${fbus_frame}\x00"
	fi

	# add crc
	fbus_frame="${fbus_frame}$(get_fbus_crc "$fbus_frame")"

	echo -n "$fbus_frame"
}


