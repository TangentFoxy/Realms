#!/bin/bash
PROJECT=realms

set -o errexit   # exit on error

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
