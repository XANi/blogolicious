#!/bin/bash
ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
echo "moving to script's root dir at [$ROOT_DIR]"
cd "$ROOT_DIR"
exec carton exec --  hypnotoad script/blogolicious $@
