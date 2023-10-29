#!/bin/bash
set -e
cd ~/github
ORIG=~/ids/docs/v2.2/pci.ids
if ! cmp -s $ORIG pci.ids ; then
	cp $ORIG pci.ids
	git commit -a -m 'New snapshot generated'
	git push
fi
