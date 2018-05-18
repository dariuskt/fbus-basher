#!/bin/bash

destnum="$1"
message="$2"
smsc="$3"

source functions.sh


setup_tty /dev/ttyUSB0

sms_frame="$(build_sms_frame)"

echo "sms: $sms_frame"

fbus_frame="$(fbus_encapsulate "$sms_frame")"

echo "fbus: $fbus_frame"

echo -ne "$fbus_frame" > /dev/ttyUSB0

