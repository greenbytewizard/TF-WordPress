UPDATE mysql.user SET Password = PASSWORD('${mysql_root_pwd}') WHERE USER = 'root';
DROP USER ''@'localhost';
UPDATE mysql.user SET Host = 'localhost' WHERE User = 'root' AND Host = '%';
DROP DATABASE IF EXISTS test;
CREATE USER 'bob.saget'@'localhost' IDENTIFIED BY '${wordpress_user_pwd}';
GRANT ALL PRIVILEGES ON *.* TO 'bob.saget'@'localhost';
CREATE DATABASE fullhousedb;
GRANT ALL PRIVILEGES ON fullhousedb.* TO 'bob.saget'@'localhost';
FLUSH PRIVILEGES;
exit