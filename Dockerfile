FROM ubuntu:16.04

ADD https://github.com/Yelp/dumb-init/releases/download/v1.0.2/dumb-init_1.0.2_amd64 /usr/bin/dumb-init
RUN chmod +x /usr/bin/dumb-init

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install jq -y && \
    apt-get install -y ca-certificates curl apt-transport-https vim && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# https://docs.gitlab.com/runner/install/linux-repository.html
RUN curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | bash
RUN apt-get -y install gitlab-runner

ADD entrypoint.sh /
ADD gitlab_functions.sh /

RUN chmod +x /entrypoint.sh /gitlab_functions.sh

ENTRYPOINT ["/usr/bin/dumb-init", "/entrypoint.sh"]
CMD ["run", "--user=gitlab-runner", "--working-directory=/home/gitlab-runner"]