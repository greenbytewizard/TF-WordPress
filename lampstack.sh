#!/bin/bash

    export PASSWORD_1="random_password.salt_passwords[0].result" 
    export PASSWORD_2="random_password.salt_passwords[1].result" 
    export PASSWORD_3="random_password.salt_passwords[2].result"
    export PASSWORD_4="random_password.salt_passwords[3].result" 
    export PASSWORD_5="random_password.salt_passwords[4].result"
    export PASSWORD_6="random_password.salt_passwords[5].result"
    export PASSWORD_7="random_password.salt_passwords[6].result" 
    export PASSWORD_8="random_password.salt_passwords[7].result"
    export mysql_root_pwd="random_password.mysql_root_pwd.result"
    export wordpress_user_pwd="random_password.wordpress_user_pwd.result"

# Run as root and remember to keep it simple
# Prepare LAMP Server for Amazon Linux 2
# Define the number of attempts
max_attempts=5
for ((current_attempt=1; current_attempt <= max_attempts; current_attempt++));
    do
    echo "Attempt $current_attempt:"
    # Run the commands
    dnf upgrade -y
    dnf install -y wget httpd php-fpm php-mysqli php-mysqlnd php-json php php-devel
    # Check if the commands were successful
    if [ $? -eq 0 ];
        then
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
desired_app=('mariadb105-server' 'mariadb-server')

for i in "${desired_app[@]}"; 
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
# func_name () {install -name} Use functions to make code DRY
EC2_GROUPS= groups ec2-user
CheckUserGroups () {
if [[ $EC2_GROUPS =~ 'apache' ]];
then
    echo "Groups set properly"
else 
    echo "Groups not set properly, attempting to fix"
    usermod -a -G apache ec2-user
fi
}

CheckUserGroups
# ls -lah /var/www
# Change group ownership, write permissions for directory/file
# stat -c(use the specified FORMAT instead of the default); %a(access rights in octal) %A(acess rights in human readable form) --help
if [ "$(stat -c '%a' /var/www)" == "2775" ]
then
    echo "Permissions set properly"
else
    echo "Permissions not set properly, attempting to fix"
    chown -R ec2-user:apache /var/www
    chgrp -R apache /var/www
    chmod 2775 /var/www
    find /var/www -type d -exec chmod 2775 {} \;
    find /var/www -type f -exec chmod 0664 {} \;
fi

systemctl restart httpd
sleep 30

apps_status=('httpd' 'mariadb')
for i in "${apps_status[@]}"; 
    do
    status=$(systemctl is-enabled "$i")
    
    systemctl start "$i"
    systemctl enable "$i"
    
    if [[ "$status" = "enabled" ]]; 
    then
        echo "Installed Properly"
    fi
done
# Step by step instructions: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-lamp-amazon-linux-2.html

# Host a WordPress Blog
# tar -xzf (extract, gzip filter, creates file)
while [ ! -f latest.tar.gz ]; do
    wget https://wordpress.org/latest.tar.gz
    sleep 5
done

echo "Extracting Tarball"
tar -xzf latest.tar.gz

mysql <<EOF
    UPDATE mysql.user SET Password = PASSWORD('${mysql_root_pwd}') WHERE USER = 'root';
    DROP USER ''@'localhost' exit;
    UPDATE mysql.user SET Host = 'localhost' mysql WHERE User = 'root' AND Host = '%';
    DROP DATABASE IF EXISTS test;
    CREATE USER 'bob.saget'@'localhost' IDENTIFIED BY '${wordpress_user_pwd}';
    GRANT ALL PRIVILEGES ON *.* TO 'bob.saget'@'localhost';
    CREATE DATABASE fullhousedb;
    GRANT ALL PRIVILEGES ON fullhousedb.* TO 'bob.saget'@'localhost';
    FLUSH PRIVILEGES;
    exit
EOF
# the source command (also known as the `.` command) is used to execute another script within the current script.
# Create and edit wp-config.php file
#sed examples (single dash command) -nei same as -n -e -i (interrupt that and split each character)
# nano wordpress/wp-config.php

cp wordpress/wp-config-sample.php wordpress/wp-config.php
sed -i "s/'database_name_here'/'fullhousedb'/g" wordpress/wp-config.php
sed -i "s/'username_here'/'bob.saget'/g" wordpress/wp-config.php
sed -i "s/'password_here'/'${wordpress_user_pwd}'/g" wordpress/wp-config.php

# Authentication Keys for each loop $${PASSWORD_1}for random passwords 
lineNo=51
var="define( 'AUTH_KEY', '${PASSWORD_1}' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=52
var="define( 'SECURE_AUTH_KEY', '${PASSWORD_2}' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=53
var="define( 'LOGGED_IN_KEY', '${PASSWORD_3}' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=54
var="define( 'NONCE_KEY', '${PASSWORD_4}' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=55
var="define( 'AUTH_SALT', '${PASSWORD_5}' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=56
var="define( 'SECURE_AUTH_SALT', '${PASSWORD_6}' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=57
var="define( 'LOGGED_IN_SALT', '${PASSWORD_7}' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

lineNo=58
var="define( 'NONCE_SALT', '${PASSWORD_8}' );"
sed -i "${lineNo}s/.*/$var/" wordpress/wp-config.php

mkdir /var/www/html/blog
cp -r wordpress/* /var/www/html/

lineNo=151
var="AllowOverride All"
sed -i "${lineNo}s/.*/$var/" /etc/httpd/conf/httpd.conf

# In Bash, when you want to access all elements of an array, you use the array[@] syntax. The [@] is used to treat each element of the array as a separate entity. This is important because if you omit the [@], the entire array would be treated as a single element.
# i (iterator) 
for i in "httpd"; 
    do 
        STATUS=$(systemctl is-enabled "$i")
    if [ "$STATUS" = "enabled" ]; then 
        echo "$i is ENABLED"
    else 
        systemctl enable "$i"
        systemctl start "$i"
    fi
done