#!/bin/bash

# Create <webroot>index.php file
echo  "Creating {{local_web_root}}/index.php ..."
if [ -d "{{local_web_root}}/index.php" ]; then
  echo "{{local_web_root}}/index.php already exists."
else

  root_index_file="{{local_web_root}}/index.php"

  export DIR=${root_index_file%/*}
  if [ ! -d "${DIR}" ] ; then
    mkdir -p "${DIR}"
  fi

  echo '<?php' > "${root_index_file}"
  echo 'echo <<<EOD' >> "${root_index_file}"
  echo '<!DOCTYPE html>' >> "${root_index_file}"
  echo '<html>' >> "${root_index_file}"
  echo '  <head>' >> "${root_index_file}"
  echo '    <meta charset="UTF-8">' >> "${root_index_file}"
  echo '    <title>{{project_name}}</title>' >> "${root_index_file}"
  echo '  </head>' >> "${root_index_file}"
  echo '  <body>' >> "${root_index_file}"
  echo '    <h2>{{project_name}}</h2>' >> "${root_index_file}"
  echo '    <hr/>' >> "${root_index_file}"
  echo '    <p>Create your project in the <b>{{project_name}}-app</b> container in the directory <b style="font-family:Courier New;">/www/var/{{project_name}}</b>.</p>' >> "${root_index_file}"
  echo '    <ul>' >> "${root_index_file}"
  echo '      <dl><dt>To access the server docker container:</dt><dd><b style="font-family:Courier New;">docker -ti exec {{project_name}}-app bash</b></dd></dl>' >> "${root_index_file}"
  echo '    </ul>' >> "${root_index_file}"
  echo '  </tbody>' >> "${root_index_file}"
  echo '</html>' >> "${root_index_file}"
  echo 'EOD;' >> "${root_index_file}"

fi
