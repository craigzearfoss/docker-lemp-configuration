# Project Setup Notes
---

### Step 1 - Create the Laravel project
- Replace {{project_name}} with the name of your project everywhere that it appears below.
```
curl -s https://laravel.build/{{project_name}} | bash
```

### Step 2 - Copy Docker configuration files
- Copy everything from the **base** directory into your project directory.
- Replace {{project_name}} with the name of your project everywhere that it appears below.
```
$ cd {{project_name}}
$ cp -r {{this_directory}}/docker-compose/ docker-compose/
$ cp {{this_directory}}/docker-compose.yml docker-compose.yml
$ cp {{this_directory}}/Dockerfile Dockerfile
```

### Step 3 - Set up the application .env file
- This file contains sensitive information so never share it.
- Set up your DB_HOST, DB_DATABASE, DB_USERNAME and DB_PASSWORD.
```
$ nano .env
```
```
...
DB_CONNECTION=mysql
DB_HOST=mysql
DB_PORT=3306
DB_DATABASE=example_app
DB_USERNAME=sail
DB_PASSWORD=password
...
```

### Step 4 - Nginx configuration
- Rename the file docker-compose/nginx/{{project_name}}.conf to your project name.

### Step 5 - MySQL initialization file
- Add your initialization SQL commands in the file docker-compose/mysql/init_db.sql.

### Step 6 - docker-compose.yml
- In the file docker-compose.yml change all occurrences of {{project_name}} to your project name.

### Step 7 - Run the application with Docker compose
- Build the app image with the following command.
```
$ docker-compose build 
```
- When the build is finished, you can run the environment in background mode.
```
$ docker-compose up -d
```
- To show information about the state of your active services.
```
$ docker-compose ps
```

### Step 8 - Run composer to make sure all dependencies are installed
```
$ docker-compose exec app composer install
```
- If you get errors when running install then try running update instead.
```
$ docker-compose exec app composer update
```

### Step 9 - Generate unique application key
- This should have been generated when you create the Laravel application, but it doesn't hurt to run it again.
```
$ docker-compose exec app php artisan key:generate
```

### Step 10 - Check the site in your browser
- On your local machine use
```
http://localhost:8000
```
- Otherwise use
```
http://server_domain_or_IP:8000
```
