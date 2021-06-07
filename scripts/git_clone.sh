#!/bin/bash

printf "\nCloning $1 ..."

cd \var\www

echo "\n\tgit clone $1 $2\n"
git clone $1 $2
