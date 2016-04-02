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
    $barcode = $_GET['to_add_barcode'];
  }
?>
<html lang="en" class="no-js">
<head>
  <title>Prodotto Acquistato</title>
  <link rel="stylesheet" type="text/css" href="css/normalize.css" />
  <link rel="stylesheet" type="text/css" href="css/demo.css" />
  <link rel="stylesheet" type="text/css" href="css/component.css" />
</head>
<body>
  <div class="container">
      <!-- Top Navigation -->
      <div class="codrops-top clearfix">
        <span class="right"><a  href="logout.php"><span>Logout</span></a></span>
    </div>
    <!--Intestazione-->
    <header>
      <?php

echo<<<end
        <h1>Benvenuto <em>$nome $cognome</em></h1>

        <nav class="codrops-demos">
          <a href="dispensa.php" title="dispensa">In Dispensa</a>
          <a href="scadenza.php" title="scadenza">In Scadenza</a>
          <a href="ricette.php" title="ricette">Ricette</a>
          <a class="current-demo" href="lista_spesa.php?page=lista_spesa" title="lista_spesa?page=lista_spesa">Lista della spesa</a>
        </nav>
end;
      ?>
    </header>
    <div class="component">
      <?php
echo<<<end
          <p>Inserisci la data di scadenza del prodotto acquistato così da poterlo aggiungere alla tua dispensa.</p>

          <link rel="stylesheet" href="css/normalize.css">
          <link rel='stylesheet prefetch' href='http://maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css'>
          <link rel="stylesheet" href="css/style.css">

          <ul class="logmod__tabs">
            <li data-tabtar="lgm-1"></li>
          </ul>

          <div class="logmod__heading">
            <span class="logmod__heading-subtitle"></span>
          </div>

          <form accept-charset="utf-8" action="dispensa.php?to_add_barcode=$barcode" class="simform" method="post" id="register_form">
            <div class="smin">
              <div class="input string optional">
                <label class="string optional">Data Scadenza *</label>
                <input class="string optional" placeholder="Data scadenza" type="date" name="scadenza" required/>
              </div>
            </div>

            <div class="simform__actions">
              <input class="submit" name="aggiungi" type="submit" value="Aggiungi" />
            </div>
          </form>
end;
      ?>

</body>
</html>