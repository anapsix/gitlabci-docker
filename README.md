gitlabci-docker
===============

This repository is all you need to create your own [Docker](http://docker.io) image of [Gitlab-CI](http://gitlab.org/gitlab-ci/) continuios integration server.
You can find a pre-build image [anapsix/gitlab-ci at Docker INDEX](https://index.docker.io/u/anapsix/gitlab-ci/)


Usage
------------

If you want to run my pre-build image, just run the following (possibly as sudo):

    docker pull anapsix/gitlab-ci
    docker run -d -p 9000 -e GITLAB_URLS="https://dev.gitlab.org,https://staging.gitlab.org" anapsix/gitlab-ci

You can rebuild the image from scratch with:

    docker build -no-cache -t anapsix/gitlab-ci github.com/anapsix/gitlabci-docker

You must set GITLAB_URLS environmental variable to contain comma delimited list of your GITLAB URLS, otherwise it will refuse to start.


Persistent external MySQL DB is now supported:

You can now use external persistent MySQL DB for your GitLab-CI container.
Launch the instance like so:

    docker run -d \
     -e DEBUG=true \
     -e MYSQL_SETUP=true \
     -e MYSQL_HOST=10.0.0.100 \
     -e MYSQL_USER="gitlabci" \
     -e MYSQL_PWD="gitlabci" \
     -e MYSQL_DB="gitlabci" \
     -e GITLAB_URLS="https://dev.gitlab.org/" \
     -p 9000 anapsix/gitlab-ci

 **WARNING**: every time you pass *MYSQL_SETUP=true*, it will overwrite an existing MySQL database..

 - You should set MYSQL_SETUP=true only first time you start container only if there is no existing DB for specified credentials / host / db name, otherwise, you **WILL LOSE**

 ## ENV Params
 - DEBUG
 - MYSQL_SETUP
 - MYSQL_MIGRATE
 - MYSQL_HOST
 - MYSQL_USER
 - MYSQL_PWD
 - MYSQL_DB
 - GITLAB_URLS
 - GITLAB_CI_HOST
 - GITLAB_CI_HTTPS
 
Examples
------------

 - **MYSQL**: only *MYSQL_HOST* variable is required
       *MYSQL_USER*, *MYSQL_PWD* and *MYSQL_DB* will all default to "gitlabci"

        docker run -d -e MYSQL_HOST=10.0.0.100 \
         -e GITLAB_URLS="https://dev.gitlab.org/" \
         -p 9000 anapsix/gitlab-ci


 - **SQLITE3**: to use container-internal ephemeral SQLite3 DB, ommit all *MYSQL_\** variables

        docker run -d -e GITLAB_URLS="https://dev.gitlab.org/" \
         -p 9000 anapsix/gitlab-ci


Contributors
------------

* Anastas Semenov <anapsix@random.io>
* TruongSinh Tran-Nguyen <i@truongsinh.pro>

License
-------

MIT
