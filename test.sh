#!/usr/bin/env bash
set -e
export TEST_PORT=4567
export USERNAME=Bob
export SECURITY_NUMBER=123456
export PASSWORD="Let me in!"
#rm -rf data
./main.rb
