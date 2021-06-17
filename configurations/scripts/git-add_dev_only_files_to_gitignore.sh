#!/bin/bash

# Add development-only files to .gitignore file
echo "\nAdding development-only files to .gitignore file ..."
gitignore_file=/var/www/site/.gitignore

if [ -d "${gitignore_file}" ]; then
  touch "${gitignore_file}"
fi

echo '' >> "${gitignore_file}"
echo "# {{project_name}} dev-only files" >> "${gitignore_file}"
echo 'public/phpinfo.php;' >> "${gitignore_file}"
