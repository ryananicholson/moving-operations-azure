#!/bin/bash

sudo apt update
sudo apt install -y apache2
sudo apt install -y php
sudo apt install -y php-mysql
echo "
<!DOCTYPE html>
<html>
<head>
<style>
redcolor {
  color: red;
}
</style>
</head>
<body>
<h1>Welcome to the Demo!</h1>
<h3>You are talking to the server at: <redcolor>
<?php
exec(\"ip -4 addr show dev eth0 | grep inet | awk '{print \$2}' | cut -d / -f1\", \$output);echo \$output[0];
?>
</redcolor>
<br/>
Database Status: <redcolor>
<?php

\$con=mysqli_init();
mysqli_ssl_set(\$con, NULL, NULL, \"/etc/ssl/certs/ca-certificates.crt\", NULL, NULL);
mysqli_real_connect(\$con, \"IPADDR\", \"student@DBSERVER\", \"Security488!\", \"demo-db\", 3306);

if (\$con->connect_error) {
          die(\"Connection failed: \" . \$con->connect_error);
}
echo \"Database online\";
?>
</redcolor>
<br/>
<br/>
Enter employee first and last name to retrieve employee ID:</h3>
<br/>
<form action=\"/lookup.php\" method=\"post\">
  <label for=\"fname\">First name:</label>
  <input type=\"text\" id=\"fname\" name=\"fname\"><br><br>
  <label for=\"lname\">Last name:</label>
  <input type=\"text\" id=\"lname\" name=\"lname\"><br><br>
  <input type=\"submit\" value=\"Submit\">
</form>
</body>
</html>" | sudo tee /var/www/html/index.php
echo "
<?php

\$con = mysqli_connect(\"IPADDR\", \"student@DBSERVER\", \"Security488!\", \"demo-db\");

if (\$con->connect_error) {
  die(\"Connection failed: \" . \$con->connect_error);
} else {
  \$fname = \$_POST[\"fname\"];
  \$lname = \$_POST[\"lname\"];
  \$sql = \"SELECT id FROM employee_info WHERE fname='\" . \$fname. \"' AND lname='\" . \$lname . \"'\";
  if (\$result = \$con->query(\$sql)) {
    while(\$row = \$result->fetch_assoc()) {
      echo \"Employee id: \" . \$row['id'] . \"<br/>\";
    }
  } else {
    echo \"0 results<br/>\";
  }
  \$con->close();
}
?>
" | sudo tee /var/www/html/lookup.php
sudo rm /var/www/html/index.html
sudo systemctl restart apache2
