if [ ! -e cpanfile.snapshot ] ; then
    carton install
fi
mkdir -p tmp/test
if [ "z$BUILD_NUMBER" = "z" ] ; then
    # probably not jenkins
    rm -f tmp/test/out.tap
    carton exec -- prove -l -r -v |tee tmp/test/out.tap
else 
    # probably something that is jenkins like
    rm -f tmp/test/out.xml
    carton exec -- prove -l -r -v --formatter=TAP::Formatter::JUnit | tee tmp/test/out.xml
fi

