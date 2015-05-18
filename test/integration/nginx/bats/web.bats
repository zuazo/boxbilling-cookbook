#!/usr/bin/env bats

@test "returns BoxBilling web site" {
  wget -O- http://boxbilling.local 2> /dev/null | grep 'BoxBilling'
}

@test "returns BoxBilling web site in HTTPS" {
  wget --no-check-certificate -O- https://boxbilling.local 2> /dev/null | grep 'BoxBilling'
}

@test "does not return errors" {
  ! wget -O- http://boxbilling.local 2> /dev/null | grep -i 'error'
}

@test "should return custom headers" {
  wget -q -S http://boxbilling.local -O- 2>&1 | \
    grep -qF 'X-Test-Header: Test Header'
}
