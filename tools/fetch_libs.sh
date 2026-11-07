#!/usr/bin/env bash
# Downloads the embedded libraries into Libs/ for local development.
# Release builds get them from the externals in .pkgmeta instead.
set -euo pipefail
cd "$(dirname "$0")/.."

CF=https://repos.curseforge.com/wow
fetch() {
    mkdir -p "$(dirname "$1")"
    curl -fsSL -o "$1" "$2"
}

fetch Libs/LibStub/LibStub.lua "$CF/libstub/trunk/LibStub.lua"
fetch Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua "$CF/callbackhandler/trunk/CallbackHandler-1.0/CallbackHandler-1.0.lua"
fetch Libs/CallbackHandler-1.0/CallbackHandler-1.0.xml "$CF/callbackhandler/trunk/CallbackHandler-1.0/CallbackHandler-1.0.xml"
fetch Libs/LibDataBroker-1.1/LibDataBroker-1.1.lua https://raw.githubusercontent.com/tekkub/libdatabroker-1-1/master/LibDataBroker-1.1.lua
fetch Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua "$CF/libdbicon-1-0/trunk/LibDBIcon-1.0/LibDBIcon-1.0.lua"
fetch Libs/LibDBIcon-1.0/lib.xml "$CF/libdbicon-1-0/trunk/LibDBIcon-1.0/lib.xml"
echo "Libraries downloaded to Libs/"
