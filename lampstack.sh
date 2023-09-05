#!/bin/bash
# Run as root and remember to keep it simple
# Prepare LAMP Server for Amazon Linux 2
# Define the number of attempts
max_attempts=3
# Start the for loop
for ((current_attempt=1; current_attempt <= max_attempts; current_attempt++)); 
    do
    echo "Attempt $current_attempt:"
    # Run the commands
    dnf upgrade -y
    dnf install -y httpd wget php-fpm php-mysqli php-json php php-devel
    # Check if the commands were successful
    if [ $? -eq 0 ]; then
        echo "Commands executed successfully."
        break  # Exit the loop
    else
        echo "Attempt $current_attempt failed."
        if [ $current_attempt -lt $max_attempts ]; 
        then
            echo "Retrying in 5 seconds..."
            sleep 5
        else
            echo "Max attempts reached. Exiting."
        fi
    fi
done

# script level variables something=name
## Do a dnf list on the versions to check if they are installed 
desired_app=('mariadb105-server')

for i in "${desired_app}"; 
    do
    installed=$(dnf list installed "$i" 2>/dev/null)  # Redirect stderr to /dev/null
    if [[ ! $installed =~ "installed" ]];  
    then
        dnf install -y "$i"
    fi
done
#  The =~ operator is used for regular expression matching. The ! in front of the condition negates the match, meaning it checks if "installed" is not found in the output.
# [[ ... ]]: This is the syntax for starting a conditional expression in Bash. 
# provide extended functionality for conditions, such as string comparison, pattern matching, and more. The double brackets are used to make complex conditions more readable and flexible compared to single brackets
apps_status=("httpd" "mysqld")

for i in "${apps_status[@]}"; 
    do
    status=$(chkconfig is-enabled "$i")
    
    chkconfig on "$i"
    chkconfig enable "$i"
    
    if [[ "$status" = "enabled" ]]; 
    then
        echo "Installed Properly"
    fi
done

# func_name () {install -name} Use functions to make code DRY
EC2_GROUPS= groups ec2-user
CheckUserGroups () {
if [[ $EC2_GROUPS =~ 'apache' ]];
then
    echo "Installed Properly"
else 
    usermod -a -G apache ec2-user
fi
}

CheckUserGroups

# ls -lah /var/www
# Change group ownership, write permissions for directory/file
# stat -c(use the specified FORMAT instead of the default); %a(access rights in octal) %A(acess rights in human readable form) --help
if [ "$(stat -c '%a' /var/www)" == "2775" ]
then
    echo "It's me a Mario"
else
    chown -R ec2-user:apache /var/www
    chgrp -R apache /var/www
    chmod 2775 /var/www && find /var/www -type d -exec chmod 2775 {} \;
    find /var/www -type f -exec chmod 0664 {} \;
fi

service_config=('httpd' 'mysqld')

for i in "${service_config[@]}"; 
    do
    status=$(service "$i" status)
    if [[ ! $status =~ "running" ]];  
    then
       service "$i" start
    fi
done
# Step by step instructions: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-lamp-amazon-linux-2.html

# Host a WordPress Blog
# tar -xzf (extract, gzip filter, creates file)

while [ ! -f latest.tar.gz ]; do
    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz
    ##quick exit
    [ -f latest.tar.gz ]; break
    sleep 5
done

systemctl start mariadb

# the source command (also known as the `.` command) is used to execute another script within the current script.
# source "C:\GitHub\terraform.tfvars"
# Use the MYSQL_PW variable in your script
MYSQL_PW="4llh41lth3L1z4rdbr41n"
# SCND_SCRT= "Shn4zzb3rr13s"
mysql -u root >>EOF
UPDATE mysql.user SET Password = PASSWORD('4llh41lth3L1z4rdbr41n') WHERE USER = 'root';
DROP USER ''@'localhost';
UPDATE mysql.user SET Host = 'localhost' WHERE User = 'root' AND Host = '%';
DROP DATABASE IF EXISTS test;
CREATE USER 'bob.saget'@'localhost' IDENTIFIED BY 'Shn4zzb3rr13s';
GRANT ALL PRIVILEGES ON *.* TO 'bob.saget'@'localhost';
CREATE DATABASE fullhousedb;
GRANT ALL PRIVILEGES ON fullhousedb.* TO 'bob.saget'@'localhost';
FLUSH PRIVILEGES;
exit EOF
# Create and edit wp-config.php file
#sed examples (single dash command) -nei same as -n -e -i (interrupt that and split each character)
# nano wordpress/wp-config.php

cp wordpress/wp-config-sample.php wordpress/wp-config.php
sed -i "s/'database_name_here'/'fullhousedb'/g" wordpress/wp-config.php
sed -i "s/'username_here'/'bob.saget'/g" wordpress/wp-config.php
sed -i "s/'password_here'/'$MYSQL_PW'/g" wordpress/wp-config.php

# Authentication Keys 
lineNo=51
var="define( 'AUTH_KEY', '5x8XbnhEH0SfVzjd' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=52
var="define( 'SECURE_AUTH_KEY', 'FzU77YvagmZDij5M' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=53
var="define( 'LOGGED_IN_KEY', 'tP98EIGs6yWzSLAa' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=54
var="define( 'NONCE_KEY', '13im39oQAdR36zbN' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=55
var="define( 'AUTH_SALT', 'Wy3iDnYdyRaNNli9' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=56
var="define( 'SECURE_AUTH_SALT', 'SIx6v5JXqLtI9tl0' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=57
var="define( 'LOGGED_IN_SALT', 'QQQIzbbkqcOls3Ad' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=58
var="define( 'NONCE_SALT', 'D8azHEsYfdmM9du8' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

mkdir /var/www/html/blog
cp -r wordpress/* /var/www/html/

lineNo=151
var="AllowOverride All"
sed -i "${lineNo}s/.*/$var/" /etc/httpd/conf/httpd.conf

# In Bash, when you want to access all elements of an array, you use the ${array[@]} syntax. The [@] is used to treat each element of the array as a separate entity. This is important because if you omit the [@], the entire array would be treated as a single element.
# i (iterator) 
for i in "httpd" "mariadb"; 
    do 
        STATUS=$(systemctl is-enabled "$i")
    if [ "$STATUS" = "enabled" ]; then 
        echo "$i is ENABLED"
    else 
        systemctl enable "$i"
        systemctl start "$i"
    fi
done