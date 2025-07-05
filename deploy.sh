#!/bin/bash

git submodule update --init --recursive

hugo --gc -b 'https://blog.deltabox.site/' --minify --themesDir themes
