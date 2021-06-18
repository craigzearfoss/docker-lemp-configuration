#!/bin/bash

# Run CodeIgniter database migrations
echo  "Running CodeIgniter database migrations ..."
cd /var/www/site
DB_HOST=db-mysql php spark migrate
