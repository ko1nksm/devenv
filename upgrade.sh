#!/bin/sh

set -eu

cd $(dirname $0)

TAB=$(printf "\t")
upgrade_box=""
recreate=""

if [ -f ./hooks.sh ]; then
  . ./hooks.sh
fi

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

call_hook() {
  local name=$1
  shift

  if type $name >/dev/null 2>&1; then
    "$name" "$@"
  fi
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

detachstorage() {
  local uuid medium
  uuid=$(vm_uuid "$1")
  medium=$(getmedium "$@")
  printf "$1: Detach storage $2 port:$3 device:$4 (%s)\n" "$medium"
  VBoxManage storageattach "$uuid" --storagectl "$2" --port "$3" --device "$4" --medium none
}

getmedium() {
  local uuid
  uuid=$(vm_uuid "$1")
  VBoxManage showvminfo "$uuid" --machinereadable | grep "\"$2-$3-$4\"=" | sed "s/[^=]*=//"
}

getextradata() {
  local uuid
  uuid=$(vm_uuid "$1")
  path=${2:-}
  [ $path ] && path="$path/"
  VBoxManage getextradata "$uuid" enumerate | while IFS= read -r line; do
    case $line in
      "Key: $path"*)
        echo ${line#Key: $path} | sed "s/, Value: /$TAB/"
    esac
  done
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
