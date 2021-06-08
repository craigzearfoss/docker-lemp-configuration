#!/bin/bash

gitignore_file={{local_project_dir}}/.gitignore
printf "\nAdding dev-only files to .gitignore ..."

echo '' >> "$gitignore_file"
echo "# {{project_name}} dev-only files" >> "$gitignore_file"
echo 'public/phpinfo.php;' >> "$gitignore_file"
