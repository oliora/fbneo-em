#!/bin/bash

clean () {
	echo "Cleaning..."
	rm -rf ./obj
	rm fbneo.*
	rm gamelist.txt
}

build() {
	clean
	rm ./fbneo-$1.*
	rm ./gamelist-em.txt
	make em-$1
	mv ./gamelist-em.txt ./em-out/gamelist-$1.txt
	mv ./fbneo-$1.js ./em-out
	mv ./fbneo-$1.wasm ./em-out
}

rm -rf em-out
mkdir em-out

build arcade
build neogeo
build capcom
build konami