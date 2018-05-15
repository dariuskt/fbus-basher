#!/bin/bash

source functions.sh
function test_report()
{
	echo
	echo "input data:    $1"
	echo "output data:   $2"
	echo "expected data: $3"
}


echo -n "### get_fbus_crc "

sample_data="\x1E\x00\x0C\xD1\x00\x07\x00\x01\x00\x03\x00\x01\x60\x00"
test "$(get_fbus_crc "$sample_data")" == '\x72\xD5' && echo -n . || echo -n F

sample_data="\x1E\x00"
test "$(get_fbus_crc "$sample_data")" == '\x1E\x00' && echo -n . || echo -n F

echo 



echo -n "### ascii_to_gsm7 "

sample_data="hello"
expected_result="\xE8\x32\x9B\xFD\x06"
test "$(ascii_to_gsm7 "$sample_data")" == "$expected_result" && echo -n . || echo -n F

sample_data="Hi All. This"
expected_result="\xC8\x34\x28\xC8\x66\xBB\x40\x54\x74\x7A\x0E"
test "$(ascii_to_gsm7 "$sample_data")" == "$expected_result" && echo -n . || echo -n F

echo



echo -n "### encode_phone_number "

sample_data="+61411990010"
expected_result="\x07\x91\x16\x14\x91\x09\x10\xF0\x00\x00\x00\x00"
result="$(encode_phone_number "$sample_data")"
test "$result" == "$expected_result" && echo -n . || test_report "$sample_data" "$result" "$expected_result"

sample_data="+3706001234567"
expected_result="\x08\x91\x73\x60\x00\x21\x43\x65\xF7\x00\x00\x00"
result="$(encode_phone_number "$sample_data")"
test "$result" == "$expected_result" && echo -n . || test_report "$sample_data" "$result" "$expected_result"

sample_data="+37060012345678"
expected_result="\x08\x91\x73\x60\x00\x21\x43\x65\x87\x00\x00\x00"
result="$(encode_phone_number "$sample_data")"
test "$result" == "$expected_result" && echo -n . || test_report "$sample_data" "$result" "$expected_result"

sample_data="+370600123456789"
expected_result="\x09\x91\x73\x60\x00\x21\x43\x65\x87\xF9\x00\x00"
result="$(encode_phone_number "$sample_data")"
test "$result" == "$expected_result" && echo -n . || test_report "$sample_data" "$result" "$expected_result"

echo



echo -n "### build_sms_frame "

destnum="040378007400000000"
message="Hi All. This message was sent through F-Bus. Cool!!"
smsc="+61411990010"
sample_data="destnum $destnum; smsc $smsc; message $message"
expected_result="\
\x1E\x00\x0C\x02\x00\x59\x00\x01\x00\x01\x02\x00\
\x07\x91\x16\x14\x91\x09\x10\xF0\x00\x00\x00\x00\
\x15\x00\x00\x00\x33\
\x0A\x81\x40\x30\x87\x00\x47\x00\x00\x00\x00\x00\
\xA7\x00\x00\x00\x00\x00\x00\xC8\x34\x28\xC8\x66\xBB\x40\x54\x74\x7A\x0E\x6A\x97\xE7\xF3\xF0\xB9\x0C\xBA\x87\xE7\xA0\x79\xD9\x4D\x07\xD1\xD1\xF2\x77\xFD\x8C\x06\x19\x5B\xC2\xFA\xDC\x05\x1A\xBE\xDF\xEC\x50\x08\x01\x43\x00\x7A\x52"
result="$(build_sms_frame)"
test "$result" == "$expected_result" && echo -n . || test_report "$sample_data" "$result" "$expected_result"


