#!/bin/bash

echo  "Clearing CodeIgniter cache ..."

cd /var/www/site

php spark cache:clear
