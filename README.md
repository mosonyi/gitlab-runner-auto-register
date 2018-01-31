# Gitlab Runner Auto Register

Created according to https://docs.gitlab.com/runner/install/linux-repository.html
With additional flags to enable auto registry with given url and token.
The default image needs additional step of executing script from outside of container which makes it hard to automate deployment.

# Running instructions

To run simply execute: 

```bash
docker run -d -e "CI_SERVER_URL=https://gitlab.com/" \
   -e "REGISTRATION_TOKEN=XXXXXXXXXXXXXX" \
   -e PRIVILIGED_MODE=false \
   --name gitlab-runner \
   flakm/gitlab-runner-auto-register:latest 
```

To check logs and registration status use:

```bash
docker logs gitlab-runner
```

To check registration details:
```bash
docker exec -i gitlab-runner cat /etc/gitlab-runner/config.toml
```

Or register new runner:

```bash
docker exec -i gitlab-runner gitlab-runner register
```

# Environment Variables

- `CI_SERVER_URL` url of gitlab
- `REGISTRATION_TOKEN` /settings/ci_cd tab of your project
- `PRIVILIGED_MODE` should you need to run in priviliged mode set to true (otherwise defaults to false)

For more information about the the environment variables check [here](https://github.com/ayufan/gitlab-ci-multi-runner/blob/master/docs/commands/README.md#gitlab-runner-register
)

# Inspiration

Forked form https://github.com/pcodk/gitlab-runner-auto-register
https://github.com/ayufan/gitlab-ci-multi-runner
