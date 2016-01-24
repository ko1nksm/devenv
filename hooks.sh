#!/bin/sh

before_destroy() {
  local vm=$1 key value storagectl port device
  getextradata "$vm" "vagrant-dev/attach_storage" | while IFS= read -r line; do
    key=${line%%$TAB*}
    value=${line#*$TAB}

    storagectl=${key%%-*}
    port=${key#*-}
    device=${port#*-}
    port=${port%%-*}

    if [ "$value" ]; then
      detachstorage "$1" "$storagectl" "$port" "$device"
    fi
  done
}
