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

    if(isset($_GET['ricetta_nome'])){
      $ricetta = $_GET['ricetta_nome'];
      $n_persone = $_POST['persone'];

      $pers_ricetta = array($ricetta => $n_persone);
      $_SESSION['pers_ricetta'] = $pers_ricetta;
    }
  }
?>
<html lang="en" class="no-js">
<head>
  <title>Lista della spesa</title>
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
          <a class="current-demo" href="$phpself?page=lista_spesa" title="lista_spesa">Lista della spesa</a>
        </nav>
end;
      ?>
    </header>
    <div class="component">
    <?php
      echo "<p>
              Qui puoi vedere i prodotti che ti consigliamo di acquistare per poter utilizzare le ricette che hai scelto, cerchiamo sempre
              il prodotto al prezzo più vantaggioso per te.
            </p>
            <p>
              Quando effettui un acquisto tra quelli proposti, utilizza la <strong>&#10003</strong> corrispondente alla riga interessata per
              aggiungerlo automaticamente alla tua dispensa.
            </p>
            <p>
              Se non sei interessato ad acquistare un dato prodotto che ti consigliamo, utilizza la <strong>&#10007</strong> per rimuoverlo dalla
              tua lista della spesa.
            </p>";

      if(isset($ricetta)){
        mysql_query("DROP VIEW IF EXISTS TipiProdottoMancanti") or die(mysql_error());
        #seleziona i TipoProdotto che mancano o che non sono in quantità sufficiente in dispensa per preaparare $ricetta per $n_persone persone
        $query = "  CREATE VIEW TipiProdottoMancanti AS
                    SELECT TipoProdotto,(QuantitaV/4)*$n_persone AS QuantitaMancante, QuantitaV AS QuantitaPer4Pers
                    FROM Ingrediente
                    WHERE NomeRicetta = \"$ricetta\"
                    AND TipoProdotto NOT IN (SELECT TipoProdotto FROM ProdottoInDispensa WHERE Utente = \"$username\")
                    UNION
                    SELECT PD.TipoProdotto, ((I.QuantitaV/4)*$n_persone-SUM(PD.QuantitaV)) AS QuantitaMancante,I.QuantitaV AS QuantitaPer4Pers
                    FROM Ingrediente I JOIN ProdottoInDispensa PD ON I.TipoProdotto = PD.TipoProdotto
                    WHERE I.NomeRicetta = \"$ricetta\" AND PD.Utente = \"$username\"
                    GROUP BY PD.TipoProdotto
                    HAVING SUM(PD.QuantitaV) < (I.QuantitaV/4)*$n_persone";

        mysql_query($query) or die(mysql_error());

        #Per i TipiProdottiMancanti sceglie  il miglior prezzo tra quelli in vendita
        mysql_query("DROP VIEW IF EXISTS MigliorPrezzoPerTipo") or die(mysql_error());
        $query = "CREATE VIEW MigliorPrezzoPerTipo AS
                    SELECT T.TipoProdotto, MIN(Prezzo) AS MigliorPrezzo, QuantitaMancante,PV.CapacitaV
                    FROM TipiProdottoMancanti T JOIN ProdottoInVendita PV ON T.TipoProdotto = PV.TipoProdotto
                    WHERE (Prezzo/PV.CapacitaV) = (SELECT MIN(Prezzo/P.CapacitaV)
                                                   FROM TipiProdottoMancanti TPM JOIN ProdottoInVendita P ON TPM.TipoProdotto = P.TipoProdotto
                                                   WHERE P.TipoProdotto = PV.TipoProdotto)
                    GROUP BY T.TipoProdotto";

        mysql_query($query) or die(mysql_error());

        #Restituisce la lista di acquisti consigliati basandosi sulle due query precedenti
        mysql_query("DROP VIEW IF EXISTS ConsigliAcquisti") or die(mysql_error());
        $query = "CREATE VIEW ConsigliAcquisti AS
                    SELECT MigliorPrezzo, Barcode, Filiale, Negozio, CEIL(M.QuantitaMancante/PV.CapacitaV) AS ConfezioniDaComprare
                    FROM MigliorPrezzoPerTipo M JOIN ProdottoInVendita PV ON M.TipoProdotto = PV.TipoProdotto
                    WHERE MigliorPrezzo = Prezzo
                    GROUP BY Barcode" ;

        mysql_query($query) or die(mysql_error());

        //controllo ListaSpesa per decidere se insert o update
        $query = "SELECT DISTINCT Username,Barcode,ConfezioniDaComprare
                FROM ConsigliAcquisti,Utente
                WHERE Username = \"$username\"";

        $res = mysql_query($query) or die(mysql_error());

        while($row = mysql_fetch_assoc($res)){
          $username = $row['Username'];
          $barcode = $row['Barcode'];
          $confezioni = $row['ConfezioniDaComprare'];
          //Se in ListaSpesa esiste già il prodotto $barcode => ne aumento le confezioni da comprare, altrimenti aggiungo una nuova riga a ListaSpesa
          mysql_query("CALL aggiusta_lista_spesa(\"$username\",\"$barcode\",\"$confezioni\")");
        }
      }
      #mostra le informazioni complete per i prodotti in ListaSpesa
      $query = "SELECT DISTINCT PV.Barcode, CONCAT(PV.Nome,' ',PV.Marca) AS Prodotto,N.Nome AS Negozio,
                                CONCAT(F.Via,' ',F.Numero,' (',F.Città,')') AS Indirizzo, PV.Prezzo,L.N_confezioni
                FROM ((ListaSpesa L JOIN ProdottoInVendita PV ON L.Prodotto = PV.Barcode)
                      JOIN Negozio N ON L.Negozio = N.P_IVA) JOIN Filiale F ON L.Filiale = F.Codice
                WHERE F.Negozio = N.P_IVA AND L.Utente = \"$username\" AND PV.Prezzo = ( SELECT MIN(PV.Prezzo)
                                                                                         FROM ProdottoInVendita PV
                                                                                         WHERE PV.Barcode = L.Prodotto)
                GROUP BY PV.Barcode";

      build_result_table($query);

      #per evitare che, ricaricando la pagina, vengano di nuovo aggiunti gli stessi prodotti(effetto indesiderato del REFRESH)
      if(isset($_GET['ricetta_nome']))
        header("Location: lista_spesa.php?page=lista_spesa");
    ?>
</body>
</html>