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
    $n_pers = $_SESSION['pers_ricetta']["$ricetta"];
  }
?>
<html lang="en" class="no-js">
<head>
  <title>Preparazione ricetta</title>
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
      //TRUE sse in Dispensa sono presenti tutti i prodotti (e nelle quantità necessarie) per preparare $ricetta per $n_pers persone
      $res = mysql_query("SELECT is_recipe_available(\"$ricetta\",\"$n_pers\",\"$username\")") or die(mysql_error());

      while($row = mysql_fetch_row($res)){
        if(!$row[0]){//se non posso preparare $ricetta perchè mancano prodotti => lancio un avviso
          echo "<div class=\"component\">";
          echo "<p><strong>ATTENZIONE:</strong> Non puoi preparare questa ricetta perchè ti mancano degli ingredienti.<p>
                <p>Le cause di questo problema possono essere:
                <ul>
                  <li>Non hai scelto alcuna ricetta dalla sezione <strong>Ricette</strong> </li>
                  <li>Non hai indicato il numero di persone per le quali vuoi preparare la ricetta nella sezione <strong>Ricette</strong> </li>
                  <li>Non hai acquistato i prodotti consigliati nella sezione <strong>Lista della Spesa</strong></li>
                </ul>
                  Ti consigliamo di riprovare.</p>";
        }
        else{//altrimenti decremento le quantità degli ingredienti (usati per preparare $ricetta) in Dispensa

          //Seleziona, per ogni TipoProdotto di Ingrediente per $ricetta, il ProdottoInDispensa che scade prima, la sua QuantitaInDispensa,
          //la QuantitaNecessaria alla preparazione $ricetta, la differenza tra queste due quantita

          $query="  SELECT Barcode,Utente,DataScadenza,PD.TipoProdotto,Marca,Nome, PD.QuantitaV AS QuantitaDispensa,
                          (I.QuantitaV/4)*$n_pers AS QuantitaNecessaria, ROUND(PD.QuantitaV-(I.QuantitaV/4)*$n_pers) AS QuantitaRimasta
                    FROM ProdottoInDispensa PD JOIN Ingrediente I ON PD.TipoProdotto = I.TipoProdotto
                    WHERE PD.Utente = \"$username\" AND I.NomeRicetta = \"$ricetta\"
                          AND DataScadenza = ( SELECT MIN(DataScadenza)
                                               FROM ProdottoInDispensa P
                                               WHERE P.Utente = \"$username\" AND P.TipoProdotto = PD.TipoProdotto)
                    ORDER BY PD.TipoProdotto,DataScadenza";

          $res = mysql_query($query) or die("Query non valida: " . mysql_error());

          while($row = mysql_fetch_assoc($res)){

            $barcode = $row['Barcode'];
            $scadenza = $row['DataScadenza'];
            $q_rimasta = $row['QuantitaRimasta'];

            //Aggiorno tutte le QuantitaV degli ingredienti usati in Dispensa
            mysql_query("UPDATE ProdottoInDispensa
                            SET QuantitaV = \"$q_rimasta\"
                            WHERE Barcode =\"$barcode\" AND Utente =\"$username\" AND DataScadenza=\"$scadenza\" ") or die(mysql_error());
          }


          //Aggiusto le QuantitaV dei ProdottoInDispensa

          //Seleziono, tra i ProdottiInDispensa, quelli che (nella loro singolarità) non sono suffcienti alla preparazione della ricetta,
          // sapendo che (se sono arrivato a questo punto) lo sono sicuramente nella somma di tutti i prodotti con il medesimo TipoProdotto

          $res = mysql_query("SELECT * FROM ProdottoInDispensa WHERE Utente =\"$username\" AND QuantitaV < 0") or die(mysql_error());

          while($row = mysql_fetch_assoc($res)){
            $quantita = $row['QuantitaV'];
            $barcode = $row['Barcode'];
            $scadenza = $row['DataScadenza'];
            $tipo = $row['TipoProdotto'];

            //Seleziono ProdottiInDispensa con stesso TipoProdotto di quello che sto analizzando (tra quelli non sufficienti nella loro singolarità)
            //(ProdottiInDispensa sono già ordinati per DataScadenza CRESCENTE)
            $query = ("SELECT *
                       FROM ProdottoInDispensa
                       WHERE TipoProdotto = \"$tipo\" AND Utente =\"$username\"
                       ORDER BY DataScadenza");

            $res2 = mysql_query($query) or die(mysql_error());

            while($quantita < 0 && $row2 = mysql_fetch_assoc($res2)){
              $bar = $row2['Barcode'];
              $scad = $row2['DataScadenza'];
              $quant_disp = $row2['QuantitaV'];


              if($quant_disp != $quantita){
                $quant_disp += $quantita;

                mysql_query("UPDATE ProdottoInDispensa
                              SET QuantitaV = \"$quant_disp\"
                              WHERE Barcode =\"$bar\" AND Utente =\"$username\" AND DataScadenza=\"$scad\" ") or die(mysql_error());
                $quantita = $quant_disp;
              }
            }
          }
          echo "<p>Le quantità dei prodotti presenti nella tua Dispensa sono state aggiornate, tenendo conto degli
                     ingredienti utilizzati per preparare la ricetta \"$ricetta\". </p>";
          unset($_SESSION['pers_ricetta']["$ricetta"]);
        }
      }

    ?>
  </body>
</html>
