#!/bin/bash

# script to put each file in a directory into its own directory, 
# numbered sequentially.  Useful to create folder structure expected
# by the Islandora book_batch module.  NOTE: This script does not
# do the full batch structure preparation.  See bookbatch.sh for that.

# Operates on the current directory.
 
FILES=./*
declare -i COUNTER
COUNTER=0
for f in $FILES
do
  COUNTER=COUNTER+1
  echo "Processing file $f..."
  mkdir $COUNTER
  echo "Adding directory $COUNTER..."
  mv $f $COUNTER
  echo "Moved file $f to $COUNTER..."
done

