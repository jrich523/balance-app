#!/bin/bash

#Setup OIDC for the repo

# Set this repo before running!
repo="jrich523/balance-app"

role_name="GitHubAction-AssumeRoleInfra"
policy_name="infra_policy"

echo "Reading AWS Account ID..."

account_id=$(aws sts get-caller-identity --query 'Account' --output text)
if [[ -z "$account_id" ]]; then
  echo "Couldn't obtain AWS account ID. Have you authenticated to AWS?"
  exit 1
fi

echo "Account ID being configured: $account_id"

echo "Creating OpenID Connect Provider..."

create_oidc_output=$(aws iam create-open-id-connect-provider --url "https://token.actions.githubusercontent.com" --client-id-list 'sts.amazonaws.com' --output text 2>&1)
if [[ $? -ne 0 ]]; then
    if [[ $create_oidc_output == *"EntityAlreadyExists"* ]]; then
        echo "OpenID Connect provider already exists -- continuing"
    else
        echo "Error creating OpenID Connect provider: $create_oidc_output"
        exit 1
    fi
fi

trust_policy_json='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::'$account_id':oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:'$repo':*"
        }
      }
    }
  ]
}'

echo "$trust_policy_json" > oidc_role_trust_policy.gen.json

echo "Creating role..."

create_role_output=$(aws iam create-role --role-name $role_name --assume-role-policy-document "$trust_policy_json" --output text 2>&1)
if [[ $? -ne 0 ]]; then
    if [[ $create_role_output == *"EntityAlreadyExists"* ]]; then
        echo "Role already exists -- continuing"
    else
        echo "Error when creating role: $create_role_output"
        exit 1
    fi
fi

allow_all_policy_json='{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    }
  ]
}
'

echo "Updating policy in role..."

put_role_output=$(aws iam put-role-policy --role-name $role_name --policy-name $policy_name --policy-document "$allow_all_policy_json" --output text 2>&1)
if [[ $? -ne 0 ]]; then
    # we're putting so no risk of entity already exists
    echo "Error putting policy in role: $put_role_output"
    exit 1
fi

echo "Success!"