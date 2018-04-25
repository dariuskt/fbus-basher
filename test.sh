#!/bin/bash

source functions.sh



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


