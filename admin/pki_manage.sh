#!/usr/bin/env bash
set -eu

log() {
  logger -s -t "${0##*/}" "$@"
}

main() {
  local -r config="$(realpath openssl.cnf)"
  local -r ca_path="$(realpath -m ca)"
  local -r config_path="$(realpath -m config)"
  local -r cakey="$ca_path/private/ca.key.pem"
  local -r cacert="$ca_path/certs/ca.cert.pem"
  local -r deployment_path="/etc/pki/"

  local -r cmd=$1
  shift

  if [[ -n "$cmd" ]]; then
    cmd_$cmd "$@"
  else
    log "Need function name for managing. Make sure to create a config with the same <name>"
    log "Example: init_ca, generate <name> [ca option flags]..."
    exit 1
  fi
}

define_paths() {
  local -r name=${1:?name required}
  local -r var_name_path=${name}_path
  readonly "${name}_path"="${ca_path}/${name}"
  readonly "${name}_key"="${!var_name_path}/private/${name}.key.pem"
  readonly "${name}_cert"="${!var_name_path}/certs/${name}.cert.pem"
  readonly "${name}_csr"="${!var_name_path}/csr/${name}.csr.pem"
  readonly "${name}_cachain"="${!var_name_path}/certs/ca-chain.cert.pem"
  readonly "${name}_crl"="${!var_name_path}/crl/dgeng.crl.pem"
}

cmd_init_ca() {
  log "Initiliazing certificate authority."
  setup_root_ca
  setup_intermediate_ca
  generate_revocation_list
}

cmd_generate_revocation_list() {
  define_paths "intermediate"
  pushd "$intermediate_path"
  log "Generate revocation list in $intermediate_path."
  openssl ca -config "$config" \
    -cert "$intermediate_cert" \
    -keyfile "$intermediate_key" \
    -gencrl -out "$crl"
  popd
}

cmd_revoke() {
  local -r cert="$intermediate_path/certs/${1}.cert.pem"
  if ! [[ -f $cert ]]; then
    log "Certificate for $1 does not exist."
    exit 1
  fi
  pushd "$intermediate_path"
  log "Revoking $cert."
  openssl ca -config "$config" \
    -cert "$intermediate_cert" \
    -keyfile "$intermediate_key" \
    -revoke "$cert"
  popd
}

cmd_crl() {
  [[ -f "$crl" ]] || exit 1
  openssl crl -in "$crl" -noout -text
}

cmd_generate() {
  local -r name=${1?No name given}
  shift

  pushd "$intermediate_path"
  create_key "$name"
  create_csr "$name" "$@"
  sign_request "$name" "$@"
  popd
}

create_key() {
  local -r name=${1?No name given}
  shift

  local -r key="$intermediate_path/private/${name}.key.pem"

  log "Generate key: $key."
  openssl genrsa -aes256 \
    -out "$key" 2048 \
    "$@"
  chmod 400 "$key"
}

create_csr() {
  local -r name=${1?No name given}
  shift

  local -r key="$intermediate_path/private/${name}.key.pem"
  local -r csr="$intermediate_path/csr/${name}.csr.pem"
  local -r csr_config="${config_path}/${name}.cnf"

  if ! test -f "$csr_config"; then
    log "Cannot find $csr_config for generating the csr."
    exit 1
  fi
  if ! rg -Fq "$name" "$csr_config"; then
    log "Extension $name not found in $csr_config."
    exit 1
  fi

  log "Generate csr: $csr."
  # generate csr with key for clients and servers
  openssl req -config <(cat "$config" "$csr_config") \
    -reqexts "$name" \
    -key "$key" \
    -new -out "$csr" \
    "$@"
}

