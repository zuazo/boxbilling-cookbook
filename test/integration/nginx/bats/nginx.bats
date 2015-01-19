#!/usr/bin/env bats

@test "should return nginx server header" {
  wget -q -S 'boxbilling.local' -O- 2>&1 | grep -qF 'Server: nginx'
}
