<?php
  function registra_user(){
     //mysql_real_escape_string — Escapes special characters in a string for use in an SQL statement, prevent SQL_INJEcTION
    $nome = mysql_real_escape_string($_POST['nome']);
    $cognome = mysql_real_escape_string($_POST['cognome']);
    $username = mysql_real_escape_string($_POST['username']);
    $password = mysql_real_escape_string($_POST['password']);

    $query = "INSERT INTO Utente(Username,Password,Nome,Cognome)
                      VALUES('$username','$password','$nome','$cognome')";
    if(mysql_query($query)){
      $_SESSION['username'] = $username;
      $_SESSION['nome'] = $nome;
      $_SESSION['cognome'] = $cognome;

      header("Location: dispensa.php");
    }
    else
      die('REGISTRAZIONE FALLITA: Username non disponibile!');
  }

  function login_user(){
    $username = mysql_real_escape_string($_POST['username']);
    $password = mysql_real_escape_string($_POST['password']);
    $res=mysql_query("SELECT * FROM Utente WHERE Username='$username'");
    $row=mysql_fetch_array($res);
    if($row['Password']==$password){
      $_SESSION['username'] = $row['Username'];
      $_SESSION['nome'] = $row['Nome'];
      $_SESSION['cognome'] = $row['Cognome'];
      header("Location: dispensa.php");
    }
  }

  #inizia una tabella, usando gli elementi dell'array $head come header delle colonne
  function table_start($head){
    echo "<table><thead><tr>";
    foreach ($head as $value) {
      echo "<th>$value</th>";
    }
    echo "</tr></thead><tbody>";
  }

  #termina una tabella
  function table_end(){
    echo "</tbody></table>";
  }

  #costruisce la tabella che mostra il risultato della query $query
  function build_result_table($query){
    mysql_set_charset("UTF8") or die(mysql_error());
    $res = mysql_query($query) or die(mysql_error());

    $n_field=mysql_num_fields($res);

    if(isset($_GET['action']) && $_GET['action'] == "dispensa_rimuovi"){//se è stato cliccato il link "Rimuovi"
      $n_field++;

      if(mysql_num_rows($res)){
        for ($i=0; $i < $n_field-1; $i++) {
          $head[] = mysql_field_name($res, $i);
        }

        $head[] = " ";

        table_start($head);

        while($row = mysql_fetch_assoc($res)){
          echo "<tr>";
          foreach ($row as $value) {
            echo "<td>$value</td>";
          }

          $to_del_barcode = $row['Barcode'];
          echo "<td><a href=\"dispensa_rimuovi.php?to_del_barcode=$to_del_barcode\">&#10007</a></td>";
          echo "</tr>";
        }

        table_end();
      }
    }
    else
      if(isset($_GET['page']) && $_GET['page'] == 'lista_spesa'){//se sono in ListaSpesa
        $n_field += 2;


        if(mysql_num_rows($res)){
          for ($i=0; $i < $n_field-2; $i++) {
            $head[] = mysql_field_name($res, $i);
          }

          $head[] = " ";$head[] = " ";

          table_start($head);

          while($row = mysql_fetch_assoc($res)){
            echo "<tr>";
            foreach ($row as $value) {
              echo "<td>$value</td>";
            }
            $barcode = $row['Barcode'];
            echo "<td><a href=\"lista_spesa_acquistato.php?to_add_barcode=$barcode\">&#10003</a></td>";
            echo "<td><a href=\"lista_spesa_rimuovi.php?to_del_barcode=$barcode\">&#10007</a></td>";
            echo "</tr>";
          }
          table_end();
        }
      }
      else{//se non ho cliccato il link "Rimuovi"
        if(mysql_num_rows($res)){
          for ($i=0; $i < $n_field; $i++) {
            $head[] = mysql_field_name($res, $i);
          }
          table_start($head);

          while($row = mysql_fetch_assoc($res)){
            echo "<tr>";
            foreach ($row as $key => $value) {
              echo "<td>$value</td>";
            }
            echo "</tr>";
          }
          table_end();
        }
      }
  }
?>