#!/bin/bash

sudo apt update
sudo apt install mysql-client -y

echo '
use demo-db;
create table employee_info (id INT NOT NULL AUTO_INCREMENT, fname VARCHAR(40) NOT NULL, lname VARCHAR(40) NOT NULL, salary VARCHAR(12) NOT NULL, address VARCHAR(60) NOT NULL, ssn VARCHAR(11) NOT NULL, PRIMARY KEY (id));
INSERT INTO employee_info ( fname, lname, salary, address, ssn )
   VALUES
   ( "Homer", "Simpson", "$50,000USD", "742 Evergreen Terrace, Springfield", "123-45-6789" );
INSERT INTO employee_info ( fname, lname, salary, address, ssn )
   VALUES
   ( "Apu", "Nahasapeemapetilon", "$65,000USD", "1810 Ward Road, Springfield", "555-77-9999" );
INSERT INTO employee_info ( fname, lname, salary, address, ssn )
   VALUES
   ( "Barney", "Gumble", "$35,000USD", "409 Wines Lane, Springfield", "333-55-7777" );
INSERT INTO employee_info ( fname, lname, salary, address, ssn )
   VALUES
   ( "Moe", "Szyslak", "$40,000USD", "1201 Webster Street, Springfield", "555-77-9999" );
INSERT INTO employee_info ( fname, lname, salary, address, ssn )
   VALUES
   ( "Helen", "Lovejoy", "$85,000USD", "1231 Willow Greene Drive, Springfield", "999-44-1111" );
' > /tmp/dbdata.sql

sleep 30
mysql -h IPADDR -u student@DBSERVER -p'Security488!' < /tmp/dbdata.sql
