#!/bin/bash

if ! grep -q "acunetix.com" /etc/hosts; then
    cat /etc/.hosts >> /etc/hosts
fi

exec gosu acunetix bash /home/acunetix/.acunetix/entrypoint.sh
