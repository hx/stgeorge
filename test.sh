#!/usr/bin/env bash
set -e
export TEST_PORT=4567
rm -rf data
./main.rb
