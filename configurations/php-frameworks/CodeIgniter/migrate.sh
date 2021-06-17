#!/bin/bash

# Run CodeIgniter database migrations
echo  "Running CodeIgniter database migrations ..."
cd /var/www/site
DB_HOST=127.0.0.1 php spark migrate
