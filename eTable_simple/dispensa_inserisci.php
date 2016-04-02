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
  <title>Inserisci prodotto</title>
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
          <a class="current-demo" href="dispensa.php" title="dispensa">In Dispensa</a>
          <a href="scadenza.php" title="scadenza">In Scadenza</a>
          <a href="ricette.php" title="ricette">Ricette</a>
          <a href="lista_spesa.php?page=lista_spesa" title="lista_spesa?page=lista_spesa">Lista della spesa</a>
        </nav>
end;
      ?>
    </header>
    <div class="component">
    <!--Tabella risultati query-->

    <?php
      if(isset($_POST['aggiungi_full'])){//non esiste $barcode in ProdottoInVendita (ovvero il prodotto che voglio inserire non è conosciuto dal DB)
        $barcode = $_SESSION['barcode'];
        $scadenza = $_SESSION['scadenza'];
        $tipo = $_POST['tipo_prod'];
        $marca = $_POST['marca_prod'];
        $nome = $_POST['nome_prod'];
        $v = $_POST['v_prod'];
        $um = $_POST['um_prod'];

        $res = mysql_query("SELECT presente_in_dispensa(\"$barcode\",\"$username\",\"$scadenza\")") or die(mysql_error());

        while($row = mysql_fetch_row($res)){
          if($row[0]){//se $barcode esiste già in ProdottoInDispensa => aumento di $v la quantità in dispensa
            mysql_query("UPDATE ProdottoInDispensa
              SET QuantitaV = QuantitaV + \"$v\"
              WHERE Utente = \"$username\" AND Barcode = \"$barcode\" AND DataScadenza = \"$scadenza\"") or die(mysql_error());
          }
          else{//altrimenti inserisco la nuova riga in ProdottoInDispensa

            $query="INSERT INTO ProdottoInDispensa(Barcode,Utente,DataScadenza,TipoProdotto,Marca,Nome,QuantitaV,QuantitaUM)
                            VALUES(\"$barcode\",\"$username\",\"$scadenza\",\"$tipo\",\"$marca\",\"$nome\",\"$v\",\"$um\")";

            mysql_query($query) or die("Query non valida: " . mysql_error());
          }
        }


        header("Location: dispensa.php");
      }
      else
        if(isset($_POST['aggiungi'])){//prova a completare il prodotto inserito attingendo da info di prodotti conosciuti (=ProdottiInVendita)
          $barcode = $_POST['barcode'];
          $scadenza = $_POST['scadenza'];

          //cerca il nuovo prodotto nei prodotti conosciuti e lo inserisce in dispensa(al solito, decide se fare UPDATE o INSERT)
          $func = "SELECT autocomplete_prod_info(\"$barcode\",\"$username\",\"$scadenza\")";

          $res = mysql_query($func) or die(mysql_error());

          while($row = mysql_fetch_row($res)){
            if($row[0])
              header("Location: dispensa.php");
            else{//se il prodotto con $barcode non è presente tra i prodotti conosciuti
              $_SESSION['barcode'] = $barcode ;
              $_SESSION['scadenza'] = $scadenza;

echo<<<end
              <p>Le informazioni relative al prodotto che vuoi inserire <strong>non sono state trovate</strong>, per favore inseriscile manulamente.</p>

              <link rel="stylesheet" href="css/normalize.css">
              <link rel='stylesheet prefetch' href='http://maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css'>
              <link rel="stylesheet" href="css/style.css">

              <ul class="logmod__tabs">
                <li data-tabtar="lgm-1"></li>
              </ul>

              <div class="logmod__heading">
                <span class="logmod__heading-subtitle"></span>
              </div>

              <form accept-charset="utf-8" action="$phpself" class="simform" method="post" id="register_form">
                <div class="smin">
                  <div class="input string optional">
                    <label class="string optional">Marca *</label>
                    <input class="string optional" maxlength="20" placeholder="Marca" type="text" size="20" name="marca_prod" required/>
                  </div>
                </div>
                <div class="smin">
                  <div class="input string optional">
                    <label class="string optional">Nome *</label>
                    <input class="string optional" maxlength="50" placeholder="Nome" type="text" size="20" name="nome_prod" required/>
                  </div>
                </div>
                <div class="smin">
                  <div class="input string optional">
                    <label class="string optional">Tipo *</label>
                    <input class="string optional" maxlength="50" placeholder="Tipo" size="20" type="text" name="tipo_prod" required/>
                  </div>
                </div>
                <div class="smin">
                  <div class="input string optional">
                    <label class="string optional">Quantità *</label>
                    <input class="string optional" placeholder="Quantità" type="number" min="1" name="v_prod" required/>
                  </div>
                </div>
                <div class="smin">
                  <div class="input string optional">
                    <label class="string optional">Unità di misura *</label>
                    <select name="um_prod">
                      <option value="l">l</option>
                      <option value="ml">ml</option>
                      <option value="kg" selected>kg</option>
                      <option value="g">g</option>
                    </select>
                  </div>
                </div>

                <div class="simform__actions">
                  <input class="submit" name="aggiungi_full" type="submit" value="Aggiungi" />
                </div>
              </form>
end;
          }
        }
      }
      else{//chiedi solo barcode e data
echo<<<end
          <link rel="stylesheet" href="css/normalize.css">
          <link rel='stylesheet prefetch' href='http://maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css'>
          <link rel="stylesheet" href="css/style.css">

          <p>Inserisci il barcode e la data di scadenza del prodotto che vuoi aggiungere alla tua dispensa.</p>

          <ul class="logmod__tabs">
            <li data-tabtar="lgm-1"></li>
          </ul>

          <div class="logmod__heading">
            <span class="logmod__heading-subtitle"></span>
          </div>

          <form accept-charset="utf-8" action="$phpself" class="simform" method="post" id="register_form">
            <div class="smin">
              <div class="input string optional">
                <label class="string optional">Barcode *</label>
                <input class="string optional" maxlength="13" placeholder="Barcode" type="text" size="13" name="barcode" required/>
              </div>
            </div>
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
        }
    ?>

</body>
</html>