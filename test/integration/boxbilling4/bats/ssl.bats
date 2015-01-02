#!/usr/bin/env bats

@test "enables SSL" {
  echo | openssl s_client -connect 127.0.0.1:443
}
