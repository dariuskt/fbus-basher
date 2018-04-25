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



