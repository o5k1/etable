-- phpMyAdmin SQL Dump
-- version 4.4.3
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Creato il: Ago 02, 2015 alle 14:27
-- Versione del server: 5.6.24
-- Versione PHP: 5.6.8

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- Database: `eTable`
--

DELIMITER $$
--
-- Procedure
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `acquista_prodotto`(IN `username` VARCHAR(20), IN `barcode` CHAR(13), IN `scadenza` DATE)
    NO SQL
BEGIN

  	DECLARE var_tipo_prodotto VARCHAR(50);
    DECLARE var_marca VARCHAR(20);
    DECLARE var_nome VARCHAR(50);
    DECLARE var_quantita_V FLOAT UNSIGNED;
    DECLARE var_quantita_UM CHAR(2);
    DECLARE var_confezioni SMALLINT;
   
    SELECT L.N_confezioni
    INTO var_confezioni
    FROM ListaSpesa L
    WHERE L.Prodotto = barcode;
    
	DELETE FROM ListaSpesa
           WHERE Utente = username AND Prodotto = barcode;
	
	CALL aggiusta_dispensa(barcode,scadenza,username,var_confezioni);
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `aggiusta_dispensa`(IN `prodotto` CHAR(13), IN `scadenza` DATE, IN `username` VARCHAR(20), IN `confezioni` INT)
BEGIN
	DECLARE var_tipo_prodotto VARCHAR(50);
    DECLARE var_marca VARCHAR(20);
    DECLARE var_nome VARCHAR(50);
    DECLARE var_quantita_V FLOAT UNSIGNED;
    DECLARE var_quantita_UM CHAR(2);
    DECLARE quant FLOAT(5) UNSIGNED;
    
    SELECT CapacitaV*confezioni
    INTO quant
    FROM ProdottoInVendita
    WHERE Barcode = prodotto
    LIMIT 1;

	IF EXISTS(
    	SELECT * FROM ProdottoInDispensa P WHERE P.Utente = username AND P.Barcode = prodotto
    	AND P.DataScadenza = scadenza) THEN
        	
            UPDATE ProdottoInDispensa
    		SET QuantitaV = QuantitaV + quant
     		WHERE Utente = username AND Barcode = prodotto AND DataScadenza = scadenza;
            
    ELSE/*In ProdottoInDispensa non c'è riga con stesso Utente-Barcode-Scadenza*/
        	
        	SELECT DISTINCT P.TipoProdotto,P.Marca,P.Nome,P.CapacitaUM
            INTO var_tipo_prodotto,var_marca,var_nome,var_quantita_UM
            FROM ProdottoInVendita P
            WHERE P.Barcode = prodotto;

            INSERT INTO ProdottoInDispensa(Barcode,Utente,DataScadenza,TipoProdotto,Marca,Nome,QuantitaV,QuantitaUM)
            VALUES(prodotto,username,scadenza,var_tipo_prodotto,var_marca,var_nome,quant,var_quantita_UM);

    END IF;
	
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `aggiusta_lista_spesa`(IN `username` VARCHAR(20), IN `prodotto` CHAR(13), IN `confezioni` SMALLINT)
BEGIN
	DECLARE var_prezzo DECIMAL(7,2);
    DECLARE var_filiale SMALLINT;
    DECLARE var_negozio CHAR(11);
        
	IF EXISTS(
    	SELECT * FROM ListaSpesa L WHERE L.Utente = username
		AND L.Prodotto = prodotto) THEN
    
    	UPDATE ListaSpesa
    		SET N_confezioni = N_confezioni+confezioni
     		WHERE Utente = username AND Prodotto = prodotto;
    ELSE
    	SELECT MigliorPrezzo,Filiale,Negozio
        INTO var_prezzo,var_filiale,var_negozio
        FROM ConsigliAcquisti C
        WHERE C.Barcode = prodotto;
        
        INSERT INTO ListaSpesa(Utente,Prodotto,Filiale,Negozio,Prezzo,N_confezioni)
       	VALUES(username,prodotto,var_filiale,var_negozio,var_prezzo,confezioni);
	END IF;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `elimina_prodotto_finito`(IN `username` VARCHAR(20))
BEGIN
  WHILE EXISTS (SELECT * FROM ProdottoInDispensa WHERE QuantitaV<=0 and Utente=username) DO
    DELETE FROM ProdottoInDispensa WHERE QuantitaV<=0 and Utente=username;
  END WHILE;
END$$

--
-- Funzioni
--
CREATE DEFINER=`root`@`localhost` FUNCTION `autocomplete_prod_info`(`brcode` CHAR(13), `usr` VARCHAR(20), `scadenza` DATE) RETURNS tinyint(1)
BEGIN

    DECLARE var_tipo_prodotto VARCHAR(50) DEFAULT '-1';
    DECLARE var_marca VARCHAR(20);
    DECLARE var_nome VARCHAR(50);
    DECLARE var_quantita_V FLOAT UNSIGNED;
    DECLARE var_quantita_UM CHAR(2);
	
    SELECT DISTINCT P.TipoProdotto,P.Marca,P.Nome,P.CapacitaV,P.CapacitaUM
    INTO var_tipo_prodotto,var_marca,var_nome,var_quantita_V,var_quantita_UM
    FROM ProdottoInVendita P
    WHERE P.Barcode = brcode;
    
    IF (var_tipo_prodotto = '-1') THEN
        	RETURN false;
    ELSE    
            CALL aggiusta_dispensa(brcode,scadenza,usr,'1');

        	RETURN true;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `is_recipe_available`(`ricetta` VARCHAR(100), `n_pers` INT UNSIGNED, `usr` VARCHAR(20)) RETURNS tinyint(1)
    NO SQL
BEGIN
	/*Se mancano totalmente dei Tipi di Ingrediente tra i Tipi in Dispensa => FALSE*/
	IF EXISTS(SELECT TipoProdotto 
              FROM Ingrediente 
              WHERE NomeRicetta = ricetta AND TipoProdotto NOT IN(SELECT TipoProdotto
                                                                              FROM ProdottoInDispensa
                                                                              WHERE Utente = usr)) THEN
		RETURN FALSE;
    ELSE
    /*Se non ho abbastanza QuantitàV dgli ingredienti */
    	IF EXISTS(SELECT*
				  FROM(SELECT Barcode,PD.TipoProdotto,SUM(PD.QuantitaV) AS QuantitaDispensa,I.QuantitaV AS QuantitaNecessaria, 
                       		  SUM(PD.QuantitaV)-(I.QuantitaV/4)*n_pers AS QuantitaRimanente
     				   FROM Ingrediente I JOIN ProdottoInDispensa PD ON I.TipoProdotto = PD.TipoProdotto
	 				   WHERE I.NomeRicetta = ricetta AND PD.Utente = usr
     				   GROUP BY PD.TipoProdotto) AS T
				  WHERE T.QuantitaRimanente < 0 
				  ) THEN
                  
           RETURN FALSE;
         
         ELSE            
            
         	RETURN TRUE;
            
    	END IF;	
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `presente_in_dispensa`(`prodotto` CHAR(13), `username` VARCHAR(20), `scadenza` DATE) RETURNS tinyint(1)
    NO SQL
