#!/usr/bin/env ruby

require 'yaml'
require 'getoptlong'

GITLAB_HOME = File.expand_path('../',__FILE__)
$app_config_file  = GITLAB_HOME + '/config/application.yml'
$db_config_file   = GITLAB_HOME + '/config/database.yml'
$puma_config_file = GITLAB_HOME + '/config/puma.rb'

# simple db config for sqlite3, replace with your own
# stored as String for easy reading / updates
$db_config_sqlite3 =<<EOF
production:
  adapter: sqlite3
  database: db/production.sqlite3
  pool: 5
  timeout: 5000
EOF

$db_config_mysql =<<EOF
production:
  adapter: mysql2
  encoding: utf8
  reconnect: false
  host: #{ENV['MYSQL_HOST']}
  port: #{ENV['MYSQL_PORT']||3306}
  database: #{ENV['MYSQL_DB']||"gitlabci"}
  pool: 10
  username: #{ENV['MYSQL_USER']||"gitlabci"}
  password: #{ENV['MYSQL_PWD']||"gitlabci"}
EOF

$puma_config =<<EOF
#!/usr/bin/env puma
application_path = '/home/gitlab_ci/gitlab-ci'
directory application_path
environment = :production
daemonize true
pidfile "\#{application_path}/tmp/pids/puma.pid"
state_path "\#{application_path}/tmp/pids/puma.state"
stdout_redirect "\#{application_path}/log/puma.stdout.log", "\#{application_path}/log/puma.stderr.log"
bind 'tcp://0.0.0.0:9000'
workers 2
EOF

# write DB config
def write_db_config
  if ENV['MYSQL_HOST']
    print "[DEBUG]: Writing Database config file for MySQL.." if ENV['DEBUG']
    begin
      File.open($db_config_file, "w") { |f| f.write(YAML.dump(YAML.load($db_config_mysql))) }
    rescue
      puts "\n[FATAL]: Could not write DB config file (#{$db_config_file}), exiting.."
    else
      puts " ok" if ENV['DEBUG']
    end
  else
    print "[DEBUG]: Writing Database config file for SQLite3.." if ENV['DEBUG']
    begin
      File.open($db_config_file, "w") { |f| f.write(YAML.dump(YAML.load($db_config_sqlite3))) }
    rescue
      puts "\n[FATAL]: Could not write DB config file (#{$db_config_file}), exiting.."
    else
      puts " ok" if ENV['DEBUG']
    end
    print "[DEBUG]: setting up SQLite3 db via db:setup rake task.." if ENV['DEBUG']
    system('sudo -u gitlab_ci -H bundle exec rake db:setup RAILS_ENV=production')
    if $?.success?
      puts "\n[DEBUG]: SQLite3 setup ok" if ENV['DEBUG']
    else
      puts "\n[FATAL]: could not setup SQLite3 via db:setup, exiting.."
      exit 1
    end
  end

  # setup DB is MYSQL_SETUP flag is set to "true"
  if ENV['MYSQL_HOST'] && ENV['MYSQL_SETUP'] == "true"
    print "[DEBUG]: setting up MySQL db via db:setup rake task\n" if ENV['DEBUG']
    system('sudo -u gitlab_ci -H bundle exec rake db:setup RAILS_ENV=production')
    if $?.success?
      puts "\n[DEBUG]: MySQL setup ok" if ENV['DEBUG']
    else
      puts "\n[FATAL]: could not run db:setup, exiting.."
      exit 1
    end
  else
    puts "[DEBUG]: Using pre-existing MySQL DB, it's better be all setup.." if ENV['DEBUG'] && ENV['MYSQL_HOST']
  end
end

# write PUMA config
def write_puma_config
  begin
    File.open($puma_config_file, "w") { |f| f.write($puma_config) }
  rescue
    puts "[FATAL]: Could not write PUMA config file (#{$puma_config_file}), exiting.."
  end
end

# write application.yml config
def write_app_config
  # read app config from example file
  app_config = YAML.load_file($app_config_file + '.example')

  # check GITLAB_URLS environmental and bail if not set
  if ENV['GITLAB_HTTPS'] then
    puts "[FATAL]: GITLAB_HTTPS has been renamed to GITLAB_CI_HTTPS"
    exit 1
  end
  # check GITLAB_URLS environmental and bail if not set
  if ENV['GITLAB_URLS'] then
    puts "[DEBUG]: GITLAB_URLS=#{ENV['GITLAB_URLS']}" if ENV['DEBUG']
    puts "[DEBUG]: GITLAB_CI_HOST=#{ENV['GITLAB_CI_HOST']||localhost}" if ENV['DEBUG']
    puts "[DEBUG]: GITLAB_CI_HTTPS=#{ENV['GITLAB_CI_HTTPS']||false}" if ENV['DEBUG']
    app_config["production"]["allowed_gitlab_urls"] = ENV['GITLAB_URLS'].split(",")
    app_config["production"]["gitlab_ci"]["host"] = ENV['GITLAB_CI_HOST'] || "localhost"
    # enable HTTPS if GITLAB_CI_HTTPS environmental is set to "true"
    app_config["production"]["gitlab_ci"]["https"] = true if ENV['GITLAB_CI_HTTPS'] == "true"

    begin
      puts "[DEBUG]: Writing APP config to #{$app_config_file}" if ENV['DEBUG']
      File.open($app_config_file, "w") { |f| f.write(YAML.dump(app_config)) }
    rescue
      puts "[FATAL]: Could not write APP config file (#{$app_config_file}), exiting.."
      exit 1
    end
  else
    puts "[FATAL]: Cannot continue without GITLAB_URLS environmental variable, exiting.."
    exit 1
  end
end

def start_gitlabci
  puts "[DEBUG]: starting services.." if ENV['DEBUG']
  system('/bin/bash /etc/init.d/cron restart')
  system('/bin/bash /etc/init.d/redis-server restart')
  system('/bin/bash /home/gitlab_ci/gitlab-ci/lib/support/init.d/gitlab_ci start')
  exec('/usr/bin/tail -F /home/gitlab_ci/gitlab-ci/log/*')
end

# help
def help
puts <<-EOF
#{$0} [-h|--help] [--db] [--puma] [--app "http://dev.gitlab.org"] [--start]

-h, --help:
    show help

--db:
  create db config

--puma:
  create puma config

--app [ "http://dev.gitlab.org,https://dev.gitlab.org" ]
  create application config, optionally passing a comma delimited list of allowed gitlab urls

--start
  (implies --app and --db)
  start an appication

EOF
end

$DEBUG = false
help if ARGV.length == 0

opts = GetoptLong.new(
  [ '--debug', '-d', GetoptLong::NO_ARGUMENT ],
  [ '--help', '-h', GetoptLong::NO_ARGUMENT ],
  [ '--db', GetoptLong::NO_ARGUMENT ],
  [ '--puma', GetoptLong::NO_ARGUMENT ],
  [ '--start', GetoptLong::NO_ARGUMENT ],
  [ '--app', GetoptLong::OPTIONAL_ARGUMENT ]
)

opts.each do |opt, arg|
  case opt
    when '--help'
      help
    when '--debug'
      $DEBUG = true
    when '--db'
      write_db_config
    when '--puma'
      write_puma_config
    when '--start'
      write_db_config
      write_app_config
      start_gitlabci
    when '--app'
      ENV['GITLAB_URLS'] = arg if arg != ''
      write_app_config
  end
end

exit 0
# EOF
