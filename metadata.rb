name             'boxbilling'
maintainer       'Onddo Labs, Sl.'
maintainer_email 'team@onddo.com'
license          'Apache 2.0'
description      'Installs and configures BoxBilling, invoice and client management software'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

supports 'amazon'
supports 'centos', '>= 6.0'
supports 'debian'
supports 'ubuntu'

depends 'apache2'
depends 'database'
depends 'encrypted_attributes', '~> 0.2'
depends 'mysql', '~> 5.0'
depends 'openssl'
depends 'php'
depends 'ssl_certificate'
depends 'yum-epel'

recipe 'boxbilling::default', 'Installs and configures BoxBilling. Including the MySQL server if set to localhost.'
recipe 'boxbilling::api', 'Installs the requirementes to use boxbilling_api resource.'
recipe 'boxbilling::mysql', 'Installs MySQL server for BoxBilling.'

provides 'boxbilling_api'

attribute 'boxbilling/download_url',
  :display_name => 'boxbilling download url',
  :description => 'BoxBilling download URL.',
  :type => 'string',
  :default => '"http://www.boxbilling.com/version/latest.zip"'

attribute 'boxbilling/required_packages',
  :display_name => 'boxbilling required packages',
  :description => 'BoxBilling required packages.',
  :type => 'string',
  :default => '%w(unzip)'

attribute 'boxbilling/php_packages',
  :display_name => 'boxbilling php packages',
  :description => 'BoxBilling required PHP packages.',
  :type => 'string',
  :calculated => true

attribute 'boxbilling/dir',
  :display_name => 'boxbilling directory',
  :description => 'BoxBilling installation directory.',
  :type => 'string',
  :default => '"/srv/www/boxbilling"'

attribute 'boxbilling/server_name',
  :display_name => 'boxbilling server',
  :description => 'BoxBilling server name.',
  :type => 'string',
  :default => 'node["fqdn"]'

attribute 'boxbilling/cron_enabled',
  :display_name => 'boxbilling cron enabled',
  :description => 'Whether to enable BoxBilling cron job.',
  :type => 'string',
  :choice => [ 'true', 'false' ],
  :default => 'true'

attribute 'boxbilling/headers',
  :display_name => 'boxbilling headers',
  :description => 'BoxBilling HTTP headers to set as hash.',
  :type => 'string',
  :default => '{}'

attribute 'boxbilling/ssl',
  :display_name => 'boxbilling ssl',
  :description => 'Whether to enable SSL in BoxBilling.',
  :type => 'string',
  :choice => [ 'true', 'false' ],
  :default => 'true'

attribute 'boxbilling/encrypt_attributes',
  :display_name => 'boxbilling encrypt attributes',
  :description => 'Whether to encrypt BoxBilling attributes containing credential secrets.',
  :type => 'string',
  :choice => [ 'true', 'false' ],
  :default => 'false'

attribute 'boxbilling/admin/name',
  :display_name => 'boxbilling admin name',
  :description => 'BoxBilling admin user name.',
  :type => 'string',
  :default => '"Admin"'

attribute 'boxbilling/admin/email',
  :display_name => 'boxbilling admin email',
  :description => 'BoxBilling admin email.',
  :type => 'string',
  :calculated => true

attribute 'boxbilling/admin/pass',
  :display_name => 'boxbilling admin pass',
  :description => 'BoxBilling admin password.',
  :type => 'string',
  :calculated => true

attribute 'boxbilling/config/timezone',
  :display_name => 'boxbilling config timezone',
  :description => 'BoxBilling timezone. See http://php.net/manual/en/timezones.php.',
  :type => 'string',
  :default => '"America/New_York"'

attribute 'boxbilling/config/db_host',
  :display_name => 'boxbilling config db host',
  :description => 'BoxBilling database host.',
  :type => 'string',
  :default => '"localhost"'

attribute 'boxbilling/config/db_name',
  :display_name => 'boxbilling config db name',
  :description => 'BoxBilling database name.',
  :type => 'string',
  :default => '"boxbilling"'

attribute 'boxbilling/config/db_user',
  :display_name => 'boxbilling config db user',
  :description => 'BoxBilling database user.',
  :type => 'string',
  :default => '"boxbilling"'

attribute 'boxbilling/config/db_password',
  :display_name => 'boxbilling config db password',
  :description => 'BoxBilling database user password.',
  :type => 'string',
  :calculated => true

attribute 'boxbilling/config/url',
  :display_name => 'boxbilling config url',
  :description => 'BoxBilling URL.',
  :type => 'string',
  :calculated => true

attribute 'boxbilling/config/license',
  :display_name => 'boxbilling config license',
  :description => 'BoxBilling license key.',
  :required => 'required',
  :type => 'string',
  :default => 'nil'

attribute 'boxbilling/config/locale',
  :display_name => 'boxbilling config locale',
  :description => 'BoxBilling locale.',
  :type => 'string',
  :default => '"en_US"'

attribute 'boxbilling/config/sef_urls',
  :display_name => 'boxbilling config sef urls',
  :description => 'Whether to enable BoxBilling search engine friendly URLs.',
  :type => 'string',
  :choice => [ 'true', 'false' ],
  :default => 'false'

attribute 'boxbilling/config/debug',
  :display_name => 'boxbilling config debug',
  :description => 'Whether to enable BoxBilling debug.',
  :type => 'string',
  :choice => [ 'true', 'false' ],
  :default => 'false'

attribute 'boxbilling/api_config/enabled',
  :display_name => 'boxbilling api config enabled',
  :description => 'Whether to generate API configuration file (api-config.php).',
  :type => 'string',
  :choice => [ 'true', 'false' ],
  :default => 'true'

attribute 'boxbilling/api_config/require_referer_header',
  :display_name => 'boxbilling api config require referer header',
  :description => 'Whether to enable require referer header in the API.',
  :type => 'string',
  :choice => [ 'true', 'false' ],
  :default => 'true'

attribute 'boxbilling/api_config/allowed_ips',
  :display_name => 'boxbilling api config allowed ips',
  :description => 'BoxBilling allowed IP addresses to access the API. Empty array will allow all IPs to access the API.',
  :type => 'string',
  :default => '[]'

attribute 'boxbilling/api_config/rate_span',
  :display_name => 'boxbilling api config rate span',
  :description => 'BoxBilling API time span for limit in seconds.',
  :type => 'string',
  :default => '3600'

attribute 'boxbilling/api_config/rate_limit',
  :display_name => 'boxbilling api config rate limit',
  :description => 'BoxBilling API requests allowed per time span.',
  :type => 'string',
  :default => '1000'

attribute 'boxbilling/mysql/server_root_password',
  :display_name => 'boxbilling mysql server root password',
  :description => 'BoxBilling MySQL root password.',
  :type => 'string',
  :calculated => true

attribute 'boxbilling/mysql/server_debian_password',
  :display_name => 'boxbilling mysql server debian password',
  :description => 'BoxBilling MySQL debian user password.',
  :type => 'string',
  :calculated => true

attribute 'boxbilling/mysql/server_repl_password',
  :display_name => 'boxbilling mysql server repl password',
  :description => 'BoxBilling MySQL repl user password.',
  :type => 'string',
  :calculated => true
