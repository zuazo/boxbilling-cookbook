# encoding: UTF-8
#
# Author:: Xabier de Zuazo (<xabier@zuazo.org>)
# Copyright:: Copyright (c) 2015 Xabier de Zuazo
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

describe file('/srv/www/boxbilling/bb-uploads/0wn3d.php') do
  it { should be_file }
end

describe file('/srv/www/boxbilling/bb-data/0wn3d.php') do
  it { should be_file }
end

describe server(:web) do
  describe http('/bb-uploads/0wn3d.php') do
    it 'disables PHP files in bb-uploads' do
      expect(response.body).to_not include '0wn3d :-S'
    end

    it 'returns PHP files source in bb-uploads' do
      expect(response.body).to include '<?php'
    end
  end # http /bb-uploads/0wn3d.php

  describe http('/bb-data/0wn3d.php') do
    it 'disables PHP files in bb-data' do
      expect(response.body).to_not include '0wn3d :-S'
    end
  end # http /bb-data/0wn3d.php
end # server web
