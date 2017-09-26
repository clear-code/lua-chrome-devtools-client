#!/bin/bash

CRYPTO_INCDIR="/usr/local/opt/openssl@1.1/include/"
OPENSSL_INCDIR="/usr/local/opt/openssl@1.1/include/"
OPENSSL_LIBDIR="/usr/local/opt/openssl@1.1/lib/"
CRYPTO_LIBDIR="/usr/local/opt/openssl@1.1/lib/"

git clone https://github.com/kenhys/cqueues.git
cd cqueues
git checkout -b support-luajit210-with-rockspec origin/support-luajit210-with-rockspec
luarocks make cqueues-20161215.51-0.rockspec \
CRYPTO_INCDIR=${CRYPTO_INCDIR} OPENSSL_INCDIR=${OPENSSL_INCDIR} \
OPENSSL_LIBDIR=${OPENSSL_LIBDIR} CRYPTO_LIBDIR=${CRYPTO_LIBDIR}
cd ..

git clone https://github.com/openresty/lua-cjson.git
cd lua-cjson
luarocks make lua-cjson-2.1devel-1.rockspec
cd ..

git clone https://github.com/kenhys/luaossl.git
cd luaossl
git checkout -b support-luajit210-with-rockspec origin/support-luajit210-with-rockspec
luarocks make luaossl-20161214-0.rockspec \
CRYPTO_INCDIR=${CRYPTO_INCDIR} OPENSSL_INCDIR=${OPENSSL_INCDIR} \
OPENSSL_LIBDIR=${OPENSSL_LIBDIR} CRYPTO_LIBDIR=${CRYPTO_LIBDIR}
cd ..

mkdir ./postgresql-client
cd postgresql-client
curl https://raw.githubusercontent.com/clear-code/lua-chrome-devtools-client/master/postgresql-client-0.1-1.rockspec > postgresql-client-0.1-1.rockspec
curl https://raw.githubusercontent.com/clear-code/lua-chrome-devtools-client/master/postgresql-client.lua > postgresql-client.lua
luarocks make postgresql-client-0.1-1.rockspec
cd ..

luarocks install luasocket
luarocks install http
luarocks install lrexlib-oniguruma
luarocks install chrome-devtools-client

rm -rf ./cqueues
rm -rf ./lua-cjson
rm -rf ./luaossl

curl https://raw.githubusercontent.com/clear-code/lua-chrome-devtools-client/master/convert-html-to-xml.lua > convert-html-to-xml.lua

/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --headless --temp-profile --disable-gpu --remote-debugging-port=9222 &
