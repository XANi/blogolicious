#!/bin/bash
ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "moving to script's root dir at [$ROOT_DIR]"
cd "$ROOT_DIR"
if [ ! -e cpanfile.snapshot ]; then
    echo "No cpanfile.snapshot found, running install"
    ./build.sh
fi
carton exec morbo script/blogolicious
