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


