#!/bin/bash
PROJECT=ld39
DOMAIN=ld39.guard13007.com    # uncomment certbot-auto line below

set -o errexit   # exit on error

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install wget curl lua5.1 liblua5.1-0-dev zip unzip libreadline-dev libncurses5-dev libpcre3-dev openssl libssl-dev perl make build-essential postgresql -y

wget https://dl.eff.org/certbot-auto
chmod a+x ./certbot-auto
mv ./certbot-auto /bin/certbot-auto
certbot-auto certonly --standalone -m paul.liverman.iii@gmail.com -d $DOMAIN

echo "RUN 'createdb ld39'"
echo "THEN 'psql' and:"
echo "  ALTER USER postgres WITH PASSWORD 'password';"
echo "  \q"
echo "AND FINALLY 'exit'"
sudo -i -u postgres

# OpenResty
cd ..
OVER=1.11.2.2
wget https://openresty.org/download/openresty-$OVER.tar.gz
tar xvf openresty-$OVER.tar.gz
cd openresty-$OVER
./configure
make
sudo make install
cd ..

# LuaRocks
LVER=2.4.1
wget https://keplerproject.github.io/luarocks/releases/luarocks-$LVER.tar.gz
tar xvf luarocks-$LVER.tar.gz
cd luarocks-$LVER
./configure
make build
sudo make install
# some rocks
sudo luarocks install lapis
sudo luarocks install luacrypto    # weird error happened before I did this
sudo luarocks install moonscript
sudo luarocks install bcrypt

# cleanup
cd ..
rm -rf openresty*
rm -rf luarocks*

cd $PROJECT

cp secret.moon.example secret.moon
nano secret.moon
git submodule init     # not using...
git submodule update   # not using...
moonc .
lapis migrate production

# $PROJECT as a service

echo "[Unit]
Description=$PROJECT server
[Service]
Type=forking
WorkingDirectory=$(pwd)
ExecStart=$(which lapis) server production
ExecReload=$(which lapis) build production
ExecStop=$(which lapis) term
[Install]
WantedBy=multi-user.target" > $PROJECT.service
sudo cp ./$PROJECT.service /etc/systemd/system/$PROJECT.service
sudo systemctl daemon-reload
sudo systemctl enable $PROJECT.service
service $PROJECT start   # is sudo really not needed?
