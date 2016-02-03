#!/bin/sh

# Copyright (c) 2016 Koichi Nakashima
# Released under the MIT license
# http://opensource.org/licenses/mit-license.php

set -eu

BASEDIR="$(cd $(dirname $0); pwd)"
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
    -i, --install   install box
    -k, --keep      do not delete package.box after installed
    -n, --no-cache  do not use cache

Usage: manage.sh ssh [OPTION]... [BOX]...
  Login to box(es) for testing

  OPTION:
    -a, --all       ssh to all boxes
    -n, --no-cache  do not use cache

Usage: manage.sh create [OPTION]... [VM]...
  Create VM(s)

  OPTION:
    -a, --all       create all VMs
    -k, --keep      keep the running state

Usage: manage.sh upgrade [OPTION]... [VM]...
  Upgrade VM(s)

  OPTION:
    -a, --all       upgrade all VMs
    -r, --recreate  destroy VM and recreate
    -f, --force     force recreate VM

Usage: manage.sh remove [OPTION]... [VM]...
  Remove VM(s)

  OPTION:
    -a, --all       remove all VMs
    -f, --force     force remove VM
TEXT
exit
}

abort() {
  error "$1"
  exit 1
}

error() {
  printf "\033[0;31m%s\033[0;39m\n" "$1"
}

warn() {
  printf "\033[1;33m%s\033[0;39m\n" "$1"
}

info() {
  printf "\033[1;32m%s\033[0;39m\n" "$1"
}

yesno() {
  while true; do
    printf "%s [y/N] " "$1"
    read ans
    case $(echo $ans | tr "[:upper:]" "[:lower:]") in
      y | yes) return 0 ;;
      n | no | "") return 1 ;;
    esac
  done
}

unquote() {
  printf "%s" "$1" | sed 's/^"\(.*\)"$/\1/'
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

vbox_liststorage() {
  local vm="$1" vmid name line item
  vmid=$(vagrant_vmid "$vm")

  printf "$vm: Attached storage list\n"
  VBoxManage showvminfo "$vmid" --machinereadable | grep "^storagecontrollername" | while read -r line; do
    name=$(unquote "${line#*=}")
    VBoxManage showvminfo "$vmid" --machinereadable | grep "\"$name-[0-9]" | while read -r item; do
      printf "  %s: %s\n" "$(unquote "${item%%=*}")" "$(unquote "${item#*=}")"
    done
  done
}

vbox_detachstorage() {
  local vm="$1" name="$2" option="${3:-}" storagectl port device vmid medium

  storagectl=${name%%-*}
  port=${name#*-}
  device=${port#*-}
  port=${port%%-*}

  vmid=$(vagrant_vmid "$vm")
  medium=$(VBoxManage showvminfo "$vmid" --machinereadable | grep "\"$name\"=" | sed "s/[^=]*=//")
  medium=$(unquote "$medium")
  if [ "$option" = "--dry-run" ]; then
    printf "$vm: Storage will be detached [$name: %s]\n" "$medium"
  else
    if [ "$medium" = "none" ]; then
      printf "$vm: Already detached [$name: %s]\n" "$medium"
    else
      printf "$vm: Detach storage [$name: %s]\n" "$medium"
      VBoxManage storageattach "$vmid" --storagectl "$storagectl" --port "$port" --device "$device" --medium none
    fi
  fi
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
  local vm="$1" option="${2:-}" line key value

  vbox_getextradata "$vm" "vagrant-dev/attach_storage" | while IFS= read -r line; do
    key=${line%%$TAB*}
    value=${line#*$TAB}
    if [ "$value" ]; then
      vbox_detachstorage "$vm" "$key" "$option"
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
    poweroff | aborted)
      vagrant up "$vm" --provision
      vagrant halt "$vm"
      ;;
    not-created) ;; # skip
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
  local vm="$1" keep="$2" status

  status=$(vagrant_status "$vm")

  case $status in
    not-created)
      echo "Create $vm (current status: $status)"
      vagrant up "$vm" --provision
      if [ ! "$keep" ]; then
        vagrant halt "$vm"
      fi
      ;;
    *)
      echo "Skip the creation of $vm (current status: $status)"
      ;;
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
  local box install="" keep="" nocache="" size boxes package
  boxes=$@

  for param in "$@"; do
    case $param in
      -a | --all) boxes=$(list_boxes) ;;
      -i | --install) install=1 ;;
      -k | --keep) keep=1 ;;
      -n | --no-cache) nocache=1 ;;
      -*) abort "Unknown option $param"
    esac
  done

  for box in $boxes; do
    case $box in -*) continue; esac
    [ -d "$BOXESDIR/$box" ] || abort "Not found box directory"
    cd "$BOXESDIR/$box"

    unset LATEST_BOX_SUFFIX
    if [ ! "$nocache" ]; then
      if vagrant box list | grep "$box@latest " >/dev/null; then
        info "Build from latest box using as cache"
        info "To remove latest box, run below"
        info "vagrant box remove \"$box@latest\" --provider virtualbox"
        export LATEST_BOX_SUFFIX="@latest"
      fi
    fi

    package="$(echo "$box" | tr "/" "-")@$(date "+%Y.%m.%d.%H%M").box"
    vagrant halt
    vagrant up
    if vagrant ssh -c "sh -c '[ -f /vagrant/cleanup.sh ]'"; then
      vagrant reload # reboot for new kernel
      vagrant ssh -c "sudo sh /vagrant/cleanup.sh"
    fi
    vagrant halt
    vagrant package --output "$package"
    [ -f "$package" ] || abort "Not found $package"
    size=$(wc -c < "$package")
    info "Generated $package [$(expr $size / 1024 / 1024) MB]"
    vagrant destroy --force

    cd "$BASEDIR"
    mv "$BOXESDIR/$box/$package" "$BASEDIR/"
    if [ "$install" ]; then
      vagrant box add "$package" --name "$box@latest" --force
      [ "$keep" ] || rm "$package"
    else
      info "To install box, run below"
      info "vagrant box add \"$package\" --name \"$box@latest\" --force"
    fi
  done
}

