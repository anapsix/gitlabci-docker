FROM tianon/debian

MAINTAINER Anastas Semenov <anapsix@random.io>

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes libxml2-dev libxslt-dev libcurl4-openssl-dev libreadline6-dev libc6-dev libssl-dev libyaml-dev libicu-dev zlib1g-dev libsqlite3-dev wget curl gcc build-essential make git sudo postfix cron ruby1.9.1 ruby1.9.1-dev rubygems-integration redis-server
RUN gem install bundle --no-ri --no-rdoc

RUN adduser --disabled-login --gecos 'GitLab CI' gitlab_ci

RUN cd /home/gitlab_ci; sudo -u gitlab_ci -H git clone -b 3-2-stable --depth 1 https://github.com/gitlabhq/gitlab-ci.git gitlab-ci
RUN cd /home/gitlab_ci/gitlab-ci; sudo -u gitlab_ci -H mkdir -p tmp/pids tmp/sockets
RUN cd /home/gitlab_ci/gitlab-ci; curl -sL https://raw.github.com/anapsix/gitlabci-docker/master/BUNDLER-adding-sqlite3-support.patch | sudo -u gitlab_ci -H git am
RUN cd /home/gitlab_ci/gitlab-ci; sudo -u gitlab_ci -H bundle install --without development test postgres mysql --deployment
RUN cd /home/gitlab_ci/gitlab-ci; sudo -u gitlab_ci -H curl -sL https://raw.github.com/anapsix/gitlabci-docker/master/gitlab_ctrl.rb > ./gitlabci_ctrl.rb; chmod +x ./gitlabci_ctrl.rb
RUN cd /home/gitlab_ci/gitlab-ci; sudo -u gitlab_ci -H ./gitlabci_ctrl.rb --db --puma --app GITLAB_URLS="https://dev.gitlab.org/"
RUN cd /home/gitlab_ci/gitlab-ci; sudo -u gitlab_ci -H bundle exec rake db:setup RAILS_ENV=production
RUN cd /home/gitlab_ci/gitlab-ci; sudo -u gitlab_ci -H bundle exec whenever -w RAILS_ENV=production

# cleanup, if needed
#RUN DEBIAN_FRONTEND=noninteractive apt-get remove --force-yes -y ruby1.9.1-dev
#RUN DEBIAN_FRONTEND=noninteractive apt-get autoremove --force-yes -y

EXPOSE 9000

WORKDIR /home/gitlab_ci/gitlab-ci
CMD /home/gitlab_ci/gitlab-ci/gitlabci_ctrl.rb --start