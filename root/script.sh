#!/bin/bash

LOCKFILE="/tmp/myprocess_"
MYPID=$$

function exit_error() {
    echo "Ya hay una instancia en ejecucion. Saliendo"
    exit 1
}

(
    flock -n 3 || exit_error
    echo "Ejecutando lua Sistema.lua"
    cp /root/Config.bak /root/Config.txt
    lua /root/Sistema.lua
) 3> "$LOCKFILE"
