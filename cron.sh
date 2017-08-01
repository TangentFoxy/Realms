#!/bin/bash
crontab -l | { cat; echo "* * * * * curl --insecure https://127.0.0.1:7823/update_realms"; } | crontab -
