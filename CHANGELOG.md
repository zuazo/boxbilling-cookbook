boxbilling CHANGELOG
====================

This file is used to list changes made in each version of the `boxbilling` cookbook.

## v1.0.0 (2015-09-01)

* Install BoxBilling 4 by default, adds `node['boxbilling']['version']` attribute (**breaking change**).
* Update chef links to use *chef.io* domain.
* Update contact information and links after migration.
* metadata: Add `source_url` and `issues_url`.

* Documentation:
 * README:
  * Use markdown tables.
  * Improve description.

* Testing:
 * Replace all bats integration tests by [Serverspec](http://serverspec.org/) and [infrataster](https://github.com/ryotarai/infrataster) tests.
 * Fix *already initialized constant* warning.
 * Gemfile: Update RuboCop to `0.33.0`.
 * Move ChefSpec tests to *test/unit*.
 * Add a Guardfile.
 * Rakefile: Add clean task.
 * Travis CI: Run tests on Ruby `2.2`.

## v0.9.0 (2015-05-19)

* Add custom HTTP headers support in nginx.
* Update RuboCop to version `0.31.0`.

## v0.8.0 (2015-03-13)

* `RecipeHelpers#boxbilling_upload_cookbook_file`: Upload files to the root directory instead of *bb-uploads* (disallowed in robots.txt).

## v0.7.0 (2015-02-23)

* Fix `boxbilling_api[admin/system/params]` notifications.
* Disable PHP inside *bb-uploads* and *bb-data* directories.

## v0.6.0 (2015-02-13)

* `boxbilling_api`:
 * Use returned id when updating after a create.
 * Fix method name typo.
 * Use passed args when reading list.
 * Improved handling of borderline cases.
 * Fix condition on same_item?.
 * Handle paths that have slug field.

## v0.5.0 (2015-02-08)

* Update boxbilling when `'download_url'` points to a new version.
* `boxbilling_api`: Add `same_item?` to compare primary keys, support for `'admin/email/template'`.
* Calculate debug mode.
* Fix all RuboCop offenses (big code refactor).
* README: Add codeclimate badge.

## v0.4.1 (2015-01-21)

* Fix disabling nginx default site.

## v0.4.0 (2015-01-20)

* Add nginx support.
* Small improvements.
* Unit tests against Chef 11 and 12.

## v0.3.0 (2015-01-03)

* htaccess: Fix Apache `2.4` support.
* Fix Ubuntu `14` support.
* Add Fedora and RedHat support.
* Add integration tests.
* Update to use `ssl_certificate` cookbook version `1.1.0`.
* metadata: Use pessimistic operator for cookbook versions.
* Enable ChefSpec coverage.
* Gemfile: Use foodcritic fixed version.
* Update license year.

## v0.2.1 (2014-12-25)

* `boxbilling_api`: fix encrypted attributes decryption outside chef solo.

## v0.2.0 (2014-12-18)

* Add BoxBilling `4` support.
* Remove `node['boxbilling']['api_config']['enabled']` attribute from documentation.
* Create writable directory recursively.
* metadata:
 * Fix attribute types.
 * Lock `database` cookbook version.
* Fix version regular expression.
* Refactor ignore failure exception logic.
* Homogenize license headers.
* Add Vagrantfile.
* ChefSpec matchers: Add `boxbilling_api` locator.
* Unit tests integrated with `should_not` gem.
* ChefSpec unit tests clean up.
* Update ChefSpec tests to `4.1`.
* Gemfile: Update `vagrant-wrapper` gem to `2`.
* Berksfile: Document `local_cookbook` method.
* Move *test/kitchen/cookbooks/boxbilling_test* to *test/cookbooks/boxbilling_test*.
* TESTING.md: Some small improvements.
* README:
 * Clean up examples.
 * Small improvements.

## v0.1.1 (2014-11-13)

* Attributes: disable `['encrypt_attributes']` by default.
* Remove `node['boxbilling']['api_config']['enabled']` attribute (not needed).
* Rakefile: include kitchen only in integration tests.
* Gemfile:
 * Update to Berksfile 3.
 * Use `vagrant-wrapper` gem.
 * Add integration groups and disable them in travis-ci.

## v0.1.0 (2014-08-28)

* Initial release of `boxbilling`
