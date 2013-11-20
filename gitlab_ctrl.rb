#!/usr/bin/env ruby

require 'yaml'
require 'getoptlong'

GITLAB_HOME = File.expand_path('../',__FILE__)
$app_config_file  = GITLAB_HOME + '/config/application.yml'
$db_config_file   = GITLAB_HOME + '/config/database.yml'
$puma_config_file = GITLAB_HOME + '/config/puma.rb'

# simple db config for sqlite3, replace with your own
# stored as String for easy reading / updates
$db_config =<<EOF
production:
  adapter: sqlite3
  database: db/production.sqlite3
  pool: 5
  timeout: 5000
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
  begin
    File.open($db_config_file, "w") { |f| f.write(YAML.dump(YAML.load($db_config))) }
  rescue
    puts "[FATAL]: Could not write DB config file (#{$db_config_file}), exiting.."
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
  if ENV['GITLAB_URLS'] then
    puts "[DEBUG]: GITLAB_URLS=#{ENV['GITLAB_URLS'][/(?<=GITLAB_URLS=).+/]}" if $DEBUG
    puts "[DEBUG]: GITLAB_HTTPS=#{ENV['GITLAB_HTTPS']}" if $DEBUG
    app_config["production"]["allowed_gitlab_urls"] = ENV['GITLAB_URLS'].split(",")
    # enable HTTPS if GITLAB_HTTPS environmental is set to "true"
    app_config["production"]["gitlab_ci"] = {"https" => true} if ENV['GITLAB_HTTPS'] == "true"

    begin
      puts "[DEBUG]: Writing APP config to #{$app_config_file}" if $DEBUG
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
  puts "[DEBUG]: starting an appication" if $DEBUG
  system('/bin/bash /home/gitlab_ci/gitlab-ci/lib/support/init.d/gitlab_ci start')
  exec('/usr/bin/tail -f /home/gitlab_ci/gitlab-ci/log/*')
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
  (implies --app)
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
      write_app_config
      start_gitlabci
    when '--app'
      ENV['GITLAB_URLS'] = arg if arg != ''
      write_app_config
  end
end

exit 0
# EOF
