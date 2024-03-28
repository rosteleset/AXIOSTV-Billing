<?php
//Zomeminder Curl Proxy
//Updates possibly available at http://nw2.us/wordpress/embed-zoneminder-stream-on-website/

//Few changes by AnyKey
header('Pragma: no-cache');
header('Expires: Thu, 01 Dec 1994 16:00:00 GMT');
header('Connection: close');
header('Cache-Control: no-cache, must-revalidate');
header('Content-Type: multipart/x-mixed-replace; boundary=ZoneMinderFrame;');
 
//Change values below to match your server.
$host = "localhost"; //zoneminder server
$port = "80"; //zoneminder port, probably 80
$user = "guest"; //zoneminder username
$pass = "guest"; //zoneminder password

$monitor = filter_var($_GET['monitor'], FILTER_SANITIZE_NUMBER_INT); //zomeminder monitor ID for camera to stream

$maxfps = "5"; //max FPS for stream
$scale = "100"; //Scale (100 Default)
$buffer = "1000"; //Buffer (1000 Default)
 
while (@ob_end_clean()); 
$ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'http://'.$host.':'.$port.'/zm/cgi-bin/nph-zms?mode=jpeg&monitor='.$monitor.'&scale='.$scale.'&maxfps='.$maxfps.'&buffer='.$buffer.'&user='.$user.'&pass='.$pass); 
    curl_setopt($ch, CURLOPT_HEADER, 0);

    // Output
    echo curl_exec($ch);

curl_close($ch);
?>
