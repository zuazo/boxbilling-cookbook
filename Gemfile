# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'https://rubygems.org'

group :test do
  gem 'rake'
  gem 'rspec', '~> 3.0'
  gem 'berkshelf', '~> 3.1'
end

group :style do
  gem 'foodcritic', '~> 4.0'
end

group :unit do
  gem 'chefspec', '~> 4.0'
end

group :integration, :kitchen do
  gem 'vagrant', github: 'mitchellh/vagrant'
  gem 'test-kitchen', '~> 1.2'
  gem 'kitchen-vagrant', '~> 0.10'
end

group :integration_cloud, :kitchen_cloud do
  gem 'kitchen-ec2', '~> 0.8'
  gem 'kitchen-digitalocean', '~> 0.7'
end
