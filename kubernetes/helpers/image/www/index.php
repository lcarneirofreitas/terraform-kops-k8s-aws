<?php
echo "<H1>My container id: " . gethostname() ."</H1>";
echo "\n";
echo "My ipaddress: " . $_SERVER['SERVER_ADDR'];
echo "\n";

$servername = "mysql.collystore.local";
$username = "root";
$password = "lerolero";
$dbname = "teste123";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);
// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
} 

$sql = "SELECT id, firstname, lastname FROM MyGuests";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    // output data of each row
    while($row = $result->fetch_assoc()) {
        echo "id: " . $row["id"]. " - Name: " . $row["firstname"]. " " . $row["lastname"]. "<br>";
    }
} else {
    echo "0 results";
}
$conn->close();
?>

