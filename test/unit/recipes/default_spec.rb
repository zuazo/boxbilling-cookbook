# encoding: UTF-8
#
# Author:: Raul Rodriguez (<raul@onddo.com>)
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2014-2015 Onddo Labs, SL.
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

require_relative '../spec_helper'

class Chef
  # make `Kernel#require` mockable
  class Recipe
    def require(string)
      Kernel.require(string)
    end
  end
end

describe 'boxbilling::default' do
  let(:db_name) { 'boxbilling_database' }
  let(:db_user) { 'boxbilling_user' }
  let(:db_password) { 'boxbilling_pass' }
  let(:chef_runner) { ChefSpec::SoloRunner.new }
  let(:chef_run) { chef_runner.converge(described_recipe) }
  let(:node) { chef_runner.node }
  before do
    allow(Kernel).to receive(:require).with('sequel')
    allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_database_empty?)
      .and_return(true)
    allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_version)
      .and_return('4.0.0')
    allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_update?)
      .and_return(false)
    allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_fresh_install?)
      .and_return(true)
    stub_command('/usr/sbin/apache2 -t').and_return(true)

    node.set['boxbilling']['config']['db_name'] = db_name
    node.set['boxbilling']['config']['db_user'] = db_user
    node.set['boxbilling']['config']['db_password'] = db_password
    node.set['boxbilling']['admin']['pass'] = 'admin'
  end

  it 'installs unzip package' do
    expect(chef_run).to install_package('unzip')
  end

  it 'includes boxbilling::mysql recipe' do
    expect(chef_run).to include_recipe('boxbilling::mysql')
  end

  it 'includes database::mysql recipe' do
    expect(chef_run).to include_recipe('database::mysql')
  end

  it 'creates mysql database' do
    expect(chef_run).to create_mysql_database(db_name)
  end

  it 'creates mysql database user' do
    expect(chef_run).to grant_mysql_database_user(db_user)
      .with_database_name(db_name)
      .with_host('localhost')
      .with_password(db_password)
      .with_privileges([:all])
  end

  it 'includes boxbilling::_apache recipe' do
    expect(chef_run).to include_recipe('boxbilling::_apache')
  end

  it 'includes php recipe' do
    expect(chef_run).to include_recipe('php')
  end

  %w(php5-curl php5-mcrypt php5-mysql).each do |pkg|
    it "installs #{pkg} package" do
      expect(chef_run).to install_package(pkg)
    end
  end

  it 'creates boxbilling main directory' do
    expect(chef_run).to create_directory('/srv/www/boxbilling')
  end

  it 'downloads boxbilling' do
    expect(chef_run).to create_remote_file_if_missing('download boxbilling')
      .with_path(
        ::File.join(Chef::Config[:file_cache_path], 'BoxBilling-4.0.0.zip')
      )
  end

  it 'extracts boxbilling' do
    expect(chef_run).to run_execute('extract boxbilling')
      .with_command(/^unzip /)
  end

  context 'writable directories' do
    %w(
      /bb-data/cache
      /bb-data/log
      /bb-data/uploads
      /bb-themes/boxbilling/assets
    ).each do |dir|
      it "sets #{dir} directory writable" do
        expect(chef_run).to create_directory(end_with(dir))
          .with_recursive(true)
          .with_owner('www-data')
          .with_group('www-data')
          .with_mode(00750)
      end
    end
  end

  context 'writable files' do
    context 'with boxbilling < 4' do
      before do
        allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_version)
          .and_return('4.0.0')
      end

      %w(
        /bb-themes/boxbilling/config/settings_data.json
      ).each do |file|
        it "sets #{file} file writable" do
          expect(chef_run).to touch_file(end_with(file))
            .with_owner('www-data')
            .with_group('www-data')
            .with_mode(00640)
        end
      end
    end # context with boxbilling < 4

    context 'with boxbilling >= 4' do
      before do
        allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_version)
          .and_return('4.0.0')
      end

      %w(
        /bb-themes/boxbilling/config/settings_data.json
        /bb-themes/huraga/config/settings_data.json
      ).each do |file|
        it "sets #{file} file writable" do
          expect(chef_run).to touch_file(end_with(file))
            .with_owner('www-data')
            .with_group('www-data')
            .with_mode(00640)
        end
      end
    end # context with boxbilling >= 4
  end

  it 'creates bb-config.php file' do
    expect(chef_run).to create_template('bb-config.php')
      .with_owner('www-data')
      .with_group('www-data')
      .with_mode(00640)
  end

  it 'creates .htaccess file' do
    expect(chef_run).to create_template('boxbilling .htaccess')
      .with_owner('www-data')
      .with_group('www-data')
      .with_mode(00640)
  end

  it 'creates database content' do
    expect(chef_run).to query_mysql_database('create database content')
      .with_database_name(db_name)
  end

  it 'create database content notifies create admin user' do
    resource = chef_run.find_resource(
      'mysql_database', 'create database content'
    )
    expect(resource).to notify('boxbilling_api[create admin user]').to(:create)
      .immediately
  end

  it 'does do nothing with create admin user' do
    resource = chef_run.find_resource('boxbilling_api', 'create admin user')
    expect(resource).to do_nothing
  end

  it 'removes installation dir' do
    expect(chef_run).to delete_directory(end_with('/install'))
  end

  it 'enables bb-cron.php cron file' do
    expect(chef_run).to create_cron('boxbilling cron')
      .with_user('www-data')
      .with_minute('*/5')
      .with_command(%r{^php -f '.*/bb-cron.php'$})
  end

  it 'does nothing with update boxbilling' do
    resource = chef_run.execute('update boxbilling')
    expect(resource).to do_nothing
  end

  it 'does nothing with clear cache' do
    resource = chef_run.execute('clear cache')
    expect(resource).to do_nothing
  end

  it 'includes boxbilling::api recipe' do
    expect(chef_run).to include_recipe('boxbilling::api')
  end

  context 'with boxbilling < 4' do
    before do
      allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_version)
        .and_return('3.0.0')
    end

    it 'creates api-config.php file' do
      expect(chef_run).to create_template('api-config.php')
        .with_owner('www-data')
        .with_group('www-data')
        .with_mode(00640)
    end

    it 'does not set /bb-themes/huraga/assets directory writable' do
      expect(chef_run).to_not create_directory(
        end_with('/bb-themes/huraga/assets')
      )
    end

    it 'does not set /bb-themes/huraga/config/settings_data.json file '\
    'writable' do
      expect(chef_run).to_not touch_file(
        end_with('/bb-themes/huraga/config/settings_data.json')
      )
    end
  end

  context 'with boxbilling >= 4' do
    before do
      allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_version)
        .and_return('4.0.0')
    end

    it 'does not create api-config.php file' do
      expect(chef_run).to_not create_template('api-config.php')
    end

    it 'sets /bb-themes/huraga/assets directory writable' do
      expect(chef_run).to create_directory(end_with('/bb-themes/huraga/assets'))
        .with_recursive(true)
        .with_owner('www-data')
        .with_group('www-data')
        .with_mode(00750)
    end

    it 'sets /bb-themes/huraga/config/settings_data.json file writable' do
      settings_json_sufix = '/bb-themes/boxbilling/config/settings_data.json'
      expect(chef_run)
        .to touch_file(end_with(settings_json_sufix))
        .with_owner('www-data')
        .with_group('www-data')
        .with_mode(00640)
    end
  end

  context 'with boxbilling update' do
    before do
      allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_update?)
        .and_return(true)
    end

    it 'extract boxbilling notifies update boxbilling' do
      resource = chef_run.execute('extract boxbilling')
      expect(resource).to notify('execute[update boxbilling]').to(:run)
    end

    it 'update boxbilling notifies clear cache' do
      resource = chef_run.execute('update boxbilling')
      expect(resource).to notify('execute[clear cache]').to(:run)
    end
  end
end
