#!/bin/bash
ssh-keygen -t rsa
cat id_rsa.pub > authorized_keys
chmod 700 $(pwd)
chmod 600 $(pwd)/authorized_keys
echo ""

cat id_rsa