BEGIN
		IF EXISTS(
    				SELECT * FROM ProdottoInDispensa P WHERE P.Utente = username AND P.Barcode = prodotto
    				AND P.DataScadenza = scadenza) THEN
        	
			RETURN TRUE;
            
    ELSE/*In ProdottoInDispensa non c'è riga con stesso Utente-Barcode-Scadenza*/
        	
        	RETURN FALSE;

    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura stand-in per le viste `ConsigliAcquisti`
--
CREATE TABLE IF NOT EXISTS `ConsigliAcquisti` (
`MigliorPrezzo` decimal(7,2)
,`Barcode` char(13)
,`Filiale` smallint(5) unsigned
,`Negozio` char(11)
,`ConfezioniDaComprare` double(17,0)
);

-- --------------------------------------------------------

--
-- Struttura della tabella `Filiale`
--

CREATE TABLE IF NOT EXISTS `Filiale` (
  `Codice` smallint(5) unsigned NOT NULL DEFAULT '0',
  `Negozio` char(11) COLLATE utf8_unicode_ci NOT NULL,
  `Città` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `Via` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `Numero` smallint(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dump dei dati per la tabella `Filiale`
--

INSERT INTO `Filiale` (`Codice`, `Negozio`, `Città`, `Via`, `Numero`) VALUES
(0, '00348980285', 'Padova', 'Piazza Metelli', 6),
(0, '00495791204', 'Padova', 'Via Facciolati', 111),
(0, '00882800212', 'Padova', 'Piazzale Stazione Ferroviaria', 14),
(0, '01515921201', 'Limena', 'Via F.lli Cervi', 3),
(0, '02036440275', 'Padova', 'Galleria San Carlo', 15),
(0, '02275030233', 'Padova', 'Via Cardinal Callegari', 58),
(0, '03195090240', 'Padova', 'Via San Marco', 101),
(1, '00348980285', 'Padova', 'Via Alessandro Prosdocimi', 2),
(1, '00495791204', 'Padova', 'Via Santa Sofia', 44),
(1, '00882800212', 'Padova', 'P.tta Conciapelli', 24),
(1, '01515921201', 'Cadoneghe', 'Strada Statale del Santo', 88),
(1, '02036440275', 'Padova', 'P.tta Garzeria', 3),
(1, '02275030233', 'Padova', 'Via Sorio', 144),
(1, '03195090240', 'Padova', 'Via Goito', 134),
(2, '00348980285', 'Padova', 'Via Chiesanuova', 71),
(2, '00882800212', 'Padova', 'Via Lagrange', 25),
(2, '02036440275', 'Padova', 'P.tta S. Croce', 17);

-- --------------------------------------------------------

--
-- Struttura della tabella `Ingrediente`
--

CREATE TABLE IF NOT EXISTS `Ingrediente` (
  `NomeRicetta` varchar(100) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `TipoProdotto` varchar(50) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `QuantitaV` float unsigned NOT NULL,
  `QuantitaUM` varchar(2) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dump dei dati per la tabella `Ingrediente`
--

INSERT INTO `Ingrediente` (`NomeRicetta`, `TipoProdotto`, `QuantitaV`, `QuantitaUM`) VALUES
('Gnocchi con funghi misti', 'Aglio', 3, 'g'),
('Pasta con pesto alla genovese', 'Aglio', 5, 'g'),
('Anatra all''arancia', 'Anatra', 2300, 'g'),
('Anatra all''arancia', 'Arancia', 50, 'g'),
('Pasta con pesto alla genovese', 'Basilico', 50, 'g'),
('Anatra all''arancia', 'Burro', 25, 'g'),
('Pasta alla papalina', 'Burro', 50, 'g'),
('Arrosticini', 'Carne ovina', 300, 'g'),
('Pasta alla papalina', 'Cipolla', 50, 'g'),
('Gnocchi con funghi misti', 'Funghi', 350, 'g'),
('Gnocchi con funghi misti', 'Gnocchi', 350, 'g'),
('Anatra all''arancia', 'Liquore', 110, 'g'),
('Arrosticini', 'Olio extravergine', 30, 'ml'),
('Gnocchi con funghi misti', 'Olio extravergine', 100, 'ml'),
('Pasta con pesto alla genovese', 'Olio extravergine', 100, 'ml'),
('Carbonara al forno', 'Pancetta affumicata', 150, 'g'),
('Carbonara al forno', 'Panna da cucina', 200, 'ml'),
('Pasta alla papalina', 'Panna da cucina', 200, 'g'),
('Pasta alla papalina', 'Parmigiano Reggiano', 60, 'g'),
('Pasta con pesto alla genovese', 'Parmigiano Reggiano', 70, 'g'),
('Carbonara al forno', 'Pasta', 350, 'g'),
('Pasta alla papalina', 'Pasta', 350, 'g'),
('Pasta con pesto alla genovese', 'Pasta', 350, 'g'),
('Carbonara al forno', 'Pecorino', 100, 'g'),
('Pasta con pesto alla genovese', 'Pecorino', 30, 'g'),
('Pasta con pesto alla genovese', 'Pinoli', 15, 'g'),
('Gnocchi con funghi misti', 'Prezzemolo', 10, 'g'),
('Pasta alla papalina', 'Prosciutto crudo', 100, 'g'),
('Arrosticini', 'Rosmarino', 3, 'g'),
('Gnocchi con funghi misti', 'Scalogno', 3, 'g'),
('Carbonara al forno', 'Uova', 3, ''),
('Pasta alla papalina', 'Uova', 3, ''),
('Gnocchi con funghi misti', 'Vino bianco', 60, 'ml');

-- --------------------------------------------------------

--
-- Struttura della tabella `ListaSpesa`
--

CREATE TABLE IF NOT EXISTS `ListaSpesa` (
  `Utente` varchar(20) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `Prodotto` char(13) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `Filiale` smallint(5) unsigned NOT NULL DEFAULT '0',
  `Negozio` char(11) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `Prezzo` decimal(7,2) NOT NULL,
  `N_confezioni` smallint(6) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dump dei dati per la tabella `ListaSpesa`
--

INSERT INTO `ListaSpesa` (`Utente`, `Prodotto`, `Filiale`, `Negozio`, `Prezzo`, `N_confezioni`) VALUES
('mconti', '8002470442016', 0, '01515921201', '2.30', 1),
('mconti', '8002710412008', 2, '02036440275', '3.15', 1),
('mconti', '8003046042299', 0, '00882800212', '0.85', 1),
('mconti', '8065540426759', 1, '00348980285', '1.50', 1),
('mconti', '8135540426759', 1, '00348980285', '1.50', 1);

-- --------------------------------------------------------

--
-- Struttura stand-in per le viste `MigliorPrezzoPerTipo`
--
CREATE TABLE IF NOT EXISTS `MigliorPrezzoPerTipo` (
`TipoProdotto` varchar(50)
,`MigliorPrezzo` decimal(7,2)
,`QuantitaMancante` double
,`CapacitaV` float
);

-- --------------------------------------------------------

--
-- Struttura della tabella `Negozio`
--

CREATE TABLE IF NOT EXISTS `Negozio` (
  `P_IVA` char(11) COLLATE utf8_unicode_ci NOT NULL,
  `Nome` varchar(50) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dump dei dati per la tabella `Negozio`
--

INSERT INTO `Negozio` (`P_IVA`, `Nome`) VALUES
('00348980285', 'Alì-Alìper'),
('00495791204', 'Sisa'),
('00882800212', 'Despar-Interspar-Eurospar'),
('01515921201', 'Coop'),
('02036440275', 'Pam'),
('02275030233', 'Lidl'),
('03195090240', 'Prix Quality'),
('03320960374', 'Conad');

-- --------------------------------------------------------

--
-- Struttura stand-in per le viste `ProdottiConsumati`
--
CREATE TABLE IF NOT EXISTS `ProdottiConsumati` (
`Barcode` char(13)
,`Utente` varchar(20)
,`DataScadenza` date
,`TipoProdotto` varchar(50)
,`Marca` varchar(20)
,`Nome` varchar(50)
,`QuantitaDispensa` float
,`QuantitaNecessaria` double
,`QuantitaRimasta` double
);

-- --------------------------------------------------------

--
-- Struttura della tabella `ProdottoInDispensa`
--

CREATE TABLE IF NOT EXISTS `ProdottoInDispensa` (
  `Barcode` char(13) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `Utente` varchar(20) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `DataScadenza` date NOT NULL DEFAULT '0000-00-00',
  `TipoProdotto` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `Marca` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `Nome` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `QuantitaV` float NOT NULL,
  `QuantitaUM` varchar(2) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dump dei dati per la tabella `ProdottoInDispensa`
--

INSERT INTO `ProdottoInDispensa` (`Barcode`, `Utente`, `DataScadenza`, `TipoProdotto`, `Marca`, `Nome`, `QuantitaV`, `QuantitaUM`) VALUES
('0', 'mconti', '2015-07-31', 'Pasta', 'Barilla', 'Pennette Rigate', 412, 'g'),
('8003046042296', 'mconti', '2015-08-26', 'Pecorino', 'Girau', 'Pecorino Romano', 50, 'g'),
('8004350130051', 'mconti', '2015-09-02', 'Pasta', 'Zara', 'Vermicelli', 212, 'g'),
('8050329378594', 'mconti', '2015-08-26', 'Uova', 'F.lli Lago', 'Uova Fresche Pasta Gialla', 4, ''),
('8069087000000', 'mconti', '2015-08-26', 'Pancetta affumicata', 'Becher', 'Dadini di pancetta affumicata', 24, 'g');

-- --------------------------------------------------------

--
-- Struttura della tabella `ProdottoInVendita`
--

CREATE TABLE IF NOT EXISTS `ProdottoInVendita` (
  `Barcode` char(13) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `Filiale` smallint(5) unsigned NOT NULL DEFAULT '0',
  `Negozio` char(11) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
  `TipoProdotto` varchar(50) COLLATE utf8_unicode_ci DEFAULT NULL,
  `Prezzo` decimal(7,2) NOT NULL,
  `Marca` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `Nome` varchar(50) COLLATE utf8_unicode_ci NOT NULL,
  `CapacitaV` float NOT NULL,
  `CapacitaUM` enum('l','ml','kg','g') COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dump dei dati per la tabella `ProdottoInVendita`
--

INSERT INTO `ProdottoInVendita` (`Barcode`, `Filiale`, `Negozio`, `TipoProdotto`, `Prezzo`, `Marca`, `Nome`, `CapacitaV`, `CapacitaUM`) VALUES
('3018300000139', 0, '01515921201', 'Liquore', '31.00', 'Grand Marnier', 'Grand Marnier Cordon Rouge', 700, 'ml'),
('3018300000139', 1, '00882800212', 'Liquore', '31.00', 'Grand Marnier', 'Grand Marnier Cordon Rouge', 700, 'ml'),
('3018300000139', 2, '00882800212', 'Liquore', '31.00', 'Grand Marnier', 'Grand Marnier Cordon Rouge', 700, 'ml'),
('8000390009883', 0, '01515921201', 'Riso', '1.20', 'Flora', 'Riso bell''insalata', 1000, 'g'),
('8001120010827', 0, '01515921201', 'Burro', '2.35', 'Coop', 'Burro ', 500, 'g'),
('8001120010827', 1, '01515921201', 'Burro', '2.00', 'Coop', 'Burro ', 500, 'g'),
('8001405000024', 0, '01515921201', 'Fette Biscottate', '1.73', 'GrissinBon', 'Fette Biscottate', 250, 'g'),
('8001405000024', 1, '00882800212', 'Fette Biscottate', '1.80', 'GrissinBon', 'Fette Biscottate', 250, 'g'),
('8001405000024', 1, '01515921201', 'Fette Biscottate', '2.00', 'GrissinBon', 'Fette Biscottate', 250, 'g'),
('8001405000024', 2, '00882800212', 'Fette Biscottate', '1.50', 'GrissinBon', 'Fette Biscottate', 250, 'g'),
('8001605011547', 0, '01515921201', 'Burro', '1.50', 'Brazzale', 'Burro delle Alpi', 100, 'g'),
('8001605011547', 1, '01515921201', 'Burro', '1.50', 'Brazzale', 'Burro delle Alpi', 100, 'g'),
('8001665125789', 0, '01515921201', 'Gnocchi', '1.56', 'Giovanni Rana', 'Gnocchetti di patate', 500, 'g'),
('8002470442016', 0, '01515921201', 'Olio extravergine', '2.30', 'Carapelli', 'Olio Delizia', 750, 'ml'),
('8002470442016', 1, '00882800212', 'Olio extravergine', '2.30', 'Carapelli', 'Olio Delizia', 750, 'ml'),
('8002590042752', 2, '02036440275', 'Cracker', '2.15', 'Misura', 'Crackers alla soia', 400, 'g'),
('8002710412007', 1, '00882800212', 'Grana Padano', '3.20', 'Zanetti', 'Grana Padano', 200, 'g'),
('8002710412008', 1, '00882800212', 'Parmigiano Reggiano', '3.20', 'Zanetti', 'Parmigiano Reggiano', 200, 'g'),
('8002710412008', 2, '02036440275', 'Parmigiano Reggiano', '3.15', 'Zanetti', 'Parmigiano Reggiano', 200, 'g'),
('8002795001493', 0, '01515921201', 'Succo ACE', '1.60', 'Sterilgarda', 'Succo ACE', 1000, 'ml'),
('8003000120701', 0, '01515921201', 'Dolce', '2.30', 'Cameo', 'Preparato per torta al limone', 100, 'ml'),
('8003000140310', 0, '03195090240', 'Zafferano', '2.38', 'Cameo', 'Zafferano', 0.3, 'g'),
('8003044410296', 0, '00882800212', 'Anatra', '10.00', 'Macelleria Zanetti', 'Anatra pulita intera', 2400, 'g'),
('8003046042296', 0, '00882800212', 'Pecorino', '3.57', 'Girau', 'Pecorino Romano', 200, 'g'),
('8003046042296', 1, '00882800212', 'Pecorino', '3.50', 'Girau', 'Pecorino Romano', 200, 'g'),
('8003046042299', 0, '00882800212', 'Pinoli', '0.85', 'Coop', 'Pinoli Sgusciati', 10, 'g'),
('8003046042299', 1, '00882800212', 'Pinoli', '1.00', 'Coop', 'Pinoli Sgusciati', 10, 'g'),
('8004015000024', 1, '01515921201', 'Prosciutto crudo', '1.20', 'F.lli Galloni', 'Prosciutto di Parma in vaschetta', 200, 'g'),
('8004015000024', 2, '00882800212', 'Prosciutto crudo', '1.27', 'F.lli Galloni', 'Prosciutto di Parma in vaschetta', 200, 'g'),
('8004350130051', 0, '00348980285', 'Pasta', '0.69', 'Zara', 'Vermicelli', 500, 'g'),
('8004350130051', 0, '00882800212', 'Pasta', '0.69', 'Zara', 'Vermicelli', 500, 'g'),
('8004350130051', 0, '01515921201', 'Pasta', '0.69', 'Zara', 'Vermicelli', 500, 'g'),
('8004350130051', 1, '00348980285', 'Pasta', '0.69', 'Zara', 'Vermicelli', 500, 'g'),
('8004350130051', 1, '00882800212', 'Pasta', '0.59', 'Zara', 'Vermicelli', 500, 'g'),
('8004350130051', 1, '01515921201', 'Pasta', '0.69', 'Zara', 'Vermicelli', 500, 'g'),
('8004350130051', 2, '00348980285', 'Pasta', '0.69', 'Zara', 'Vermicelli', 500, 'g'),
('8005850113025', 0, '03195090240', 'Tonno in Scatola', '2.30', 'Nostromo', 'Tonno all''olio d''oliva', 320, 'g'),
('8008690014728', 1, '01515921201', 'Panna da cucina', '0.80', 'Granarolo', 'Panna da cucina', 100, 'ml'),
('8008690054718', 0, '01515921201', 'Panna da cucina', '1.10', 'Ala', 'Panna da cucina', 200, 'ml'),
('8013355000290', 0, '01515921201', 'Biscotti', '1.89', 'Pavesi', 'Pavesini', 200, 'g'),
('8013355000290', 1, '00882800212', 'Biscotti', '1.89', 'Pavesi', 'Pavesini', 200, 'g'),
('8013355000290', 1, '01515921201', 'Biscotti', '1.89', 'Pavesi', 'Pavesini', 200, 'g'),
('8013355000290', 2, '00882800212', 'Biscotti', '1.89', 'Pavesi', 'Pavesini', 200, 'g'),
('8014204500290', 1, '00882800212', 'Carne ovina', '7.70', 'Macelleria Lai', 'Braciole di Abbacchio', 500, 'g'),
('8014205000290', 2, '00882800212', 'Carne ovina', '4.10', 'Macelleria Lai', 'Bistecche di pecora sarda', 500, 'g'),
('8017700975691', 0, '00882800212', 'Limone', '1.50', 'Fratelli Santini', 'Limoni Fratelli Santini', 750, 'g'),
('8017700975691', 1, '00882800212', 'Limone', '1.20', 'Fratelli Santini', 'Limoni Fratelli Santini', 750, 'g'),
('8017700975691', 2, '00882800212', 'Limone', '1.30', 'Fratelli Santini', 'Limoni Fratelli Santini', 750, 'g'),
('8017700975692', 0, '00882800212', 'Arancia', '1.53', 'Fratelli Santini', 'Arancie Fratelli Santini', 750, 'g'),
('8017700975692', 1, '00882800212', 'Arancia', '1.22', 'Fratelli Santini', 'Arancie Fratelli Santini', 750, 'g'),
('8017700975692', 2, '00882800212', 'Arancia', '1.31', 'Fratelli Santini', 'Arancie Fratelli Santini', 750, 'g'),
('8032974000870', 0, '03195090240', 'Tortellini', '2.15', 'Prix Quality', 'Tortellini grana e spek', 400, 'g'),
('8032974000887', 0, '03195090240', 'Tortellini', '2.15', 'Prix Quality', 'Tortellini ricotta e spinaci', 400, 'g'),
('8033166502055', 1, '01515921201', 'Vino bianco', '21.00', 'Fattoria il Palagio', 'Sauvignon', 750, 'ml'),
('8033199902055', 0, '01515921201', 'Vino bianco', '17.00', 'Barattin', 'Verduzzo Dorato', 750, 'ml'),
('8050329378594', 0, '00882800212', 'Uova', '1.65', 'F.lli Lago', 'Uova Fresche Pasta Gialla', 6, ''),
('8050329378594', 1, '00882800212', 'Uova', '1.35', 'F.lli Lago', 'Uova Fresche Pasta Gialla', 6, ''),
('8065540426759', 1, '00348980285', 'Aglio', '1.50', 'Cannamela', 'Aglio liofilizzato', 70, 'g'),
('8065540426759', 2, '00882800212', 'Aglio', '1.62', 'Cannamela', 'Aglio liofilizzato', 70, 'g'),
('8069087000000', 0, '01515921201', 'Pancetta affumicata', '1.90', 'Becher', 'Dadini di pancetta affumicata', 200, 'g'),
('8069087000000', 1, '01515921201', 'Pancetta affumicata', '1.60', 'Becher', 'Dadini di pancetta affumicata', 200, 'g'),
('8076203543340', 2, '00882800212', 'Cipolla', '0.60', 'Ortofrutta Gastone', 'Cipolla Bianca', 100, 'g'),
('8076802085707', 0, '01515921201', 'Pasta', '0.79', 'Barilla', 'Mezze Penne Rigate', 500, 'g'),
('8076802085707', 1, '00882800212', 'Pasta', '0.69', 'Barilla', 'Mezze Penne Rigate', 500, 'g'),
('8076802085707', 1, '01515921201', 'Pasta', '0.79', 'Barilla', 'Mezze Penne Rigate', 500, 'g'),
('8076802085707', 2, '00882800212', 'Pasta', '0.69', 'Barilla', 'Mezze Penne Rigate', 500, 'g'),
('8076809513340', 0, '00882800212', 'Sugo pesto', '2.40', 'Barilla', 'Pesto alla genovese', 190, 'g'),
('8076809513340', 1, '00882800212', 'Sugo pesto', '2.00', 'Barilla', 'Pesto alla genovese', 190, 'g'),
('8076809513340', 2, '00882800212', 'Sugo pesto', '1.90', 'Barilla', 'Pesto alla genovese', 190, 'g'),
('8076809513341', 0, '00882800212', 'Funghi', '2.34', 'Giovanni Rana', 'Funghi misti', 180, 'g'),
('8076809513341', 1, '00882800212', 'Funghi', '2.55', 'Giovanni Rana', 'Funghi misti', 180, 'g'),
('8076809513341', 2, '00882800212', 'Funghi', '2.50', 'Giovanni Rana', 'Funghi misti', 180, 'g'),
('8076809540728', 0, '01515921201', 'Pane', '2.01', 'Mulino Bianco', 'Pagnotta di Grano Duro', 350, 'g'),
('8076809540728', 1, '00348980285', 'Pane', '1.98', 'Mulino Bianco', 'Pagnotta di Grano Duro', 350, 'g'),
('8076809540728', 1, '00882800212', 'Pane', '2.01', 'Mulino Bianco', 'Pagnotta di Grano Duro', 350, 'g'),
('8076809540728', 1, '01515921201', 'Pane', '2.01', 'Mulino Bianco', 'Pagnotta di Grano Duro', 350, 'g'),
('8076809540728', 2, '00882800212', 'Pane', '1.98', 'Mulino Bianco', 'Pagnotta di Grano Duro', 350, 'g'),
('8135540422659', 2, '00882800212', 'Rosmarino', '1.50', 'Cannamela', 'Rosmarino liofilizzato', 70, 'g'),
('8135540426759', 1, '00348980285', 'Basilico', '1.50', 'Cannamela', 'Basilico in foglie', 70, 'g'),
('8135540426759', 2, '00882800212', 'Basilico', '1.62', 'Cannamela', 'Basilico in foglie', 70, 'g'),
('8345809513340', 0, '00882800212', 'Scalogno', '2.40', 'Ortofrutta Ferrari', 'Scalogno sfuso', 250, 'g');

--
-- Trigger `ProdottoInVendita`
--
DELIMITER $$
CREATE TRIGGER `inserisci_nuovo_tipo` BEFORE INSERT ON `ProdottoInVendita`
 FOR EACH ROW BEGIN
	IF NOT EXISTS (SELECT * FROM TipoProdotto WHERE Nome=New.TipoProdotto) THEN
		
        INSERT INTO TipoProdotto VALUES (New.TipoProdotto);
        
	END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `Ricetta`
--

CREATE TABLE IF NOT EXISTS `Ricetta` (
  `Nome` varchar(100) COLLATE utf8_unicode_ci NOT NULL,
  `Portata` enum('Primo','Secondo','Spuntino','Dessert','Contorno') COLLATE utf8_unicode_ci NOT NULL,
  `Tempo` time NOT NULL,
  `Difficolta` enum('Bassa','Media','Alta') COLLATE utf8_unicode_ci NOT NULL,
  `Istruzioni` text COLLATE utf8_unicode_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dump dei dati per la tabella `Ricetta`
--

INSERT INTO `Ricetta` (`Nome`, `Portata`, `Tempo`, `Difficolta`, `Istruzioni`) VALUES
('Anatra all''arancia', 'Secondo', '01:30:00', 'Media', 'Per preparare l’anatra all’arancia iniziate a preparare l’anatra: se ne avete acquistata una dal macellaio sarà certamente già pulita altrimenti dovrete prepararla eliminando le interiora e togliendo il grasso ed eventualmente lasciandone un po’ da parte da tritare al coltello per aggiungerlo al fondo di cottura.\r\n\r\nPassate l’anatra sul fornello acceso per bruciare le eventuali piumette ancora presenti, poi sciacquatela bene sotto acqua corrente dentro e fuori e asciugatela perfettamente con un panno da cucina. Quindi procedete salando e pepando l’interno e aggiungendo due foglie di alloro.\r\n\r\nPoi passate a legarla: fate scorrere lo spago all’altezza dello stomaco dell’anatra, prima sotto una zampa, poi sull’anatra e infine sotto l’altra zampa. Prendete le due estremità e tirando bene incrociate lo spago e tiratelo verso l’altra estremità dell’anatra e fatelo passare sotto le spalle, quindi capovolgetela e fate passare lo spago sotto le alette.\r\nQuindi annodate per chiudere tirando bene : questo servirà a tenere bene la forma dell’anatra intera in cottura.\r\n\r\nIn un tegame capiente (adatto anche alla cottura in forno) fate scaldare l’olio e il burro, quindi unite il grasso in eccesso dell’anatra messo da parte e fatelo sciogliere per qualche istante. Unite l’anatra e rosolatela a fuoco medio da una parte e dall’altra; dopodiché sfumate con il Grand Marnier, irrrorate con il fondo di cottura e quando sarà evaporato, coprite con coperchio e ponete l''anatra a cuocere in forno statico preriscaldato a 190° per 40 minuti (se non avete un tegame adatto alla cottura in forno potete rosolare l’anatra in un comune tegame e cuocerla in una pirofila, coperta con carta alluminio).\r\n\r\nDedicatevi al caramello sciogliendo lo zucchero insieme all’acqua a fuoco bassissimo: dovrete raggiungere la temperatura di 166° misurando con un termometro da cucina e a quel punto versare il succo di arancia filtrato; mescolate con una frusta per emulsionare il tutto e aggiungete qualche cucchiaio del fondo di cottura dell’anatra. e l’amido di mais stemperato in poca acqua.\r\nContinuate a lavorare tutto con la frusta quindi spegnete e filtrate la salsa, poi unite le scorze di arancia affettate finemente e tenete da parte. Riprendete l’anatra dal forno spennellatela con la salsa all’arancia, poi adagiate le fettine di arancia e spennellate ancora con la salsa. Rimettete in forno per 15-20 minuti a 180° senza coprirla, fino a quando al cuore dell’anatra non saranno 165-170° da misurare con una sonda per arrosti.\r\n\r\nSe volete avere un effetto più croccante, potete passare 10 minuti l’anatra sotto il grill. Se invece la preferite più umida potete continuare la cottura coperta. Servite l’anatra all’arancia ben calda!e spennellate ancora con la salsa , poi rimettete in forno per 15-20 minuti a 180° senza coprirla, fino a quando al cuore dell’anatra non saranno 165-170° da misurare con un termometro per arrosti.\r\n\r\nUna volta cotta, servite ben caldo questo succulento secondo piatto!'),
('Arrosticini', 'Secondo', '00:30:00', 'Bassa', 'Per preparare gli arrosticini, cominciate prendendo la carne. Aiutandovi con un coltello dalla lama tagliente, eliminate le parti più grasse della carne. Quindi, tagliate la carne in striscioline e quindi a cubetti spessi 1 cm.\r\n\r\nOttenuti i cubetti di carne infilzateli negli spiedini.\r\n\r\nRipetete il procedimento per tutti gli arrosticini.\r\n\r\nOra fate scaldare bene una griglia in ghisa e oleatela leggermente in modo da girare facilmente gli arrosticini in cottura.\r\nQuindi adagiate gli arrosticini sulla griglia rovente.\r\n\r\nLa cottura dovrebbe richiedere all’incirca 1 minuto per lato. Cuocete gli arrosticini in entrambi i lati fino a quando non noterete una leggera crosticina. \r\n\r\nSalate e guarnite il piatto con i vostri arrosticini con del rosmarino.\r\n\r\nI vostri arrosticini sono ora pronti da gustare.'),
('Carbonara al forno', 'Primo', '00:35:00', 'Bassa', 'Per preparare la carbonara al forno mettete sul fuoco una pentola con abbondante acqua che servirà per la pasta.\r\n\r\nNel frattempo mettete la pancetta affumicata tagliata a cubetti in un tegame antiaderente, senza l’aggiunta d’olio.\r\n\r\nCon una spatola mescolate bene la pancetta, facendola rosolare a fuoco medio fino a quando il grasso diventerà trasparente e leggermente croccante; quindi togliete dal fuoco e lasciate intiepidire leggermente.\r\n\r\nIn una ciotola versate le uova, sbattetele, quindi unite il pecorino grattugiato, tenendone da parte un po''; sale e pepe a piacere.\r\n\r\nAggiungete anche la panna e continuate a mescolare con le fruste per qualche minuto amalgamando bene tutti gli ingredienti; infine unite la pancetta, tenendone da parte uno o due cucchiai (verrà aggiunta e gratinata alla fine insieme al pecorino avanzato).\r\n\r\nQuando l’acqua della pasta avrà raggiunto il bollore, salate moderatamente, poiché la pasta avrà già un condimento molto sapido dato dalla pancetta e dal pecorino.\r\n\r\nQuando la pasta sarà al dente, scolatela bene e versatela nella ciotola con il condimento di uova, aiutandovi con uno scola spaghetti o un forchettone.\r\n\r\nCon due forchette amalgamate bene la pasta, dopodiché con un pennello da cucina oliate una pirofila e distribuitevi la pasta in maniera uniforme.\r\n\r\nDa ultimo, cospargete tutta la superficie della pasta con la pancetta e il pecorino grattugiato che avevate tenuto da parte. \r\nMettete in forno e fate cuocere sotto il grill a 270° per 5-7 minuti.\r\n\r\nTrascorso il tempo necessario, spegnete il forno e servite la carbonara al forno ancora calda.'),
('Gnocchi con funghi misti', 'Primo', '00:35:00', 'Media', 'Una volta effettuata la pulizia dei funghi, sbucciate e tritate uno scalogno, quindi versate in una ampia padella l''olio e uno spicchio di aglio intero (lo potrete togliere successivamente).\r\n\r\nFate appassire lo scalogono e dorare lo spicchio d''aglio a fuoco dolce, poi unite il prezzemolo tritato e i funghi; fateli saltare alcuni minuti quindi sfumate con il vino bianco, fatelo evaporare e spegnete il fuoco.\r\n\r\nCuocete gli gnocchi in una pentola capiente con abbondante acqua salata a piacere: ci vorranno pochi istanti, quando gli gnocchi verranno a galla, scolateli con una schiumarola e passateli direttamente nella padella con il condimento. \r\n\r\nSaltateli pochi istanti a fuoco dolce, mescolando per insaporirli e i vostri gnocchi con funghi misti saranno pronti per essere gustati.'),
('Pasta alla papalina', 'Primo', '00:25:00', 'Bassa', 'Per preparare la pasta alla papalina tagliate prima a fette e poi a listarelle il prosciutto crudo.\r\n\r\nPonete sul fuoco una pentola antiaderente e fate sciogliere il burro a tocchetti.\r\n\r\nLasciate appassire la cipolla tritata finemente per 8 minuti nel burro aggiungendo un mestolo di acqua a temperatura ambiente.\r\n\r\nUnite il prosciutto crudo precedentemente tagliato a listarelle e mescolate con una spatola da cucina, facendo cuocere per altri 2 minuti.\r\n\r\nUna volta pronto, spegnete e tenete da parte. \r\n\r\nMettete sul fuoco una pentola con acqua salata e portate a bollore, quindi cuocete la pasta al dente per 3 minuti; nel frattempo rompete le uova in un recipiente e aggiungete la panna, e mescolate energicamente con le fruste.\r\n\r\nUnite il formaggio grattugiato, mischiate nuovamente, infine aggiustate di sale.\r\n\r\nTrascorso il tempo necessario, scolate le pasta e versatela direttamente nella padella con il condimento, facendola saltare per qualche istante per insaporire; spegnete il fuoco e aggiungete il composto a base di uova, distribuendolo in maniera omogenea sulla pasta.\r\n\r\nMischiate velocemente per amalgamare bene tutti gli ingredienti, quindi regolate di pepe: la vostra pasta alla papalina è pronta per essere servita ben calda.'),
('Pasta con pesto alla genovese', 'Primo', '00:35:00', 'Media', 'Per preparare il pesto alla genovese ponete l’aglio sbucciato nel mortaio insieme a qualche grano di sale grosso.\r\n\r\nCominciate a pestare e quando l’aglio sarà ridotto in crema aggiungete il basilico insieme ad un pizzico di sale grosso.\r\n\r\nSchiacciate, quindi, il basilico contro le pareti del mortaio ruotando il pestello da sinistra verso destra e contemporaneamente ruotate il mortaio in senso contrario (da destra verso sinistra) e continuate così fino a quando dalle foglie di basilico non uscirà un liquido verde brillante.\r\n\r\nA questo punto aggiungete i pinoli e ricominciate a pestare per ridurre in crema.\r\n\r\nAggiungete i formaggi un po'' alla volta che andranno a rendere ancora più cremosa la salsa e per ultimo unite l''olio di oliva extravergine che andrà versato a filo, mescolando continuamente con il pestello.\r\n\r\nAmalgamate bene gli ingredienti fino ad ottenere una salsa omogenea e tenete da parte.\r\n\r\nIn un altro tegame fate cuocere in abbondante acqua salata la pasta di vostra scelta, poi mettete in una padella ampia il pesto ottenuto.\r\n\r\nAggiungete la pasta scolata al dente e accendete il fuoco per farla saltare pochi istanti mescolando accuratamente in modo da amalgamare gli ingredienti.');

-- --------------------------------------------------------

--
-- Struttura stand-in per le viste `TipiProdottoMancanti`
--
CREATE TABLE IF NOT EXISTS `TipiProdottoMancanti` (
`TipoProdotto` varchar(50)
,`QuantitaMancante` double
,`QuantitaPer4Pers` float unsigned
);

-- --------------------------------------------------------

--
-- Struttura della tabella `TipoProdotto`
--

CREATE TABLE IF NOT EXISTS `TipoProdotto` (
  `Nome` varchar(50) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dump dei dati per la tabella `TipoProdotto`
--

INSERT INTO `TipoProdotto` (`Nome`) VALUES
('Aglio'),
('Anatra'),
('Arancia'),
('Basilico'),
('Biscotti'),
('Brie'),
('Burro'),
('Capperi'),
('Carne ovina'),
('Carota'),
('Cavolfiore'),
('Cipolla'),
('Cracker'),
('Dolce'),
('Edamer'),
('Erba cipollina'),
('Fagioli'),
('Farina'),
('Fette Biscottate'),
('Filetto vitello'),
('Funghi'),
('Gamberi'),
('Gnocchi'),
('Grana Padano'),
('Groviera'),
('Latte'),
('Limone'),
('Liquore'),
('Maionese'),
('Olio extravergine'),
('Olive nere snocciolate'),
('Pancetta affumicata'),
('Pane'),
('Panna da cucina'),
('Parmigiano Reggiano'),
('Passata di pomodoro'),
('Pasta'),
('Patata'),
('Pecorino'),
('Peperone'),
('Petto di pollo'),
('Philadelphia'),
('Pinoli'),
('Piselli'),
('Polpa di granchio'),
('Pomodoro'),
('Porro'),
('Prezzemolo'),
('Prosciutto crudo'),
('Riso'),
('Rosmarino'),
('Salsa di soia'),
('Salsa Worcestershire'),
('Scalogno'),
('Sedano'),
('Senape'),
('Succo ACE'),
('Sugo funghi'),
('Sugo pesto'),
('Tonno in Scatola'),
('Tortellini'),
('Uova'),
('Vino bianco'),
('Wurstel'),
('Zafferano'),
('Zucca'),
('Zucchina');

-- --------------------------------------------------------

--
-- Struttura della tabella `Utente`
--

CREATE TABLE IF NOT EXISTS `Utente` (
  `Username` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `Password` varchar(20) COLLATE utf8_unicode_ci NOT NULL,
  `Nome` varchar(10) COLLATE utf8_unicode_ci NOT NULL,
  `Cognome` varchar(10) COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

--
-- Dump dei dati per la tabella `Utente`
--

INSERT INTO `Utente` (`Username`, `Password`, `Nome`, `Cognome`) VALUES
('mconti', 'mconti', 'Mauro', 'Conti'),
('rspolaor', 'rspolaor', 'Riccardo', 'Spolaor');

-- --------------------------------------------------------

--
-- Struttura per la vista `ConsigliAcquisti`
--
DROP TABLE IF EXISTS `ConsigliAcquisti`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `ConsigliAcquisti` AS select `M`.`MigliorPrezzo` AS `MigliorPrezzo`,`PV`.`Barcode` AS `Barcode`,`PV`.`Filiale` AS `Filiale`,`PV`.`Negozio` AS `Negozio`,ceiling((`M`.`QuantitaMancante` / `PV`.`CapacitaV`)) AS `ConfezioniDaComprare` from (`MigliorPrezzoPerTipo` `M` join `ProdottoInVendita` `PV` on((`M`.`TipoProdotto` = `PV`.`TipoProdotto`))) where (`M`.`MigliorPrezzo` = `PV`.`Prezzo`) group by `PV`.`Barcode`;

-- --------------------------------------------------------

--
-- Struttura per la vista `MigliorPrezzoPerTipo`
--
DROP TABLE IF EXISTS `MigliorPrezzoPerTipo`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `MigliorPrezzoPerTipo` AS select `T`.`TipoProdotto` AS `TipoProdotto`,min(`PV`.`Prezzo`) AS `MigliorPrezzo`,`T`.`QuantitaMancante` AS `QuantitaMancante`,`PV`.`CapacitaV` AS `CapacitaV` from (`TipiProdottoMancanti` `T` join `ProdottoInVendita` `PV` on((`T`.`TipoProdotto` = `PV`.`TipoProdotto`))) where (`PV`.`Prezzo` / `PV`.`CapacitaV`) in (select min((`PV`.`Prezzo` / `PV`.`CapacitaV`)) from (`TipiProdottoMancanti` `T` join `ProdottoInVendita` `PV` on((`T`.`TipoProdotto` = `PV`.`TipoProdotto`))) group by `T`.`TipoProdotto`) group by `T`.`TipoProdotto`;

-- --------------------------------------------------------

--
-- Struttura per la vista `ProdottiConsumati`
--
DROP TABLE IF EXISTS `ProdottiConsumati`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `ProdottiConsumati` AS select `PD`.`Barcode` AS `Barcode`,`PD`.`Utente` AS `Utente`,`PD`.`DataScadenza` AS `DataScadenza`,`PD`.`TipoProdotto` AS `TipoProdotto`,`PD`.`Marca` AS `Marca`,`PD`.`Nome` AS `Nome`,`PD`.`QuantitaV` AS `QuantitaDispensa`,((`I`.`QuantitaV` / 4) * 9) AS `QuantitaNecessaria`,(`PD`.`QuantitaV` - ((`I`.`QuantitaV` / 4) * 9)) AS `QuantitaRimasta` from (`ProdottoInDispensa` `PD` join `Ingrediente` `I` on((`PD`.`TipoProdotto` = `I`.`TipoProdotto`))) where ((`PD`.`Utente` = 'mconti') and (`I`.`NomeRicetta` = 'Carbonara al forno') and `PD`.`DataScadenza` in (select min(`PD`.`DataScadenza`) from (`ProdottoInDispensa` `PD` join `Ingrediente` `I` on((`PD`.`TipoProdotto` = `I`.`TipoProdotto`))) where ((`PD`.`Utente` = 'mconti') and (`I`.`NomeRicetta` = 'Carbonara al forno')) group by `PD`.`TipoProdotto`)) order by `PD`.`TipoProdotto`,`PD`.`DataScadenza`;

-- --------------------------------------------------------

--
-- Struttura per la vista `TipiProdottoMancanti`
--
DROP TABLE IF EXISTS `TipiProdottoMancanti`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `TipiProdottoMancanti` AS select `Ingrediente`.`TipoProdotto` AS `TipoProdotto`,((`Ingrediente`.`QuantitaV` / 4) * 1) AS `QuantitaMancante`,`Ingrediente`.`QuantitaV` AS `QuantitaPer4Pers` from `Ingrediente` where ((`Ingrediente`.`NomeRicetta` = 'Pasta con pesto alla genovese') and (not(`Ingrediente`.`TipoProdotto` in (select `ProdottoInDispensa`.`TipoProdotto` from `ProdottoInDispensa` where (`ProdottoInDispensa`.`Utente` = 'mconti'))))) union select `PD`.`TipoProdotto` AS `TipoProdotto`,(((`I`.`QuantitaV` / 4) * 1) - sum(`PD`.`QuantitaV`)) AS `QuantitaMancante`,`I`.`QuantitaV` AS `QuantitaPer4Pers` from (`Ingrediente` `I` join `ProdottoInDispensa` `PD` on((`I`.`TipoProdotto` = `PD`.`TipoProdotto`))) where ((`I`.`NomeRicetta` = 'Pasta con pesto alla genovese') and (`PD`.`Utente` = 'mconti')) group by `PD`.`TipoProdotto` having (sum(`PD`.`QuantitaV`) < ((`I`.`QuantitaV` / 4) * 1));

--
-- Indici per le tabelle scaricate
--

--
-- Indici per le tabelle `Filiale`
--
ALTER TABLE `Filiale`
  ADD PRIMARY KEY (`Codice`,`Negozio`),
  ADD KEY `Negozio` (`Negozio`);

--
-- Indici per le tabelle `Ingrediente`
--
ALTER TABLE `Ingrediente`
  ADD PRIMARY KEY (`TipoProdotto`,`NomeRicetta`),
  ADD KEY `NomeRicetta` (`NomeRicetta`);

--
-- Indici per le tabelle `ListaSpesa`
--
ALTER TABLE `ListaSpesa`
  ADD PRIMARY KEY (`Utente`,`Prodotto`,`Filiale`,`Negozio`),
  ADD KEY `Prodotto` (`Prodotto`,`Filiale`,`Negozio`);

--
-- Indici per le tabelle `Negozio`
--
ALTER TABLE `Negozio`
  ADD PRIMARY KEY (`P_IVA`);

--
-- Indici per le tabelle `ProdottoInDispensa`
--
ALTER TABLE `ProdottoInDispensa`
  ADD PRIMARY KEY (`Barcode`,`Utente`,`DataScadenza`),
  ADD KEY `Utente` (`Utente`);

--
-- Indici per le tabelle `ProdottoInVendita`
--
ALTER TABLE `ProdottoInVendita`
  ADD PRIMARY KEY (`Barcode`,`Filiale`,`Negozio`),
  ADD KEY `Filiale` (`Filiale`),
  ADD KEY `Negozio` (`Negozio`),
  ADD KEY `TipoProdotto` (`TipoProdotto`);

--
-- Indici per le tabelle `Ricetta`
--
ALTER TABLE `Ricetta`
  ADD PRIMARY KEY (`Nome`);

--
-- Indici per le tabelle `TipoProdotto`
--
ALTER TABLE `TipoProdotto`
  ADD PRIMARY KEY (`Nome`);

--
-- Indici per le tabelle `Utente`
--
ALTER TABLE `Utente`
  ADD PRIMARY KEY (`Username`);

--
-- Limiti per le tabelle scaricate
--

--
-- Limiti per la tabella `Filiale`
--
ALTER TABLE `Filiale`
  ADD CONSTRAINT `Filiale_ibfk_1` FOREIGN KEY (`Negozio`) REFERENCES `Negozio` (`P_IVA`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `Ingrediente`
--
ALTER TABLE `Ingrediente`
  ADD CONSTRAINT `Ingrediente_ibfk_1` FOREIGN KEY (`NomeRicetta`) REFERENCES `Ricetta` (`Nome`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `Ingrediente_ibfk_2` FOREIGN KEY (`TipoProdotto`) REFERENCES `TipoProdotto` (`Nome`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `ListaSpesa`
--
ALTER TABLE `ListaSpesa`
  ADD CONSTRAINT `ListaSpesa_ibfk_1` FOREIGN KEY (`Utente`) REFERENCES `Utente` (`Username`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ListaSpesa_ibfk_2` FOREIGN KEY (`Prodotto`, `Filiale`, `Negozio`) REFERENCES `ProdottoInVendita` (`Barcode`, `Filiale`, `Negozio`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `ProdottoInDispensa`
--
ALTER TABLE `ProdottoInDispensa`
  ADD CONSTRAINT `ProdottoInDispensa_ibfk_1` FOREIGN KEY (`Utente`) REFERENCES `Utente` (`Username`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `ProdottoInVendita`
--
ALTER TABLE `ProdottoInVendita`
  ADD CONSTRAINT `ProdottoInVendita_ibfk_1` FOREIGN KEY (`Filiale`) REFERENCES `Filiale` (`Codice`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ProdottoInVendita_ibfk_2` FOREIGN KEY (`Negozio`) REFERENCES `Negozio` (`P_IVA`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `ProdottoInVendita_ibfk_3` FOREIGN KEY (`TipoProdotto`) REFERENCES `TipoProdotto` (`Nome`) ON DELETE CASCADE ON UPDATE CASCADE;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
