boxbilling CHANGELOG
====================

This file is used to list changes made in each version of the `boxbilling` cookbook.

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
