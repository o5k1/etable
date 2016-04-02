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

    /*PROCEDURE che cancella eventuali ProdottiInDispensa con QuantitaV <= 0*/
    mysql_query("CALL elimina_prodotto_finito(\"$username\")") or die (mysql_error());

    if(isset($_POST['aggiungi']) && isset($_GET['to_add_barcode'])){//se sono arrivato a questa pagina da lista_spesa_acquistato
      $barcode = $_GET['to_add_barcode'];
      $scadenza = $_POST['scadenza'];

      /*
      PROCEDURE che cancella il prodotto acquistato da ListaSpesa e lo inserisce in ProdottoInDispensa, con QuantitaV = CapacitaV*N_confezioni
      chiama a sua volta la PROCEDURE aggiusta_dispensa che, se prodotto comprato (con stessa DataScadenza) esiste già in Dispensa => ne aumenta
      solo QuantitaV, altrimenti aggiunge una nuova riga in ProdottoInDispensa.
      */
      mysql_query("CALL acquista_prodotto(\"$username\",\"$barcode\",\"$scadenza\")") or die(mysql_error());
    }
  }
?>
<html lang="en" class="no-js">
<head>
  <title>Dispensa</title>
    <link rel="stylesheet" type="text/css" href="css/normalize.css" />
    <link rel="stylesheet" type="text/css" href="css/demo.css" />
    <link rel="stylesheet" type="text/css" href="css/component.css" />
</head>
<body>
  <div class="container">
      <!-- Top Navigation -->
      <div class="codrops-top clearfix">
        <span class="right"><a  href="logout.php"><span>Logout</span></a></span>
        <?php
echo<<<end
          <span class="left"><a  href="dispensa_inserisci.php"><span>Inserisci</span></a></span>
          <span class="left"><a  href="$phpself?action=dispensa_rimuovi"><span>Rimuovi</span></a></span>
end;
        ?>
      </div>
    <!--Intestazione-->
    <header>
      <?php

echo<<<end
        <h1>Benvenuto <em>$nome $cognome</em></h1>

        <nav class="codrops-demos">
          <a class="current-demo" href="$phpself" title="dispensa">In Dispensa</a>
          <a href="scadenza.php" title="scadenza">In Scadenza</a>
          <a href="ricette.php" title="ricette">Ricette</a>
          <a href="lista_spesa.php?page=lista_spesa" title="lista_spesa">Lista della spesa</a>
        </nav>
end;
      ?>
    </header>
    <div class="component">
    <!--Tabella risultati query-->
      <?php
        if(isset($_GET['action']) && $_GET['action'] == "dispensa_rimuovi")//se è stato cliccato il link "Rimuovi"
          echo "<p>Per rimuovere un prodotto dalla tua dispensa utilizza la <strong>&#10007</strong> corrispondente alla riga interessata.</p>";
        else
          echo "<p>Qui puoi vedere i prodotti che hai attualmente in dispensa.</p>";
        $query = "SELECT Barcode,Marca,Nome,TipoProdotto AS Tipo,CONCAT(QuantitaV,' ',QuantitaUM) AS Quantità,
                         DATE_FORMAT(DataScadenza,'%e-%c-%Y') AS Scadenza
                  FROM ProdottoInDispensa
                  WHERE Utente=\"$username\"
                  ORDER BY DataScadenza ASC";

        build_result_table($query);
      ?>
</body>
</html>