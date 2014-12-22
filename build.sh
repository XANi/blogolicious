#!/bin/sh
if ! which carton ; then
    echo "you need to install carton (perl module dep manager) first"
    exit 1
fi

carton install
carton exec perl Makefile.PL
