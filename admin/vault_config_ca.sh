#!/usr/bin/env bash
# https://www.vaultproject.io/api-docs/secret/pki#submit-ca-information
# make sure the certificate is the full chain if the ca is not the root
# use # pki_manage.sh intca_cat_json
#  from scripts repo 
set -e
readonly suffix_url="v1/pki_int/config/ca"
readonly input=$(jq '.intca')
readonly key=$(echo "$input" | jq -r '.key' | openssl rsa)
readonly cert=$(echo "$input" | jq -r '.cert')
readonly root=$(echo "$input" | jq -r '.root')
jq -Rs '{ "pem_bundle": . }' < <(echo -e "${key}\n${cert}\n${root}") \
  | curl \
    --insecure \
    --header "X-Vault-Token: ${VAULT_TOKEN}" \
    --request POST \
    --data @- \
    "${VAULT_ADDR}/${suffix_url}"
