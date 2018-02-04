#!/usr/bin/env bash

if [ -z "$CI_SERVER_URL" ]; then
  CI_SERVER_URL="https://gitlab.com/"
fi

if [ -z "$REGISTRATION_TOKEN" ]; then
  echo "ERROR: Env REGISTRATION_TOKEN not set!"
  exit 1
fi

if [ "$PRIVILIGED_MODE" != "true" ]; then
  PRIVILIGED_MODE="false"
fi

if [ "$LOCKED_MODE" != "true" ]; then
  LOCKED_MODE="true"
fi

if [ "$ADMIN_TOKEN" != "" ]; then
  REGISTER_OTHER_PROJECTS="true"
  PROJECTS_STRING="$PROJECTS_TO_REGISTER"
fi

if [ "$CUSTOM_RUNNER_NAME" != "" ]; then
  export RUNNER_NAME="$CUSTOM_RUNNER_NAME"
else
  export RUNNER_NAME="$HOSTNAME"
fi

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

gitlab-runner register --executor=docker --locked=$LOCKED_MODE --docker-image=docker:latest  --docker-privileged=$PRIVILIGED_MODE --docker-volumes=/var/run/docker.sock:/var/run/docker.sock
if [ $? -gt 0 ]; then
  echo "===> ERROR: Registration failed!"
  exit 1
fi


if [ "$REGISTER_OTHER_PROJECTS" == "true" ]; then
  source ./gitlab_functions.sh
  RUNNER_ID=$(getRunnerIdByDescription "$RUNNER_NAME" "$CI_SERVER_URL" "$ADMIN_TOKEN")

  projects=$(echo "$PROJECTS_STRING" | tr ";" "\n")

  for PROJECT_ID in $projects
  do
      echo "registering runner $RUNNER_ID to [$PROJECT_ID]"
      registerRunnerToProject "$RUNNER_ID" "$PROJECT_ID" "$CI_SERVER_URL" "$ADMIN_TOKEN"
  done  
fi


echo "===> Current version of gitlab-runner:"
gitlab-runner --version

echo "===> Running gitlab-runner run..."
gitlab-runner run

echo "===> Stopping and unregistering..."
gitlab-runner unregister --name "$RUNNER_NAME"

