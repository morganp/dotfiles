#!/bin/sh

find . -name "simv" -type f -exec rm -rf {} \;
find . -name "simv.*" -type d -exec rm -rf {} \;
find . -name "*csrc" -type d -exec rm -rf {} \;
find . -name "vcs.key" -type f -exec rm -rf {} \;
find . -name ".job" -type f -exec rm -rf {} \;