sign_request() {
  # generate cert for clients or servers
  local -r name=${1?No name given}
  shift

  local -r csr="$intermediate_path/csr/${name}.csr.pem"
  local -r cert="$intermediate_path/certs/${name}.cert.pem"
  local -r key="$intermediate_path/private/${name}.key.pem"
  local -r csr_config="${config_path}/${name}.cnf"

  if ! test -f "$csr_config"; then
    log "Cannot find $csr_config for generating the csr."
    exit 1
  fi
  if ! rg -Fq "$name" "$csr_config"; then
    log "Extension $name not found in $csr_config."
    exit 1
  fi

  log "Sign csr $csr: generate to $cert."
  openssl ca -config <(cat "$config" "$csr_config") \
    -extensions "$name" \
    -notext \
    -cert "$intermediate_cert" \
    -keyfile "$intermediate_key" \
    -in "$csr" \
    -out "$cert" \
    "$@"
  chmod 644 "$cert"

  if ! verify_cert "$cert"; then
    log "Failed to verify cert $cert."
    exit 1
  fi
  if ! cmd_verify "$cert"; then
    log "Failed to verify cert $cert with chain trust."
    exit 1
  fi
  log "Exported new certifate for '$name' - $cert"
  log "Export the following certificates for use in an env:"
  log "$ca_chain_cert"
  log "$key"
  log "$cert"
}

cmd_setup_root_ca() {
  log "Setup root ca in $ca_path."
  mkdir -p "$ca_path"
  setup_env "$ca_path"
  pushd "$ca_path"
  # create root key
  gen_ca_key "$cakey"
  gen_ca_cert "$cakey" "$cacert"
  verify_cert "$cacert"
  popd
}

cmd_setup_intermediate_ca() {
  define_paths "intermediate"
  log "Setup intermediate ca in $intermediate_path."
  mkdir -p "$intermediate_path"
  setup_env "$intermediate_path"
  pushd "$intermediate_path"
  # create root key
  gen_ca_key "$intermediate_key"
  gen_csr "$intermediate_key" "$intermediate_csr"
  sign_intermediate_csr
  verify_cert "$intermediate_cert"
  cmd_verify_with_ca "$intermediate_cert"
  # create chain
  popd
}

cmd_setup_ca() {
  # create subca from intermediate
  local -r caname=${1?caname required}
  define_paths "intermediate"
  define_paths "${caname}"
  local -r var_caname_path=${caname}_path
  local -r var_caname_key=${caname}_key
  local -r var_caname_cert=${caname}_cert
  local -r var_caname_csr=${caname}_csr

  log "Setup ${caname} ca in ${!var_caname_path}."
  mkdir -p "${!var_caname_path}"
  setup_env "${!var_caname_path}"
  pushd "${!var_caname_path}"
  # create root key
  gen_ca_key "${!var_caname_key}"
  gen_csr "${!var_caname_key}" "${!var_caname_csr}"
  sign_ca_csr "${!var_caname_csr}" "${!var_caname_cert}" "${2:?days valid required}"
  verify_cert "${!var_caname_cert}"
  cmd_verify_with_subca "${!var_caname_cert}"
  # create chain
  cat "${!var_caname_cert}" "$intermediate_cert" "$cacert" >"${!var_caname_cachain}"
  popd
}

cmd_renew_intermediate_ca() {
  define_paths "intermediate"
  pushd "$intermediate_path"
  gen_csr "$intermediate_key" "$intermediate_csr"
  sign_intermediate_csr
  verify_cert "$intermediate_cert"
  cmd_verify_with_ca "$intermediate_cert"
  popd
  cat "$intermediate_cert" "$cacert" >"$intermediate_cachain"
}

cmd_cachain_cat() {
  define_paths "intermediate"
  cat "$intermediate_cert" "$cacert"
}

cmd_subcachain_cat() {
  local -r name=${1?name required}
  define_paths "intermediate"
  define_paths "$name"
  local -r var_name_cert=${name}_cert
  cat "${!var_name_cert}" "$intermediate_cert" "$cacert"
}

