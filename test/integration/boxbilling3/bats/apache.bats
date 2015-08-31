#!/usr/bin/env bats

@test "should return apache server header" {
  wget -q -S '127.0.0.1' -O- 2>&1 | grep -qF 'Server: Apache'
}
