Testing
=======

## Requirements

* `vagrant`
* `foodcritic`
* `berkshelf`
* `should_not`
* `chefspec`
* `test-kitchen`
* `kitchen-vagrant`

You must have [VirtualBox](https://www.virtualbox.org/) and [Vagrant](http://www.vagrantup.com/) installed.

You can install gem dependencies with bundler:

    $ gem install bundler
    $ bundle install

## Running the Syntax Style Tests

    $ bundle exec rake style

## Running the Unit Tests

    $ bundle exec rake unit

## Running the Integration Tests

    $ bundle exec rake integration

Or:

    $ bundle exec kitchen list
    $ bundle exec kitchen test
    [...]

### Running Integration Tests in the Cloud

#### Requirements

* `kitchen-vagrant`
* `kitchen-digitalocean`
* `kitchen-ec2`

You can run the tests in the cloud instead of using vagrant. First, you must set the following environment variables:

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_KEYPAIR_NAME`: EC2 SSH public key name. This is the name used in Amazon EC2 Console's Key Pars section.
* `EC2_SSH_KEY_PATH`: EC2 SSH private key local full path. Only when you are not using an SSH Agent.
* `DIGITALOCEAN_CLIENT_ID`
* `DIGITALOCEAN_API_KEY`
* `DIGITALOCEAN_SSH_KEY_IDS`: DigitalOcean SSH numeric key IDs.
* `DIGITALOCEAN_SSH_KEY_PATH`: DigitalOcean SSH private key local full path. Only when you are not using an SSH Agent.

Then, you must configure test-kitchen to use `.kitchen.cloud.yml` configuration file:

    $ export KITCHEN_LOCAL_YAML=".kitchen.cloud.yml"
    $ bundle exec kitchen list
    [...]

## Using Vagrant with the Vagrantfile

### Vagrantfile Requirements

* ChefDK: https://downloads.getchef.com/chef-dk/
* Berkhelf and Omnibus vagrant plugins:
```
$ vagrant plugin install vagrant-berkshelf vagrant-omnibus
```
* The path correctly set for ChefDK:
```
$ export PATH="/opt/chefdk/bin:${PATH}"
```
* Set your license key in the `BB_LICENSE` enviroment variable:
```
$ export BB_LICENSE='PRO-1234'
```

### Vagrantfile Usage

    $ vagrant up

To run Chef again on the same machine:

    $ vagrant provision

The default login credentials are:

* URL: [http://localhost:8080/bb-admin.php](http://localhost:8080/bb-admin.php)
* Email: *test@example.com*
* Password: *4dm1n_p4ss*

To destroy the machine:

    $ vagrant destroy

## ChefSpec Matchers

### boxbilling_api(path)

Helper method for locating a `boxbilling_api` resource in the collection.

```ruby
resource = chef_run.boxbilling_api('admin/system/params')
expect(resource)
  .to notify('boxbilling_api[admin/system/params invoice starting_number]')
  .to(:update).delayed
```

### request_boxbilling_api(path)

Assert that the *Chef Run* makes a `boxbilling_api` request.

```ruby
expect(chef_run).to request_boxbilling_api(path)
```

### create_boxbilling_api(path)

Assert that the *Chef Run* makes a `boxbilling_api` create request.

```ruby
expect(chef_run).to create_boxbilling_api(path)
```

### update_boxbilling_api(path)

Assert that the *Chef Run* makes a `boxbilling_api` update request.

```ruby
expect(chef_run).to update_boxbilling_api(path)
```

### delete_boxbilling_api(path)

Assert that the *Chef Run* makes a `boxbilling_api` delete request.

```ruby
expect(chef_run).to delete_boxbilling_api(path)
```
