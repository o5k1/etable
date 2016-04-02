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
  <title>Ricette</title>
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
          <a class="current-demo" href="$phpself" title="ricette">Ricette</a>
          <a href="lista_spesa.php?page=lista_spesa" title="lista_spesa">Lista della spesa</a>
        </nav>
end;
      ?>
    </header>
    <div class="component">
     <!--Tabella risultati query-->
      <?php
        echo "<p>Qui puoi vedere le ricette consigliate per consumare i prodotti che stanno scadendo, seleziona il nome di una ricetta per
                 ottenere maggiori informazioni.
              </p>
              <p>
                 La colonna <strong>ProdottiConsumati</strong> indica quanti tipi diversi di prodotti in scadenza possono essere
                 potenzialmente consumati scegliendo una certa ricetta.
             </p>
             <p>
                 Quando utilizzi una ricetta selezionala dalla lista tramite <strong>&#10003</strong> così da aggiornare le quantità dei tuoi prodotti in
                 dispensa, sottraendovi le rispettive quantità degli ingredienti che hai consumato.
             </p>";

        #resituisce il numero di prodotti in scadenza
        $query = "SELECT COUNT(DISTINCT TipoProdotto) AS n
                  FROM ProdottoInDispensa
                  WHERE Utente=\"$username\" AND DataScadenza < DATE_ADD(CURDATE(),INTERVAL 2 WEEK)";
        $res = mysql_query($query) or die(mysql_error());
        $row = mysql_fetch_assoc($res);
        $n_prod_scad = 0;
        if($row)
          $n_prod_scad = $row['n'];


        #ricette che utilizzano prodotti in dispensa che stanno scadendo
        $query = "SELECT R.Nome,R.Portata,R.Tempo,R.Difficolta AS Difficoltà,
                         CONCAT(COUNT(DISTINCT PD.TipoProdotto),' su ',$n_prod_scad) AS ProdottiConsumati
                  FROM (Ingrediente I JOIN Ricetta R ON I.NomeRicetta = R.Nome)
                       JOIN ProdottoInDispensa PD ON I.TipoProdotto = PD.TipoProdotto
                  WHERE PD.Utente = '$username' AND PD.DataScadenza < DATE_ADD(CURDATE(),INTERVAL 2 WEEK)
                  GROUP BY R.Nome
                  ORDER BY COUNT(*) DESC";

        mysql_set_charset("UTF8");
        $res = mysql_query($query) or die(mysql_error());

        $n_field=mysql_num_fields($res);

        if(mysql_num_rows($res)){
        for ($i=0; $i < $n_field; $i++) {
          $head[] = mysql_field_name($res, $i);
        }
        table_start($head);

        while($row = mysql_fetch_assoc($res)){
          echo "<tr>";
          foreach ($row as $key => $value) {
            if($key == 'Nome')
              echo "<td><a href=\"ricette_info.php?ricetta_nome=$value\">$value</a></td>";
            else
              echo "<td>$value</td>";
          }
          $nome = $row['Nome'];
          if(isset($_SESSION['pers_ricetta']["$nome"]))
            echo "<td><a href=\"ricette_cucinata.php?ricetta_nome=$nome\">&#10003</a></td>";
          echo "</tr>";
        }
        table_end();
      }
      ?>

</body>
</html>