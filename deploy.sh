#!/bin/bash

yarn --cwd themes/hugo-nuo run build

hugo --gc -b 'https://blog.deltabox.site/' --minify --themesDir themes
