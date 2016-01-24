#!/bin/sh

set -eu

cd $(dirname $0)

upgrade_box=""
recreate=""

usage() {
cat <<TEXT
Usage: Upgrade [OPTION]... [VM]...

OPTION:
  -b, --box       upgrade boxes
  -r, --recreate  destroy vm and recreate
  -h, --help      display help
TEXT
exit
}

abort() {
  printf "\033[0;31m%s\033[0;39m\n" "$1"
  exit 1
}

upgrade_boxes() {
  local name
  cd .boxes
  find . -name Vagrantfile | while IFS= read name; do
    name=$(echo "${name#./}")
    name=$(echo "${name%/Vagrantfile}")
    ./build.sh "$name"
  done
  cd ..
}

status_vm() {
  local status
  status=$(vagrant status "$1" | grep "^$1 ")
  status=${status#$1}
  status=${status% *}
  echo $status | sed 's/ /-/'
}

upgrade_vm() {
  local status

  status=$(status_vm "$vm")

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

  status=$(status_vm "$vm")

  echo "Recreate $vm ($status)"

  case $status in
    running)
      vagrant halt "$vm"
      destroy_vm "$vm"
      vagrant up "$vm" --provision
      ;;
    poweroff | aborted)
      destroy_vm "$vm"
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

destroy_vm() {
  if [ -f "$1/before-destroy.sh" ]; then
    . "$1/before-destroy.sh"
  elif [ -f "./before-destroy.sh" ]; then
    . "./before-destroy.sh"
  fi
  vagrant destroy -f "$1"
}

detach_storage() {
  local uuid

  uuid=$(vm_uuid "$1")
  echo "$1: Detach storage $2 port:$3 device:$4"
  VBoxManage storageattach "$uuid" --storagectl "$2" --port "$3" --device "$4" --medium none
}

vm_uuid() {
  local id_file=".vagrant/machines/$1/virtualbox/id"
  if [ -d $1 -a -f $id_file ]; then
    cat "$id_file"
  fi
}

if [ $# -eq 0 ]; then
  usage
fi

for param in "$@"; do
  case $param in
    -b | --box)       upgrade_box=1 ;;
    -r | --recreate)  recreate=1 ;;
    -h | --help) usage ;;
    -*) abort "Unknown option $param"
  esac
done

if [ $upgrade_box ]; then
  upgrade_boxes
fi

for vm in "$@"; do
  case $vm in
    -*) continue
  esac
  if [ $(vm_uuid $vm) ]; then
    if [ $recreate ]; then
      recreate_vm "$vm"
    else
      upgrade_vm "$vm"
    fi
  else
    abort "Specified VM '$vm' is not created by vagrant"
  fi
done
