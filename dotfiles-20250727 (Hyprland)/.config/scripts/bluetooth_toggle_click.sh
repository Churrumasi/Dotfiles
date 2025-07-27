#!/usr/bin/env bash

powered=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')

if [[ "$powered" == "yes" ]]; then
  bluetoothctl power off
else
  bluetoothctl power on
fi
