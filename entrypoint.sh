#!/usr/bin/env bash

if [ -z "$CI_SERVER_URL" ]; then
  CI_SERVER_URL="https://gitlab.com/"
fi

if [ -z "$DOCKER_IMAGE" ]; then
  export DOCKER_IMAGE=docker:20.10.10
fi

if [ -z "$REGISTRATION_TOKEN" ]; then
  echo "ERROR: Env REGISTRATION_TOKEN not set!"
  exit 1
fi

if [ "$ADMIN_TOKEN" != "" ]; then
  REGISTER_OTHER_PROJECTS="true"
  PROJECTS_STRING=`echo "$PROJECTS_TO_REGISTER" | tr ";" ","`
fi

MY_NAME="${CUSTOM_RUNNER_NAME:-$HOSTNAME}"
export RUNNER_NAME="$MY_NAME"

# gitlab-ci-multi-runner data directory
DATA_DIR="/etc/gitlab-runner"
CONFIG_FILE=${CONFIG_FILE:-$DATA_DIR/config.toml}
# custom certificate authority path
CA_CERTIFICATES_PATH=${CA_CERTIFICATES_PATH:-$DATA_DIR/certs/ca.crt}
LOCAL_CA_PATH="/usr/local/share/ca-certificates/ca.crt"

update_ca() {
  echo "Updating CA certificates..."
  cp "${CA_CERTIFICATES_PATH}" "${LOCAL_CA_PATH}"
  update-ca-certificates --fresh >/dev/null
}

if [ -f "${CA_CERTIFICATES_PATH}" ]; then
  # update the ca if the custom ca is different than the current
  cmp --silent "${CA_CERTIFICATES_PATH}" "${LOCAL_CA_PATH}" || update_ca
fi

echo "===> Start Docker..."
service docker start

echo "===> Trap SIGTERM to terminate Gitlab Runner..."
trap "gitlab-runner stop" SIGTERM

echo "===> Running gitlab-runner register..."
export REGISTER_NON_INTERACTIVE=true

gitlab-runner register --executor=docker $REGISTER_EXTRA_ARGS
if [ $? -gt 0 ]; then
  echo "===> ERROR: Registration failed!"
  exit 1
fi


if [ "$REGISTER_OTHER_PROJECTS" == "true" ]; then
  export GITLAB_TOKEN="$ADMIN_TOKEN"
  
  ./gitlab-runner-cleaner.sh register "$RUNNER_NAME" --byId=false --projects "$PROJECTS_STRING"
fi


echo "===> Current version of gitlab-runner:"
gitlab-runner --version

echo "===> Running gitlab-runner run..."
gitlab-runner run

echo "===> Stopping and unregistering..."
gitlab-runner unregister --name "$RUNNER_NAME"

