#!/bin/bash

git clone https://github.com/kenhys/cqueues.git
cd cqueues
git checkout -b support-luajit210-with-rockspec origin/support-luajit210-with-rockspec 
luarocks make cqueues-20161215.51-0.rockspec
cd ..

git clone https://github.com/openresty/lua-cjson.git
cd lua-cjson
luarocks make lua-cjson-2.1devel-1.rockspec
cd ..

git clone https://github.com/kenhys/luaossl.git
cd luaossl
git checkout -b support-luajit210-with-rockspec origin/support-luajit210-with-rockspec
luarocks make luaossl-20161214-0.rockspec
cd ..

mkdir ./postgresql-client
cd postgresql-client
curl https://raw.githubusercontent.com/clear-code/lua-chrome-devtools-client/master/postgresql-client-0.1-1.rockspec > postgresql-client-0.1-1.rockspec 
curl https://raw.githubusercontent.com/clear-code/lua-chrome-devtools-client/master/postgresql-client.lua > postgresql-client.lua
luarocks make postgresql-client-0.1-1.rockspec
cd ..

luarocks install luasocket
luarocks install http
luarocks install basexx
luarocks install lrexlib-oniguruma
luarocks install chrome-devtools-client

rm -rf ./cqueues
rm -rf ./lua-cjson
rm -rf ./luaossl
rm -rf ./postgresql-client

curl https://raw.githubusercontent.com/clear-code/lua-chrome-devtools-client/master/convert-html-to-xml.lua > convert-html-to-xml.lua

useradd chromium-devtools
groupadd chromium-devtools
usermod -a -G chromium-devtools chromium-devtools

mv ./headless-chromium /etc/sysconfig/headless-chromium
mv ./headless-chromium.service /etc/systemd/system/headless-chromium.service

systemctl enable headless-chromium
systemctl daemon-reload
systemctl start headless-chromium
