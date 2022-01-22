#!/bin/bash

yarn run build --cwd themes/hugo-nuo

hugo --gc -b 'https://blog.deltabox.site/' --minify --themesDir themes
