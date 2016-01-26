#!/bin/sh

# Copyright (c) 2016 Koichi Nakashima
# Released under the MIT license
# http://opensource.org/licenses/mit-license.php

set -eu

BASEDIR="$(dirname $0)"
BOXESDIR="$BASEDIR/.boxes"
TAB=$(printf "\t")

usage() {
cat <<TEXT
Usage: manage.sh [ -h | --help ]
  Display help

Usage: manage.sh build [OPTION]... [BOX]...
  Build box(es)

  OPTION:
    -a, --all       build all boxes
    -d, --debug     keep VM for debug

Usage: manage.sh create [OPTION]... [VM]...
  Create VM(s)

  OPTION:
    -a, --all       create all VMs

Usage: manage.sh upgrade [OPTION]... [VM]...
  Upgrade VM(s)

  OPTION:
    -a, --all       upgrade all VMs
    -r, --recreate  destroy VM and recreate

Usage: manage.sh remove [OPTION]... [VM]...
  Remove VM(s)

  OPTION:
    -a, --all       remove all VMs
TEXT
exit
}

abort() {
  printf "\033[0;31m%s\033[0;39m\n" "$1"
  exit 1
}

info() {
  printf "\033[1;33m%s\033[0;39m\n" "$1"
}

vagrant_status() {
  local vm="$1" status

  status=$(vagrant status "$vm" | grep ")$" | grep "^$vm ")
  status=${status#$vm}
  status=${status% *}
  echo $status | sed 's/ /-/'
}

vagrant_status_list() {
  vagrant status | grep ")$"
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
  local vm="$1" path="${2:-}" vmid

  [ "$path" ] && path="$path/"
  vmid=$(vagrant_vmid "$vm")
  VBoxManage getextradata "$vmid" enumerate | while IFS= read -r line; do
    case $line in
      "Key: $path"*) echo ${line#Key: $path} | sed "s/, Value: /$TAB/"
    esac
  done
}

detach_storage() {
  local vm="$1" line key value

  vbox_getextradata "$vm" "vagrant-dev/attach_storage" | while IFS= read -r line; do
    key=${line%%$TAB*}
    value=${line#*$TAB}
    if [ "$value" ]; then
      vbox_detachstorage "$vm" "$key"
    fi
  done
}

upgrade_vm() {
  local vm="$1" status

  status=$(vagrant_status "$vm")

  echo "Upgrade $vm (current status: $status)"
  case $status in
    running)
      vagrant provision "$vm"
      ;;
    poweroff)
      vagrant up "$vm" --provision
      vagrant halt "$vm"
      ;;
    not-created | aborted) ;; # skip
    *) abort "Unsupport status '$status'"
  esac
}

recreate_vm() {
  local vm="$1" status

  status=$(vagrant_status "$vm")

  echo "Recreate $vm (current status: $status)"
  case $status in
    running)
      vagrant halt "$vm"
      detach_storage "$vm"
      vagrant destroy -f "$vm"
      vagrant up "$vm" --provision
      ;;
    poweroff | aborted)
      detach_storage "$vm"
      vagrant destroy -f "$vm"
      vagrant up "$vm" --provision
      vagrant halt "$vm"
      ;;
    not-created) ;; # skip
    *) abort "Unsupport status '$status'"
  esac
}

create_vm() {
  local vm="$1" status

  status=$(vagrant_status "$vm")

  echo "Create $vm (current status: $status)"
  case $status in
    not-created)
      vagrant up "$vm" --provision
      vagrant halt "$vm"
      ;;
    *) ;; # skip
  esac
}

remove_vm() {
  local vm="$1" status

  status=$(vagrant_status "$vm")

  echo "Remove $vm (current status: $status)"
  case $status in
    running)
      vagrant halt "$vm"
      detach_storage "$vm"
      vagrant destroy -f "$vm"
      ;;
    poweroff | aborted)
      detach_storage "$vm"
      vagrant destroy -f "$vm"
      ;;
    not-created) ;; # skip
    *) abort "Unsupport status '$status'"
  esac
}

