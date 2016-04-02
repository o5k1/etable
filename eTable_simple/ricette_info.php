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
    $ricetta = $_GET['ricetta_nome'];
  }
?>
<html lang="en" class="no-js">
<head>
  <title><?php echo $ricetta; ?></title>
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
          <a class="current-demo" href="ricette.php" title="ricette">Ricette</a>
          <a href="lista_spesa.php?page=lista_spesa" title="lista_spesa">Lista della spesa</a>
        </nav>
end;
      ?>
    </header>
    <div class="component">
    <?php
      echo"<p><h1>$ricetta</em></h1></p>";
      #Ingredienti della ricetta scelta dall'utente
      $query = "SELECT TipoProdotto AS Ingredienti, CONCAT(QuantitaV,' ',QuantitaUM) AS QuantitàPer4
                FROM Ingrediente
                WHERE NomeRicetta = \"$ricetta\"";

      build_result_table($query);

      #Istruzioni della ricetta scelta
      $query = "SELECT Istruzioni FROM Ricetta WHERE Nome=\"$ricetta\"";

      build_result_table($query);

echo<<<end
      <p>Selezionando questa ricetta ed indicando il <strong>numero di persone</strong> per le quali la si vuole preparare, eventuali <strong>ingredienti
         non presenti nella tua Dispensa</strong> (o presenti in <strong>quantità non sufficiente</strong>) saranno aggiunti alla Lista della Spesa:</p>

      <link rel="stylesheet" href="css/normalize.css">
      <link rel='stylesheet prefetch' href='http://maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css'>
      <link rel="stylesheet" href="css/style.css">

      <ul class="logmod__tabs">
        <li data-tabtar="lgm-1"></li>
      </ul>

      <div class="logmod__heading">
        <span class="logmod__heading-subtitle"></span>
      </div>

      <form accept-charset="utf-8" action="lista_spesa.php?page=lista_spesa&ricetta_nome=$ricetta" class="simform" method="post" id="register_form">
          <div class="smin">
          <div class="input string optional">
            <label class="string optional">Persone *</label>
            <input class="string optional" type="number" min="1" placeholder="Numero di persone" name="persone" required/>
          </div>
        </div>
        <div class="simform__actions">
          <input class="submit" name="seleziona" type="submit" value="Seleziona" />
        </div>
      </form>
end;

    ?>
</body>
</html>