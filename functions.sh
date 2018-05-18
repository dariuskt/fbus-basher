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
function dec_to_hex1()
{
	len="$1"
	printf '\\x%02X' $len
}

function dec_to_hex2()
{
	len="$1"
	printf '\\x%02X\\x%02X' $(($len >> 8)) $(($len & 0xff))
}
function get_frame_len()
{
	len="$(get_len_dec "$1")"
	len=$(($len+2))
	dec_to_hex2 "$len"
}
function get_len()
{
	dec_to_hex1 $(get_len_dec "$1")
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

function num_to_oct()
{
	num=${1//[^0-9]/}
	data=''

	for two_digits in $(echo $num | sed 's/\(..\)/\1 /g')
	do
		two_digits=${two_digits}F
		lower=${two_digits:0:1}
		upper=${two_digits:1:1}

		data="$data\x$upper$lower"
	done

	echo "$data"
}

function encode_phone_number() {
	num="$1"
	data="\x82\x0C${2}\x08${3}"

	# number type
	data="${data}\x91"

	# encode number itself
	data="$data$(num_to_oct $num)"

	echo -n "$data"
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

function build_message_block() {
	msg="$1"

	data="$(ascii_to_gsm7 "$msg")"
	len="$(( $(get_len_dec "$data") + 4))"
	len2="$(get_len "$data")"
	len3="$(get_len "$msg")"

	while [ $(( $(( $(get_len_dec "$data") + 4)) % 8 )) -ne 0 ]
	do
		data="${data}\x55"
	done

	len1=$( dec_to_hex1 $(( $(get_len_dec "$data") + 4)) )

	data="\x80${len1}${len2}${len3}${data}"

	echo -n "$data"
}

function build_sms_frame()
{
	# globals $smsc $destnum $message

	# Byte 6~14: Documentation is a LIE! https://github.com/pkot/gnokii/blob/master/common/phones/nk6510.c#L2060
	sms_header="\x00\x01\x00\x02\x00\x00\x00\x55\x55"
	# magic follows
	sms_header="${sms_frame}\x01\x02"
	# more magic
	sms_frame="\x11\x00\x00\x00\x00\x04"


	sms_frame="${sms_frame}$(encode_phone_number "$destnum" '\x01' '\x0b')"
	sms_frame="${sms_frame}$(encode_phone_number "$smsc"    '\x02' '\x07')"
	sms_frame="${sms_frame}$(build_message_block "$message")"


	sms_frame="${sms_frame}\x08\x04\x01\xA9"


	len=$(( $(get_len_dec "$sms_frame") + 2 ))
	len=$(dec_to_hex1 "$len")
	sms_frame="${sms_header}${len}${sms_frame}"

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
	fbus_frame="${fbus_frame}$(get_frame_len "$sms_frame")"

	# add payload
	fbus_frame="${fbus_frame}${sms_frame}"

	# frames to go 0x01 means last frame
	fbus_frame="${fbus_frame}\x01"

	# sequence number
	fbus_frame="${fbus_frame}\x60"

	# padd in case frame length is odd
	fbus_bytes="$(echo -ne "$fbus_frame" | wc -c)"
	if [ $(($fbus_bytes & 0x01)) -eq 1 ]
	then
		fbus_frame="${fbus_frame}\x00"
	fi

	# add crc
	fbus_frame="${fbus_frame}$(get_fbus_crc "$fbus_frame")"

	echo -n "$fbus_frame"
}


