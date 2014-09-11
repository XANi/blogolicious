if [ ! -e cpanfile.snapshot ] ; then
    carton install
fi

carton exec -- prove -l -r -v
