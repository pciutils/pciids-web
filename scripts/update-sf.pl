#!/bin/bash
set -e
cd ~/sf.net
rm -rf htdocs
mkdir htdocs
cd htdocs

O=~/ids/docs
cp -aL $O/static .
cp -aL $O/{v2.2,pci.ids*} .
cp ../index.html .

rsync -az --delete ~/sf.net/htdocs mares,pciids@web.sourceforge.net:
