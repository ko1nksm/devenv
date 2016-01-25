#!/bin/sh

set -eu

cd $(dirname $0)

TAB=$(printf "\t")

if [ -f ./hooks.sh ]; then
  . ./hooks.sh
fi

usage() {
cat <<TEXT
Usage: manage.sh [ -h | --help ]
  Display help

Usage: manage.sh upgrade [OPTION]... [VM]...

  OPTION:
    -r, --recreate  destroy vm and recreate
TEXT
exit
}

abort() {
  printf "\033[0;31m%s\033[0;39m\n" "$1"
  exit 1
}

call_hook() {
  local name="$1"
  shift

  if type "$name" >/dev/null 2>&1; then
    "$name" "$@"
  fi
}

vagrant_status() {
  local vm="$1" status
  status=$(vagrant status "$vm" | grep "^$vm ")
  status=${status#$vm}
  status=${status% *}
  echo $status | sed 's/ /-/'
}

vagrant_vmid() {
  local vm="$1" id_file=".vagrant/machines/$vm/virtualbox/id"
  if [ -d "$vm" -a -f "$id_file" ]; then
    cat "$id_file"
  fi
}

vbox_detachstorage() {
  local vm="$1" name="$2" storagectl port device vmid medium

  storagectl=${name%%-*}
  port=${name#*-}
  device=${port#*-}
  port=${port%%-*}

  vmid=$(vagrant_vmid "$vm")
  medium=$(VBoxManage showvminfo "$vmid" --machinereadable | grep "\"$name\"=" | sed "s/[^=]*=//")
  printf "$vm: Detach storage $storagectl port:$port device:$device (%s)\n" "$medium"
  VBoxManage storageattach "$vmid" --storagectl "$storagectl" --port "$port" --device "$device" --medium none
}

vbox_getextradata() {
  local vm="$1" vmid path="${2:-}"
  vmid=$(vagrant_vmid "$vm")
  [ "$path" ] && path="$path/"
  VBoxManage getextradata "$vmid" enumerate | while IFS= read -r line; do
    case $line in
      "Key: $path"*)
        echo ${line#Key: $path} | sed "s/, Value: /$TAB/"
    esac
  done
}

upgrade_vm() {
  local status

  status=$(vagrant_status "$vm")

  echo "Upgrade $vm ($status)"

  case $status in
    running)
      vagrant provision "$vm"
      ;;
    poweroff)
      vagrant up "$vm" --provision
      vagrant halt "$vm"
      ;;
    not-created | aborted)
      # skip
      ;;
    *)
      abort "Unsupport status '$status'"
  esac
}

recreate_vm() {
  local status

  status=$(vagrant_status "$vm")

  echo "Recreate $vm ($status)"

  case $status in
    running)
      vagrant halt "$vm"
      call_hook before_destroy "$vm"
      vagrant destroy -f "$vm"
      vagrant up "$vm" --provision
      ;;
    poweroff | aborted)
      call_hook before_destroy "$vm"
      vagrant destroy -f "$vm"
      vagrant up "$vm" --provision
      vagrant halt "$vm"
      ;;
    not-created)
      # skip
      ;;
    *)
      abort "Unsupport status '$status'"
  esac
}

upgrade() {
  local param recreate=""

  for param in "$@"; do
    case $param in
      -r | --recreate)  recreate=1 ;;
      -*) abort "Unknown option $param"
    esac
  done

  for vm in "$@"; do
    case $vm in
      -*) continue
    esac

    if [ $(vagrant_vmid $vm) ]; then
      if [ $recreate ]; then
        recreate_vm "$vm"
      else
        upgrade_vm "$vm"
      fi
    else
      abort "Specified VM '$vm' is not created by vagrant"
    fi
  done
}

if [ $# -eq 0 ]; then
  usage
fi

for param in "$@"; do
  case $param in
    -h | --help) usage ;;
  esac
done

case $1 in
  upgrade) $@ ;;
  *) abort "Unknown command '$1'"
esac
