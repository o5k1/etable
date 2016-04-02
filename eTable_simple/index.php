<?php
  session_start();
  include_once 'config.php';
  include_once 'library.php';

  if(isset($_SESSION['username'])){
    header("Location: dispensa.php");
  }
  if(isset($_POST['registrati'])){
    registra_user();
  }
  else
    if(isset($_POST['entra'])){
      login_user();
    }
?>
<html>
<head>
  <meta charset="UTF-8">
  <title>eTable|Entra - Registrati</title>
  <link rel="stylesheet" href="css/normalize.css">
  <link rel='stylesheet prefetch' href='http://maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css'>
  <link rel="stylesheet" href="css/style.css">
</head>
<body>
  <div id="title_reg">eTable</div>

  <div class="logmod">
    <div class="logmod__wrapper">
      <div class="logmod__container">
        <!--Tab Entra|Registrati-->
        <ul class="logmod__tabs">
          <li data-tabtar="lgm-2"><a href="#">Entra</a></li>
          <li data-tabtar="lgm-1"><a href="#">Registrati</a></li>
        </ul>

        <div class="logmod__tab-wrapper">
          <div class="logmod__tab lgm-1">

            <div class="logmod__heading">
              <span class="logmod__heading-subtitle">Inserisci i tuoi dati personali <strong>per creare un account</strong></span>
            </div>

            <div class="logmod__form">
              <!--Form Registrati-->
              <form accept-charset="utf-8" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>" class="simform" method="post" id="register_form">
                <div class="sminputs">
                  <div class="input string optional">
                    <label class="string optional">Nome *</label>
                    <input class="string optional" placeholder="Nome" type="text" size="50" maxlength="20" name="nome" required/>
                  </div>
                  <div class="input string optional">
                    <label class="string optional">Cognome *</label>
                    <input class="string optional" placeholder="Cognome" type="text" size="50" maxlength="20" name="cognome" required/>
                  </div>
                </div>
                <div class="sminputs">
                  <div class="input string optional">
                    <label class="string optional">Username *</label>
                    <input class="string optional" placeholder="Username" type="text" size="50" maxlength="20" name="username" required/>
                  </div>
                  <div class="input string optional">
                    <label class="string optional">Password *</label>
                    <input class="string optional" placeholder="Password" type="password" size="50" maxlength="20" name="password" required/>
                  </div>
                </div>
                <div class="simform__actions">
                  <input class="sumbit" name="registrati" type="submit" value="Crea Account" />
                </div>
              </form>
            </div>
          </div>

        <div class="logmod__tab lgm-2">
          <div class="logmod__heading">
            <span class="logmod__heading-subtitle">Inserisci il tuo username e la tua password <strong>per entrare</strong></span>
          </div>

          <div class="logmod__form">
            <!--Form Entra-->
            <form accept-charset="utf-8" action="<?php echo htmlspecialchars($_SERVER["PHP_SELF"]);?>" class="simform" method="post" id="login_form">
              <div class="sminputs">
                <div class="input full">
                  <label class="string optional">Username *</label>
                  <input class="string optional" placeholder="Username" type="text" size="50" maxlength="20" name="username" required/>
                </div>
              </div>
              <div class="sminputs">
                <div class="input full">
                  <label class="string optional">Password *</label>
                  <input class="string optional" placeholder="Password" type="password" size="50" maxlength="20" name="password" required/>
                </div>
              </div>

              <div class="simform__actions">
                <input class="sumbit" name="entra" type="submit" value="Entra" />
              </div>

            </form>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
<script src='http://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.3/jquery.min.js'></script>
<script src="js/index.js"></script>
</body>
</html>