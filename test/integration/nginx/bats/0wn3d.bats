#!/usr/bin/env bats

@test "creates bb-uploads 0wn3d PHP file" {
  [ -f /srv/www/boxbilling/bb-uploads/0wn3d.php ]
}

@test "disables PHP files in bb-uploads" {
  ! wget -O- http://127.0.0.1/bb-uploads/0wn3d.php 2> /dev/null \
    | grep -F 0wn3d
}

@test "returns PHP files source in bb-uploads" {
  wget -O- http://127.0.0.1/bb-uploads/0wn3d.php 2> /dev/null \
    | grep -F '<?php'
}

@test "creates bb-data 0wn3d PHP file" {
  [ -f /srv/www/boxbilling/bb-data/0wn3d.php ]
}

@test "disables PHP files in bb-data" {
  ! wget -O- http://127.0.0.1/bb-data/0wn3d.php 2> /dev/null \
    | grep -F 0wn3d
}