do_ssh() {
  local box nocache="" boxes
  boxes=$@

  for param in "$@"; do
    case $param in
      -a | --all) boxes=$(list_boxes) ;;
      -n | --no-cache) nocache=1 ;;
      -*) abort "Unknown option $param"
    esac
  done

  for box in $boxes; do
    case $box in -*) continue; esac
    [ -d "$BOXESDIR/$box" ] || abort "Not found box directory"
    cd "$BOXESDIR/$box"

    unset LATEST_BOX_SUFFIX
    if [ ! "$nocache" ]; then
      if vagrant box list | grep "$box@latest " >/dev/null; then
        export LATEST_BOX_SUFFIX="@latest"
      else
        error "Not found latest box '$box'"
        continue
      fi
    fi

    vagrant halt
    vagrant up --no-provision
    vagrant ssh
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
  local param vms keep="" vmid
  vms=$@

  for param in "$@"; do
    case $param in
      -a | --all) vms=$(list_defined_vms) ;;
      -k | --keep) keep=1 ;;
      -*) abort "Unknown option $param"
    esac
  done

  for vm in $vms; do
    case $vm in -*) continue; esac
    create_vm "$vm" "$keep"
  done
}

do_upgrade() {
  local param recreate="" force="" vms vmid
  vms=$@

  for param in "$@"; do
    case $param in
      -a | --all) vms=$(list_vms) ;;
      -r | --recreate) recreate=1 ;;
      -f | --force) force=1 ;;
      -*) abort "Unknown option $param"
    esac
  done

  for vm in $vms; do
    case $vm in -*) continue; esac
    vmid=$(vagrant_vmid "$vm")
    if [ ! "$vmid" ]; then
      error "Specified VM '$vm' is not created by vagrant"
      continue
    fi

    if [ $recreate ]; then
      vbox_liststorage "$vm"
      if [ ! "$force" ]; then
        detach_storage "$vm" --dry-run
        warn "Attached storage will be deleted"
        yesno "Are you sure you want to recreate VM?" || continue
      fi
      recreate_vm "$vm"
    else
      upgrade_vm "$vm"
    fi
  done
}

do_remove() {
  local param vms force="" vmid
  vms=$@

  for param in "$@"; do
    case $param in
      -a | --all) vms=$(list_vms) ;;
      -f | --force) force=1 ;;
      -*) abort "Unknown option $param"
    esac
  done

  for vm in $vms; do
    case $vm in -*) continue; esac
    vmid=$(vagrant_vmid "$vm")
    if [ ! "$vmid" ]; then
      error "Specified VM '$vm' is not created by vagrant"
      continue
    fi

    vbox_liststorage "$vm"
    if [ ! "$force" ]; then
      detach_storage "$vm" --dry-run
      warn "Attached storage will be deleted"
      yesno "Are you sure you want to remove VM?" || continue
    fi
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
  build | ssh)
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
