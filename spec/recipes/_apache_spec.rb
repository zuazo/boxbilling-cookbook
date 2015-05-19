# encoding: UTF-8
#
# Author:: Raul Rodriguez (<raul@onddo.com>)
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

describe 'boxbilling::_apache' do
  let(:chef_runner) { ChefSpec::SoloRunner.new }
  let(:chef_run) { chef_runner.converge(described_recipe) }
  let(:node) { chef_runner.node }
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_version)
      .and_return('4.0.0')
    stub_command('/usr/sbin/apache2 -t').and_return(true)
  end

  %w(
    apache2::default
    php
    apache2::mod_php5
    apache2::mod_rewrite
    apache2::mod_headers
  ). each do |recipe|
    it "includes #{recipe} recipe" do
      expect(chef_run).to include_recipe(recipe)
    end
  end

  context 'apache_site default definition' do
    it 'disables default site' do
      allow(::File).to receive(:symlink?).and_call_original
      allow(::File).to receive(:symlink?)
        .with(%r{sites-enabled/default\.conf$}).and_return(true)
      expect(chef_run).to run_execute('a2dissite default.conf')
    end
  end

  context 'web_app boxbilling definition' do
    it 'creates apache2 site' do
      expect(chef_run)
        .to create_template(%r{/sites-available/boxbilling\.conf$})
    end
  end

  context 'ssl' do
    it 'creates ssl certificate' do
      expect(chef_run).to create_ssl_certificate('boxbilling')
    end

    it 'includes apache2::mod_ssl recipe' do
      expect(chef_run).to include_recipe('apache2::mod_ssl')
    end

    context 'web_app boxbilling-ssl definition' do
      it 'creates apache2 site' do
        expect(chef_run).to create_template(
          end_with('/sites-available/boxbilling.conf')
        )
      end
    end
  end # context ssl

  context 'with boxbilling < 4' do
    before do
      allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_version)
        .and_return('3.0.0')
    end

    it 'downloads ioncube' do
      expect(chef_run).to create_remote_file_if_missing('download ioncube')
        .with_path(
          ::File.join(Chef::Config[:file_cache_path], 'ioncube_loaders.tar.gz')
        )
    end

    it 'installs ioncube' do
      expect(chef_run).to run_execute('install ioncube')
        .with_creates(/ioncube\.ini$/)
    end
  end

  context 'with boxbilling >= 4' do
    before do
      allow_any_instance_of(Chef::Recipe).to receive(:boxbilling_version)
        .and_return('4.0.0')
    end

    it 'does not download ioncube' do
      expect(chef_run).to_not create_remote_file_if_missing('download ioncube')
    end

    it 'does not install ioncube' do
      expect(chef_run).to_not run_execute('install ioncube')
    end
  end
end
