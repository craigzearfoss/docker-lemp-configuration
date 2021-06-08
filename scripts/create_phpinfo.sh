#!/bin/bash

phpinfo_file={{local_project_dir}}/public/phpinfo.php
printf "\nCreating ${phpinfo_file} file ..."

echo '<?php' > "$phpinfo_file"
echo 'phpinfo();' >> "$phpinfo_file"
