#!/bin/sh

options="-not -name *'.svn'*"

find . $options -name "*_synth.tcl" -type f -exec rm -rf {} \;
find . $options -name "*_map.txt" -type f -exec rm -rf {} \;
find . $options -name "run.log" -type f -exec rm -rf {} \;

find . $options -name "tmp" -type f -exec rm -rf {} \;
find . $options -name "Backup" -type d -exec rm -rf {} \;

