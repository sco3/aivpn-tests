#!/usr/bin/env -S bash -x 

sudo ./aivpn-client -k "$(cat client.key)" --adaptive --full-tunnel &> client.log 