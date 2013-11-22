gitlabci-docker
===============

This repository is all you need to create your own [Docker](http://docker.io) image of [Gitlab-CI](http://gitlab.org/gitlab-ci/) continuios integration server.
You can find a pre-build image [anapsix/gitlab-ci at Docker INDEX](https://index.docker.io/u/anapsix/gitlab-ci/)


Usage
------------

If you want to run my pre-build image, just run the following (possibly as sudo):

    docker pull anapsix/gitlab-ci
    docker run -d -e GITLAB_URLS="https://dev.gitlab.org,https://staging.gitlab.org" anapsix/gitlab-ci

You can rebuild the image from scratch with:

    docker build -no-cache -t anapsix/gitlab-ci github.com/anapsix/gitlabci-docker

You must set GITLAB_URLS environmental variable to contain comma delimited list of your GITLAB URLS, otherwise it will refuse to start.

Contributors
------------

* Anastas Semenov <anapsix@random.io>

License
-------

MIT
