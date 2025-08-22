#!/bin/sh
sed -i \
         -e 's/#0d0d0f/rgb(0%,0%,0%)/g' \
         -e 's/#8e9aba/rgb(100%,100%,100%)/g' \
    -e 's/#0d0d0f/rgb(50%,0%,0%)/g' \
     -e 's/#1D2E67/rgb(0%,50%,0%)/g' \
     -e 's/#0d0d0f/rgb(50%,0%,50%)/g' \
     -e 's/#8e9aba/rgb(0%,0%,50%)/g' \
	"$@"
