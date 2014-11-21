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

describe 'boxbilling::api' do
  let(:chef_run) { ChefSpec::SoloRunner.new.converge(described_recipe) }
  before { allow(Kernel).to receive(:require).with('sequel') }

  it 'installs sequel gem' do
    expect(chef_run).to install_chef_gem('sequel')
  end

  it 'requires sequel gem' do
    expect(Kernel).to receive(:require).with('sequel').once
    chef_run
  end
end
