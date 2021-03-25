#!/bin/bash
echo "INPUT_SECRETS: $INPUT_SECRETS"
eval "$( aws sts assume-role --role-arn arn:aws:iam::894939414795:role/wave-circleci-vault-role-shared --role-session session | jq -r '.Credentials | keys[] as $k | "\($k) \(.[$k])"' | awk '{ gsub(/[A-Z]/,"_&",$1); print "export","AWS"toupper($1)"="$2}' )"
vault login -method=aws -path=aws -address=https://vault.shared.astoapp.co.uk role=ci-role header_value=vault.shared.astoapp.co.uk region=us-east-1 > /dev/null 2>&1  && unset ${!AWS_@}

IFS=', ' read -r -a array <<< "$INPUT_SECRETS"
for SECRET_KEY in "${array[@]}"
do
    SECRET_VALUE="$(vault kv get -field=VALUE -address=https://vault.shared.astoapp.co.uk secret/app/circleci/${SECRET_KEY,,})"
    echo "::add-mask::${SECRET_VALUE}"
    echo "::set-output name=${SECRET_KEY}::${SECRET_VALUE}"
    if [ $INPUT_ENV_VAR == "1" ] ; then
      echo "${SECRET_KEY}=${SECRET_VALUE}" >> $GITHUB_ENV
    fi
done