list_boxes() {
  cd "$BOXESDIR"
  find . -name Vagrantfile | while IFS= read name; do
    name=$(echo "${name#./}")
    name=$(echo "${name%/Vagrantfile}")
    echo "$name"
  done
}

do_build() {
  local box workdir size debug="" boxes=$@

  for param in "$@"; do
    case $param in
      -a | --all) boxes=$(list_boxes) ;;
      -d | --debug) debug=1 ;;
      -*) abort "Unknown option $param"
    esac
  done

  for box in $boxes; do
    case $box in -*) continue; esac
    workdir="$BOXESDIR/$box"
    [ -d "$workdir" ] || abort "Not found box directory"
    cd "$workdir"
    [ -f package.box ] && abort "$workdir/package.box already exists."

    if vagrant box list | grep "$box (virtualbox, 0)" >/dev/null; then
      info "Found latest box"
      export LATEST_BOX_VERSION=0
    else
      unset LATEST_BOX_VERSION
    fi

    vagrant halt
    vagrant up --provision
    [ "$debug" ] && continue
    vagrant reload # reboot for new kernel
    vagrant ssh -c "sudo sh /vagrant/cleanup.sh"
    vagrant halt
    vagrant package
    [ -f package.box ] || abort "Not found package.box"
    size=$(wc -c < package.box)
    info "Generated package.box [$(expr $size / 1024 / 1024) MB]"
    vagrant box add package.box --name "$box" --force
    rm package.box
    vagrant destroy --force
  done
}

list_defined_vms() {
  vagrant_status_list | while IFS= read line; do
    echo ${line%% *}
  done
}

list_vms() {
  local dir vm
  for dir in "$BASEDIR/.vagrant/machines/"*; do
    vm=${dir##*/}
    if [ $(vagrant_vmid $vm) ]; then
      echo "$vm"
    fi
  done
}

do_create() {
  local param vms=$@ vmid

  for param in "$@"; do
    case $param in
      -a | --all) vms=$(list_defined_vms) ;;
      -*) abort "Unknown option $param"
    esac
  done

  for vm in $vms; do
    case $vm in -*) continue; esac
    create_vm "$vm"
  done
}

do_upgrade() {
  local param recreate="" vms=$@ vmid

  for param in "$@"; do
    case $param in
      -a | --all) vms=$(list_vms) ;;
      -r | --recreate) recreate=1 ;;
      -*) abort "Unknown option $param"
    esac
  done

  for vm in $vms; do
    case $vm in -*) continue; esac
    vmid=$(vagrant_vmid "$vm")
    [ "$vmid" ] || abort "Specified VM '$vm' is not created by vagrant"
    if [ $recreate ]; then
      recreate_vm "$vm"
    else
      upgrade_vm "$vm"
    fi
  done
}

do_remove() {
  local param vms=$@ vmid

  for param in "$@"; do
    case $param in
      -a | --all) vms=$(list_vms) ;;
      -*) abort "Unknown option $param"
    esac
  done

  for vm in $vms; do
    case $vm in -*) continue; esac
    vmid=$(vagrant_vmid "$vm")
    [ "$vmid" ] || abort "Specified VM '$vm' is not created by vagrant"
    remove_vm "$vm"
  done
}

[ $# -eq 0 ] && usage
for param in "$@"; do
  case $param in
    -h | --help) usage ;;
  esac
done

cd "$BASEDIR"
case $1 in
  build)
    if [ $# -eq 1 ]; then
      info "Box name(s) must be specified from list below or specify --all option"
      list_boxes
      exit
    fi
    do_$@
    ;;
  create | upgrade | remove)
    if [ $# -eq 1 ]; then
      info "VM name(s) must be specified from list below or specify --all option"
      list_vms
      exit
    fi
    do_$@
    ;;
  *) abort "Unknown command '$1'"
esac