sign_intermediate_csr() {
  log "Signing intermediate cert."
  # sign intermediate with root ca
  openssl ca -config "$config" \
    -extensions v3_intermediate_ca \
    -days 730 -notext \
    -keyfile "$cakey" \
    -cert "$cacert" \
    -in "$intermediate_csr" \
    -out "$intermediate_cert"
  chmod 644 "$intermediate_cert"
}

sign_ca_csr() {
  log "Signing ca csr with intermediate ca."
  openssl ca -config "$config" \
    -extensions v3_intermediate_ca \
    -days "${3:?days required}" -notext \
    -keyfile "${intermediate_key}" \
    -cert "${intermediate_cert}" \
    -in "${1:?ca csr required}" \
    -out "${2:?ca cert output path required}"
  chmod 644 "$2"
}

setup_env() {
  log "Setup environment in $1."
  pushd "$1"
  mkdir -p certs crl newcerts private csr
  chmod 700 private
  touch index.txt
  echo 1000 >serial
  echo 1000 >crlnumber
  popd
}

gen_csr() {
  local -r key=$1
  local -r csr=$2
  log "Generate certificate signing request for $csr."
  openssl req -config "$config" -new \
    -key "$key" \
    -out "$csr"
}

gen_ca_key() {
  local -r key=$1
  log "Generate ca key: $key."
  openssl genrsa -aes256 -out "$key" 4096 || exit 1
  chmod 400 "$key"
}

gen_ca_cert() {
  # create root cert
  # use long expiration date
  local -r key=$1
  local -r cert=$2
  log "Generate ca certificate: $cert."
  openssl req -config "$config" \
    -key "$key" \
    -new -x509 -days 3650 -extensions v3_ca \
    -out "$cert"
  chmod 644 "$cert"
}

cmd_deploy() {
  mkdir -p "$deployment_path"
  log "Deploying intermediate ca and ca chain to $deployment_path."
  log "Confirm: <Enter>"
  read p
  cp "$intermediate_cert" "$deployment_path/"
  cp "$intermediate_key" "$deployment_path/"
  create_ca_chain
  cp "$ca_chain_cert" "$deployment_path/"
}

verify_cert() {
  # verify
  # the Signature Algorithm used
  # the dates of certificate Validity
  # the Public-Key bit length
  # the Issuer, which is the entity that signed the certificate
  # the Subject, which refers to the certificate itself
  # issuer and subject should be identical
  local -r cert=$1
  openssl x509 -noout -text -in "$cert" | less
}

cmd_verify_with_ca() {
  # check against root ca
  local -r cert=$1
  log "Verify certificate: $cert, against ca certificate: $cacert."
  openssl verify -CAfile "$cacert" \
    "$cert"
}

cmd_verify_with_subca() {
  # check against intermediate root ca
  local -r cert=$1
  log "Verify certificate: $cert, against subca certificate: $intermediate_cert."
  openssl verify -CAfile "$intermediate_cert" \
    "$cert"
}

cmd_verify() {
  # check against root ca
  local -r cert=$1
  log "Verify certificate: $cert, against ca chain: $ca_chain_cert."
  openssl verify -CAfile "$ca_chain_cert" \
    "$cert"
}

cmd_rm() {
  define_paths "intermediate"
  local -r key="$intermediate_path/private/${1}.key.pem"
  local -r csr="$intermediate_path/csr/${1}.csr.pem"
  local -r cert="$intermediate_path/certs/${1}.cert.pem"
  set +e
  rm -v "$key"
  rm -v "$csr"
  rm -v "$cert"
}

cmd_ls() {
  define_paths "intermediate"
  local -r key="$intermediate_path/private/${1}.key.pem"
  local -r csr="$intermediate_path/csr/${1}.csr.pem"
  local -r cert="$intermediate_path/certs/${1}.cert.pem"
  set +e
  ls -l "$key"
  ls -l "$csr"
  ls -l "$cert"
}

