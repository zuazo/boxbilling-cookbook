boxbilling CHANGELOG
====================

This file is used to list changes made in each version of the `boxbilling` cookbook.

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
