#!/bin/bash
crontab -l | { cat; echo "* * * * * curl --insecure https://127.0.0.1/update_realms && curl -sm 30 k.wdt.io/paul.liverman.iii@gmail.com/ld39-minute?c=*_*_*_*_*"; } | crontab -