cmd_ca_print() {
  set +e
  openssl rsa -noout -text -in "$cakey"
  openssl x509 -noout -text -in "$cacert"
  openssl req -noout -text -in "$csr"
}

cmd_ca_cat() {
  set +e
  echo "## ca key #########################################################################"
  cat "$cakey"
  echo "## ca cert ########################################################################"
  cat "$cacert"
  echo "################################################################################"
}

cmd_rootca_cat_json() {
  set +e
  jq -c -n \
    --arg name "ca" \
    --arg key "$(cat "$cakey")" \
    --arg cert "$(cat "$cacert")" \
    '{ ($name): { "key": $key, "cert": $cert } }'
}

cmd_intca_cat_json() {
  define_paths "intermediate"
  set +e
  jq -c -n \
    --arg name "intca" \
    --arg key "$(cat "$intermediate_key")" \
    --arg root "$(cat "$cacert")" \
    --arg cert "$(cat "$intermediate_cert")" \
    --arg cachain "$(cat "$intermediate_cachain")" \
    '{ ($name): { "key": $key, "cert": $cert, "root": $root, "cachain": $cachain } }'
}

cmd_subca_cat_json() {
  local -r name=${1:?subca name required}
  define_paths "intermediate"
  define_paths "${name}"

  local -r var_name_path=${name}_path
  local -r var_name_key=${name}_key
  local -r var_name_cert=${name}_cert
  local -r var_name_cachain=${name}_cachain

  set +e
  jq -c -n \
    --arg name "intca" \
    --arg key "$(cat "${!var_name_key}")" \
    --arg root "$(cat "$cacert")" \
    --arg intca "$(cat "$intermediate_cert")" \
    --arg cert "$(cat "${!var_name_cert}")" \
    --arg cachain "$(cat "${!var_name_cachain}")" \
    '{ ($name): { "key": $key, "cert": $cert, "root": $root, "intca": $intca, "cachain": $cachain } }'
}

cmd_intca_pem_bundle() {
  # print the intermediate ca as a pem bundle for feeding to the vault api
  set +e
  define_paths "intermediate"
  # bundle requires decrypted key
  cat "$intermediate_key" | openssl rsa
  cat "$intermediate_cert"
  cat "$cacert"
}

cmd_print() {
  define_paths "intermediate"
  local -r key="$intermediate_path/private/${1}.key.pem"
  local -r csr="$intermediate_path/csr/${1}.csr.pem"
  local -r cert="$intermediate_path/certs/${1}.cert.pem"
  set +e
  openssl rsa -noout -text -in "$key"
  openssl x509 -noout -text -in "$cert"
  openssl req -noout -text -in "$csr"
}

cmd_cat() {
  define_paths "intermediate"
  local -r key="$intermediate_path/private/${1}.key.pem"
  local -r csr="$intermediate_path/csr/${1}.csr.pem"
  local -r cert="$intermediate_path/certs/${1}.cert.pem"
  set +e
  echo "## key #########################################################################"
  cat "$key"
  echo "## cert ########################################################################"
  cat "$cert"
  echo "################################################################################"
}

cmd_cat_json() {
  define_paths "intermediate"
  local -r key="$intermediate_path/private/${1}.key.pem"
  local -r csr="$intermediate_path/csr/${1}.csr.pem"
  local -r cert="$intermediate_path/certs/${1}.cert.pem"
  set +e
  jq -c -n \
    --arg name "$1" \
    --arg key "$(cat $key)" \
    --arg cert "$(cat $cert)" \
    '{ ($name): { "key": $key, "cert": $cert } }'
}

cmd_decrypt_key() {
  define_paths "intermediate"
  local -r name=${1?No name given}
  shift

  local -r key="$intermediate_path/private/${name}.key.pem"

  log "Generate key: $key."
  openssl rsa \
    -in "$key" \
    -out "$key"
  chmod 400 "$key"
}

set -e
main "$@"
set +e
