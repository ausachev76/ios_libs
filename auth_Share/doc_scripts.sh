#!/bin/bash
for i in $( find . -name '*.h' -type f ); do
headerdoc2html -j -o ./Documentation $i
done

gatherheaderdoc ./Documentation


sed -i.bak 's/<html><body>//g' ./Documentation/masterTOC.html
sed -i.bak 's|<\/body><\/html>||g' ./Documentation/masterTOC.html
sed -i.bak 's|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN" "http://www.w3.org/TR/REC-html40/loose.dtd">||g' ./Documentation/masterTOC.html