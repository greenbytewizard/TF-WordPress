--MYSQL_PW=("4llh41lth3L1z4rdbr41n")
--SCND_SCRT=("Shn4zzb3rr13s")
UPDATE mysql.user SET Password = PASSWORD('4llh41lth3L1z4rdbr41n') WHERE USER = 'root';
DROP USER ''@'localhost';
UPDATE mysql.user SET Host = 'localhost' WHERE User = 'root' AND Host = '%';
DROP DATABASE IF EXISTS test;
CREATE USER 'bob.saget'@'localhost' IDENTIFIED BY 'Shn4zzb3rr13s';
GRANT ALL PRIVILEGES ON *.* TO 'bob.saget'@'localhost';
CREATE DATABASE fullhousedb;
GRANT ALL PRIVILEGES ON fullhousedb.* TO 'bob.saget'@'localhost';
FLUSH PRIVILEGES;
exit