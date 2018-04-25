#!/bin/bash

source functions.sh



echo -n "### get_fbus_crc "

sample_data="\x1E\x00\x0C\xD1\x00\x07\x00\x01\x00\x03\x00\x01\x60\x00"
test "$(get_fbus_crc "$sample_data")" == '\x72\xD5' && echo -n . || echo -n F

sample_data="\x1E\x00"
test "$(get_fbus_crc "$sample_data")" == '\x1E\x00' && echo -n . || echo -n F

echo 



