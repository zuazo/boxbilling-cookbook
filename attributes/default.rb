
default['boxbilling']['download_url'] = 'http://www.boxbilling.com/version/latest.zip'

default['boxbilling']['required_packages'] = %w{ unzip }
default['boxbilling']['php_packages'] = case node['platform']
  when 'redhat', 'centos', 'scientific', 'fedora', 'suse', 'amazon', 'oracle'
    %w{ php-curl php-mcrypt php-mysql }
  when 'debian', 'ubuntu'
    %w{ php5-curl php5-mcrypt php5-mysql }
  else
    Chef::Log.warn("Unknown platform (#{node['platform']}), guessing required package names. You may need to set the node['boxbilling']['php']['packages'] attribute.")
    %w{ php-curl php-mcrypt php-mysql }
end

default['boxbilling']['dir'] = '/srv/www/boxbilling'
default['boxbilling']['server_name'] = node['fqdn']
default['boxbilling']['server_aliases'] = nil
default['boxbilling']['cron_enabled'] = true

default['boxbilling']['ssl'] = false

default['boxbilling']['admin']['name'] = 'Admin'
default['boxbilling']['admin']['email'] = "admin@#{node['boxbilling']['server_name']}"
default['boxbilling']['admin']['pass'] = nil

default['boxbilling']['config']['timezone'] = 'America/New_York' # Available timezones: http://php.net/manual/en/timezones.php
default['boxbilling']['config']['db_host'] = 'localhost'
default['boxbilling']['config']['db_name'] = 'boxbilling'
default['boxbilling']['config']['db_user'] = 'boxbilling'
default['boxbilling']['config']['db_password'] = nil
default['boxbilling']['config']['url'] = "http://#{node['boxbilling']['server_name']}/"
default['boxbilling']['config']['license'] = nil
default['boxbilling']['config']['locale'] = 'en_US'
default['boxbilling']['config']['sef_urls'] = false
default['boxbilling']['config']['debug'] = false
