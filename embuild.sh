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
	make -j 16 em-$1
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

make -f makefile.em EM_TYPE=arcade gamelist-em > ./em-out/games.txt
