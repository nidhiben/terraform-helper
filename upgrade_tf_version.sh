#!/usr/bin/env bash

set -e -o pipefail

THIS_DIR="$(cd "$(dirname "${0}")" && pwd)"
ROOT_DIR="$(cd "$THIS_DIR/.." && pwd)"
TF_VERSION=$1

find_tf_directory () {
  dirs="$(find "${ROOT_DIR}" -name versions.tf -not -path "*/modules/*" -exec dirname '{}' \;)"
  failed=0
  for dir in $dirs; do
    cd "${dir}" || exit
    echo ${dir}
    upgrade_to_tf_version ">= ${TF_VERSION}" "${dir}"
  done
}


upgrade_to_tf_version() {
  local versions=$1
  local dir=$2
  echo ${dir}
  sed "s/required_version =.*/required_version = \"${versions}\"/" versions.tf
  if [[ "${dir}" =~ *"modules"* ]];then
    continue
  else
    echo "Initializing terraform after bumping the terraform version to ${versions}...."
    terraform init -upgrade
    echo "Running terraform plan...."
    terraform plan -detailed-exitcode
    if [[ $? == 2 ]];then
      echo "Please review the terraform changes above!"
      continue
    fi
    terraform 0.13upgrade -yes
    terraform plan -detailed-exitcode
    if [[ $? == 2 ]];then
      echo "Please review the terraform changes above!"
      continue
    elif [ $? == 0 ]; then
      terraform apply
    fi
  fi
}

main() {
  find_tf_directory
}

main
