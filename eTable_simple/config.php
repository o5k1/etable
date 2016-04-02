<?php
	$user = 'root';
	$password = '';
	$db = 'eTable';
	$host = 'localhost';

	$link = mysql_connect($host,$user,$password) or die("Impossibile Connettersi al Server");

	$db_selected = mysql_select_db($db,$link) or die("Impossibile Connettersi al Database");
?>