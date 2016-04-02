<?php
  session_start();
  include_once 'config.php';
  include_once 'library.php';

  if(!isset($_SESSION['username'])){
    header("Location: index.php");
  }
  else{
    $username = $_SESSION['username'];
    $nome = $_SESSION['nome'];
    $cognome = $_SESSION['cognome'];
    $phpself = $_SERVER['PHP_SELF'];
    $barcode = $_GET['to_del_barcode'];
  }

  $query = "DELETE FROM ProdottoInDispensa
            WHERE Utente = \"$username\" AND Barcode = \"$barcode\"";
  mysql_query($query) or die(mysql_error());

  header("Location: dispensa.php?action=dispensa_rimuovi");
?>