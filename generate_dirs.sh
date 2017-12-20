#!/bin/bash
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

