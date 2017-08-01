#!/bin/bash
PROJECT=realms

set -o errexit   # exit on error

echo "RUN 'createdb $PROJECT'"
echo "AND THEN 'exit'"
sudo -i -u postgres

cp ../dhparams.pem ./dhparams.pem

cp secret.moon.example secret.moon
nano secret.moon
git submodule init     # not using...
git submodule update   # not using...
moonc .
lapis migrate production

./service.sh

echo "Remember to forward to port 7823!"
