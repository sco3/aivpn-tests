#!/usr/bin/env -S bash


if [ ! -f server.key ] ; then 
    openssl rand 32 | sudo tee server.key 
fi

chmod 600 server.key