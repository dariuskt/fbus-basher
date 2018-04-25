#!/bin/bash

smsc="$1"
destnum="$2"
message="$3"

source functions.sh


# setup_tty /dev/ttyUSB0

sms_frame="$(build_sms_frame)"

echo "sms: $sms_frame"

fbus_frame="$(fbus_encapsulate "$sms_frame")"

echo "fbus: $fbus_frame"


# debug

sample_data="Hi All. This"
expected_result="\xC8\x34\x28\xC8\x66\xBB\x40\x54\x74\x7A\x0E"

result="$(ascii_to_gsm7 "$sample_data")"
echo
num="$(echo -n "$sample_data" | xxd -p -u)"
echo ">>$num<<"
printf "%10s %s\n" input  "$(echo "ibase=16;obase=2;$num" | bc)"
num="$(echo -n $result | tr -d '\\x')"
printf "%10s %s\n" output "$(echo "ibase=16;obase=2;$num" | bc)"
num="$(echo -n $expected_result | tr -d '\\x')"
printf "%10s %s\n" target "$(echo "ibase=16;obase=2;$num" | bc)"


