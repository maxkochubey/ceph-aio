#!/usr/bin/env bash

set -e

echo "Configuring apt mirrors"
wget -qO - http://apt-mirror.test/repo-key.asc | apt-key add -
echo "deb http://apt-mirror.test/ubuntu/ trusty main multiverse restricted universe" > /etc/apt/sources.list
echo "deb http://apt-mirror.test/ubuntu/ trusty-backports main multiverse restricted universe" >> /etc/apt/sources.list
echo "deb http://apt-mirror.test/ubuntu/ trusty-security main multiverse restricted universe" >> /etc/apt/sources.list
echo "deb http://apt-mirror.test/ubuntu/ trusty-updates main multiverse restricted universe" >> /etc/apt/sources.list
