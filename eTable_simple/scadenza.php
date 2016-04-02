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
  }
?>
<html lang="en" class="no-js">
<head>
  <title>In scadenza</title>
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
          <a class="current-demo" href="$phpself" title="scadenza">In Scadenza</a>
          <a href="ricette.php" title="ricette">Ricette</a>
          <a href="lista_spesa.php?page=lista_spesa" title="lista_spesa">Lista della spesa</a>
        </nav>
end;
      ?>
    </header>
    <div class="component">
     <!--Tabella risultati query-->
      <?php
        echo "<p>Qui puoi vedere quali tra i tuoi prodotti stanno scadendo.</p>";
        $query = "SELECT Marca,Nome,TipoProdotto AS Tipo,CONCAT(QuantitaV,' ',QuantitaUM) AS Quantità,
                         DATE_FORMAT(DataScadenza,'%e-%c-%Y') AS Scadenza
                  FROM ProdottoInDispensa
                  WHERE Utente=\"$username\" AND DataScadenza < DATE_ADD(CURDATE(),INTERVAL 2 WEEK)
                  ORDER BY DataScadenza,QuantitaV DESC";

        build_result_table($query);
      ?>

</body>
</html>