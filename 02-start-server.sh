#!/usr/bin/env -S bash -x 

RUST_LOG_STYLE=never  sudo RUST_LOG_STYLE=never    ./aivpn-server --listen 0.0.0.0:443 --key-file server.key  --clients-db clients.json  &> server.log  