#!/bin/bash

# Checkout a git repository branch
echo  "Checking out git branch {{git_branch}} ..."
if [ ! -d "/var/www/site" ]; then
  echo "Directory /var/www/site does not exist."
fi

# Checkout repository branch
cd /var/www/site
git checkout {{git_branch}}
