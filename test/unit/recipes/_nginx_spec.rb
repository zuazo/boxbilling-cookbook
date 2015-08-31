# encoding: UTF-8
#
# Author:: Raul Rodriguez (<raul@onddo.com>)
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2015 Onddo Labs, SL.
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

describe 'boxbilling::_nginx' do
  let(:chef_runner) { ChefSpec::SoloRunner.new }
  let(:chef_run) { chef_runner.converge(described_recipe) }
  let(:node) { chef_runner.node }
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_version)
      .and_return('4.0.0')
    stub_command('which nginx').and_return(true)
    stub_command(
      'test -d /etc/php5/fpm/pool.d || mkdir -p /etc/php5/fpm/pool.d'
    ).and_return(true)
  end

  %w(
    nginx
    boxbilling::_php_fpm
  ). each do |recipe|
    it "includes #{recipe} recipe" do
      expect(chef_run).to include_recipe(recipe)
    end
  end

  it 'disables apache (fix for debian)' do
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:exist?).with('/etc/init.d/apache2')
      .and_return(true)
    expect(chef_run).to stop_service('apache2')
    expect(chef_run).to disable_service('apache2')
  end

  context 'nginx_site default definition' do
    it 'disables default site' do
      allow(::File).to receive(:symlink?).and_call_original
      allow(::File).to receive(:symlink?).with(%r{sites-enabled/default$})
        .and_return(true)
      expect(chef_run).to run_execute('nxdissite default')
    end
  end

  it 'creates nginx boxbilling site' do
    expect(chef_run).to create_template(%r{/sites-available/boxbilling$})
  end

  context 'nginx_site boxbilling definition' do
    it 'enables boxbilling site' do
      allow(::File).to receive(:symlink?).and_call_original
      allow(::File).to receive(:symlink?)
        .with(%r{sites-enabled/boxbilling$}).and_return(false)
      allow(::File).to receive(:symlink?)
        .with(%r{sites-enabled/000-boxbilling$}).and_return(false)
      expect(chef_run).to run_execute('nxensite boxbilling')
    end
  end

  context 'with SSL' do
    it 'creates ssl certificate' do
      expect(chef_run).to create_ssl_certificate('boxbilling')
    end

    it 'creates nginx boxbilling-ssl site' do
      expect(chef_run).to create_template(
        end_with('/sites-available/boxbilling-ssl')
      )
    end

    context 'nginx_site boxbilling-ssl definition' do
      it 'enables boxbilling site' do
        allow(::File).to receive(:symlink?).and_call_original
        allow(::File).to receive(:symlink?)
          .with(%r{sites-enabled/boxbilling-ssl$}).and_return(false)
        allow(::File).to receive(:symlink?)
          .with(%r{sites-enabled/000-boxbilling-ssl$}).and_return(false)
        expect(chef_run).to run_execute('nxensite boxbilling-ssl')
      end
    end # context nginx_site boxbilling-ssl definition
  end # context with SSL
end
