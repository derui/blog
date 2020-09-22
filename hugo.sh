#!/bin/bash

if [[ ! -d ./bin ]]; then
    mkdir -p bin
fi

if [[ ! -f ./bin/hugo ]]; then
    curl -L -o bin/hugo.tar.gz https://github.com/gohugoio/hugo/releases/download/v0.75.1/hugo_0.75.1_Linux-64bit.tar.gz
    tar xf bin/hugo.tar.gz -C bin/
fi

./bin/hugo $@
