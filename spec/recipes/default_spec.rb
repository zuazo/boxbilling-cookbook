# encoding: UTF-8
#
# Author:: Xabier de Zuazo (<xabier@onddo.com>)
# Copyright:: Copyright (c) 2014 Onddo Labs, SL. (www.onddo.com)
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'spec_helper'

# make `Kernel#require` mockable
class Chef::Recipe
  def require(string)
    Kernel.require(string)
  end
end

describe 'boxbilling::default' do
  let(:db_name) { 'boxbilling_database' }
  let(:db_user) { 'boxbilling_user' }
  let(:db_password) { 'boxbilling_pass' }
  let(:chef_run) do
    ChefSpec::Runner.new do |node|
      node.set['boxbilling']['config']['db_name'] = db_name
      node.set['boxbilling']['config']['db_user'] = db_user
      node.set['boxbilling']['config']['db_password'] = db_password
      node.set['boxbilling']['admin']['pass'] = 'admin'
    end.converge(described_recipe)
  end
  before do
    allow(Kernel).to receive(:require).with('sequel')
    stub_command('/usr/sbin/apache2 -t').and_return(true)
  end

  it 'should install unzip package' do
    expect(chef_run).to install_package('unzip')
  end

  it 'should include php recipe' do
    expect(chef_run).to include_recipe('php')
  end

  %w(php5-curl php5-mcrypt php5-mysql).each do |pkg|
    it "should install #{pkg} package" do
      expect(chef_run).to install_package(pkg)
    end
  end

  it 'should download ioncube' do
    expect(chef_run).to create_remote_file_if_missing('download ioncube')
      .with_path(::File.join(Chef::Config[:file_cache_path], 'ioncube_loaders.tar.gz'))
  end

  it 'should install ioncube' do
    expect(chef_run).to run_execute('install ioncube')
      .with_creates(/ioncube\.ini$/)
  end

  it 'should include boxbilling::mysql recipe' do
    expect(chef_run).to include_recipe('boxbilling::mysql')
  end

  it 'should include database::mysql recipe' do
    expect(chef_run).to include_recipe('database::mysql')
  end

  it 'should create mysql database' do
    expect(chef_run).to create_mysql_database(db_name)
  end

  it 'should create mysql database user' do
    expect(chef_run).to grant_mysql_database_user(db_user)
      .with_database_name(db_name)
      .with_host('localhost')
      .with_password(db_password)
      .with_privileges([:all])
  end

  it 'should create boxbilling main directory' do
    expect(chef_run).to create_directory('/srv/www/boxbilling')
  end

  it 'should download boxbilling' do
    expect(chef_run).to create_remote_file_if_missing('download boxbilling')
      .with_path(::File.join(Chef::Config[:file_cache_path], 'latest.zip'))
  end

  it 'should extrac boxbilling' do
    expect(chef_run).to run_execute('extract boxbilling')
      .with_command(/^unzip /)
      .with_creates(/\/index\.php$/)
  end

  %w(
    apache2::default
    apache2::mod_php5
    apache2::mod_rewrite
    apache2::mod_headers
  ). each do |recipe|
    it "should include #{recipe} recipe" do
      expect(chef_run).to include_recipe(recipe)
    end
  end

  context 'apache_site default definition' do
    it 'should disable default site' do
      allow(::File).to receive(:symlink?).with(any_args).and_return(false)
      allow(::File).to receive(:symlink?).with(/sites-enabled\/default\.conf$/).and_return(true)
      expect(chef_run).to run_execute('a2dissite default.conf')
    end
  end

  context 'web_app boxbilling definition' do
    it 'should create apache2 site' do
      expect(chef_run).to create_template(/\/sites-available\/boxbilling\.conf$/)
    end
  end

  context 'ssl' do

    it 'should create ssl certificate' do
      expect(chef_run).to create_ssl_certificate('boxbilling')
    end

    it 'should include apache2::mod_ssl recipe' do
      expect(chef_run).to include_recipe('apache2::mod_ssl')
    end

    context 'web_app boxbilling-ssl definition' do
      it 'should create apache2 site' do
        expect(chef_run).to create_template(
          end_with('/sites-available/boxbilling.conf')
        )
      end
    end

  end # context ssl

  context 'writable directories' do
    %w(
      /bb-data/cache
      /bb-data/log
      /bb-data/uploads
      /bb-themes/boxbilling/assets
    ).each do |dir|
      it "should set #{dir} directory writable" do
        expect(chef_run).to create_directory(end_with(dir))
          .with_owner('www-data')
          .with_group('www-data')
          .with_mode(00750)
      end
    end
  end

  context 'writable files' do
    %w(
      /bb-themes/boxbilling/config/settings.html
      /bb-themes/boxbilling/config/settings_data.json
    ).each do |file|
      it "should set #{file} file writable" do
        expect(chef_run).to touch_file(end_with(file))
          .with_owner('www-data')
          .with_group('www-data')
          .with_mode(00640)
      end
    end
  end

  it 'should set bb-config.php file permissions' do
    expect(chef_run).to create_file_if_missing('bb-config.php')
      .with_owner('www-data')
      .with_group('www-data')
      .with_mode(00640)
  end

  it 'bb-config.php should notify setup' do
    resource = chef_run.file('bb-config.php')
    expect(resource).to notify('ruby_block[run boxbilling setup]').to(:create).immediately
  end

  it 'should do nothing with boxbilling setup' do
    resource = chef_run.ruby_block('run boxbilling setup')
    expect(resource).to do_nothing
  end

  it 'should remove installation dir' do
    expect(chef_run).to delete_directory(end_with('/install'))
  end

  it 'should create bb-config.php file' do
    expect(chef_run).to create_template('bb-config.php')
      .with_owner('www-data')
      .with_group('www-data')
      .with_mode(00640)
  end

  it 'should create api-config.php file' do
    expect(chef_run).to create_template('api-config.php')
      .with_owner('www-data')
      .with_group('www-data')
      .with_mode(00640)
  end

  it 'should create .htaccess file' do
    expect(chef_run).to create_template('boxbilling .htaccess')
      .with_owner('www-data')
      .with_group('www-data')
      .with_mode(00640)
  end

  it 'should enable bb-cron.php cron file' do
    expect(chef_run).to create_cron('boxbilling cron')
      .with_user('www-data')
      .with_minute('*/5')
      .with_command(/^php -f '.*\/bb-cron.php'$/)
  end

  it 'should include boxbilling::api recipe' do
    expect(chef_run).to include_recipe('boxbilling::api')
  end

end
