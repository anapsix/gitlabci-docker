## gitlabci-docker

This repository is all you need to create your own [Docker](http://docker.io) image of [Gitlab-CI](http://gitlab.org/gitlab-ci/) continuios integration server.
You can find a pre-build image [anapsix/gitlab-ci at Docker INDEX](https://index.docker.io/u/anapsix/gitlab-ci/)


### Usage


If you want to run my pre-build image, just run the following (possibly as sudo):

    docker pull anapsix/gitlab-ci
    docker run -d -p 9000 -e GITLAB_URLS="https://dev.gitlab.org,https://staging.gitlab.org" anapsix/gitlab-ci

You can rebuild the image from scratch with:

    docker build -no-cache -t anapsix/gitlab-ci github.com/anapsix/gitlabci-docker

You must set GITLAB_URLS environmental variable to contain comma delimited list of your GITLAB URLS, otherwise it will refuse to start.


#### Persistent external MySQL DB is now supported!

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

 - You should set MYSQL_SETUP=true only first time you start container if there is no existing DB for specified credentials / host / db name, otherwise, you **WILL LOSE** DB content and all settings. Could be used to jump between incompatible versions, such as 4.x ->  5.x, while overwriting existing DB.


### ENV params
 - `DEBUG` (optional: enables debug messages during container startup)
 - `GITLAB_URLS` (required: set it to full URL of your GitLAB SCM installation)
 - `GITLAB_CI_HOST` (optional: probably helpful when using HTTPS)
 - `GITLAB_CI_HTTPS` (optional: used to enable HTTPS support)
 - `MYSQL_SETUP` (optional: use with caution: initializes DB, wipes it if already present, helpful when upgrading between incompatible versions)
 - `MYSQL_MIGRATE` (optional: use it when upgrading between GitLAB-CI versions, doesn't work between 4.x and 5.x)
 - `MYSQL_HOST` (required for MySQL support, if not set temp SQLite3 will be used)
 - `MYSQL_USER` (optional, will default to gitlabci if not set)
 - `MYSQL_PWD` (optional, will default to gitlabci if not set)
 - `MYSQL_DB` (optional, will default to gitlabci if not set)

### Examples

 - **MYSQL**: only *MYSQL_HOST* variable is required
       *MYSQL_USER*, *MYSQL_PWD* and *MYSQL_DB* will all default to "gitlabci"

        docker run -d -e MYSQL_HOST=10.0.0.100 \
         -e GITLAB_URLS="https://dev.gitlab.org/" \
         -p 9000 anapsix/gitlab-ci


 - **SQLITE3**: to use container-internal ephemeral SQLite3 DB, ommit all *MYSQL_\** variables

        docker run -d -e GITLAB_URLS="https://dev.gitlab.org/" \
         -p 9000 anapsix/gitlab-ci


### Contributors

* Anastas Dancha <anapsix@random.io>
* TruongSinh Tran-Nguyen <i@truongsinh.pro>

### License

MIT

