# encoding: UTF-8
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
  gem 'should_not', '~> 1.1'
  gem 'chefspec', '~> 4.1'
end

group :integration do
  gem 'vagrant-wrapper', '~> 1.2'
  gem 'test-kitchen', '~> 1.2'
  gem 'kitchen-vagrant', '~> 0.10'
end

group :integration, :integration_cloud do
  gem 'kitchen-ec2', '~> 0.8'
  gem 'kitchen-digitalocean', '~> 0.8'
end
