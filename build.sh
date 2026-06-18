#!/bin/bash

if type "clang" > /dev/null 2>&1; then
  clang *.c -Werror -O0 -g -o small-osc
else
  gcc *.c -Werror -std=c99 -O0 -g -o small-osc
fi
