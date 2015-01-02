#!/usr/bin/env bats

@test "returns BoxBilling web site" {
  wget -O- http://127.0.0.1 2> /dev/null | grep 'BoxBilling'
}

@test "returns BoxBilling web site in HTTPS" {
  wget --no-check-certificate -O- https://127.0.0.1 2> /dev/null | grep 'BoxBilling'
}

@test "does not return errors" {
  ! wget -O- http://127.0.0.1 2> /dev/null | grep -i 'error'
}
