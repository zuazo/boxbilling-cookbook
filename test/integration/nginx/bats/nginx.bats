#!/usr/bin/env bats

@test "should return nginx server header" {
  wget -q -S '127.0.0.1' -O- 2>&1 | grep -qF 'Server: nginx'
}
