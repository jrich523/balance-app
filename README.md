# Balance App

This is a simple API and Infra for a ETH latest balance check endpoint.

## Dev Setup

For local development of the API, there is a docker-compose file that will mount a .env file that should contain the api key.
Please review the `template.env` file

## Infra Setup

### First Run/New Acccount

If in a new repo, update the repo value in `account_setup.sh` and run to build the OIDC setup.
Run Terragrunt init locally to create the S3/Dynamo state configuration

The ECR repository is not created as part of this terraform and should already exist.
