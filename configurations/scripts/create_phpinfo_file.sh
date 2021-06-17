#!/bin/bash

# Create php.info file
echo  "Creating phpinfo.php file ..."
if [ -d "{{local_web_root}}/phpinfo.php" ]; then
  echo "{{local_web_root}}/phpinfo.php already exists."
else

  phpinfo_file="{{local_web_root}}/phpinfo.php"

  export DIR=${phpinfo_file%/*}
  if [ ! -d "${DIR}" ] ; then
    mkdir -p "${DIR}"
  fi

  echo '<?php' >> "${phpinfo_file}"
  echo 'phpinfo();' >> "${phpinfo_file}"

fi