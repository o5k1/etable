# Progetto eTable
## Collaboratori
Andrea Tombolato, Tommaso Zagni.

## Abstract
La metà del cibo che viene prodotto nel mondo, circa due miliardi di tonnellate, finisce nella spazzatura benché sia in gran parte commestibile.
Fra le cause di questo spreco di massa vi sono le cattive abitudini di milioni di persone, che non conservano i prodotti in modo adeguato.
La piattaforma eTable nasce con lo scopo di arginare il problema tramite la gestione intelligente della
dispensa personale di ogni utente.
La dispensa di un utente è composta da prodotti alimentari aventi una certa scadenza **all’approssimarsi della quale sarà compito di eTable suggerire all’utente una lista di ricette adeguate per consumare i suddetti prodotti**.
Può accadere che l’utente scelga una ricetta che utilizza anche prodotti non presenti nella sua dispensa o presenti in quantità non sufficienti, in tal caso **sarà cura della piattaforma compilare una lista della spesa contenente i prodotti mancanti** indicando, per ogni prodotto, 
l' esercizio commerciale più conveniente dove effettuare l’acquisto sulla base del prezzo applicato al prodotto d'interesse.

## Descrizione requisiti
Si vogliono realizzare un database e la relativa interfaccia web per la gestione intelligente della dispensa alimentare di un utente.
Un **tipo prodotto** è un concetto astratto che identifica una famiglia di prodotti simili.
* e.g. Una confezione di Vermicelli Pasta Zara venduta nella filiale Alì-Alìper di Piazza Metelli 6 (Padova) e una confezione di Penne rigate Barilla venduta nella filiale Coop di Via San Marco 11 (Limena) hanno entrambe tipo prodotto “Pasta”.

Un **prodotto** è caratterizzato da un nome, da un prezzo di vendita al dettaglio e dalla quantità con cui si presenta, è identificato univocamente dal barcode apposto sulla confezione e dalla filiale del negozio presso cui è venduto.
Bisogna prestare attenzione al fatto che il barcode identifica un prodotto, non un esemplare di prodotto nella sua singolarità.
* e.g. il barcode 8002230000302 identifica una qualsiasi bottiglia di aperitivo Aperol da 70 cl, non una specifica bottiglia di Aperol presente in un determinato scaffale di un dato esercizio commerciale.

Ogni **negozio** è identificato dalla propria partita IVA e possiede un nome commerciale, ha inoltre almeno una filiale identificata dal proprio codice e dal negozio di cui è filiale.
Ogni **filiale** ha un indirizzo per consentirne la localizzazione.
* e.g. La partiva IVA 01515921201 identifica il negozio denominato “Coop” che ha una filiale a Limena in Via F.lli Cervi 3 con codice 0.

Si suppone che due filiali dello stesso negozio non possano avere sede nella stessa via della stessa città.
Si può pensare ad un negozio con filiali come ad una catena di negozi, mentre un negozio con un’unica
filiale è qualcosa di più artigianale, come una bottega.
Filiali aventi stesso indirizzo e città sono da considerarsi come ospitate all’interno di ipermercati o strutture simili .

Ogni **utente** è identificato dal proprio username, utilizzato assieme alla password per accedere alla
piattaforma web eTable. L’utente è inoltre caratterizzato dal proprio nome e cognome.
Ciascun utente può possedere dei prodotti alimentari **in dispensa**, ognuno presente con una certa quantità ed identificato univocamente dal tipo di prodotto del quale è istanza, dall’utente che lo possiede e dalla data di scadenza.
Tramite l’interfaccia web l’utente rimane aggiornato sui propri prodotti e riceve consigli sulle ricette da
utilizzare per consumare quelli in scadenza, un prodotto è considerato “in scadenza” se scade entro due settimane dal momento in cui si controlla.
* e.g. Se la data odierna è 01-08-2015, tutti i prodotti con data di scadenza compresa tra 01-08-2015 e 15-08-2015 sono considerati “in scadenza”.

Una **ricetta** è identificata dal proprio nome ed è composta da ingredienti che sono tutti prodotti, per ogni ricetta vengono inoltre forniti i passi da seguire, una difficoltà ed un tempo indicativi per la sua preparazione.
Può accadere che un prodotto non sia ingrediente di alcuna ricetta, in tal caso verrà solo notificato all’utente l’approssimarsi della scadenza.
I piatti che è possibile preparare utilizzando le varie ricette sono divisi per **portate**: primo, secondo, contorno, dessert, spuntino.
Questa suddivisione permette di fornire all’utente una discreta scelta sulla modalità con cui consumare i prodotti che possono essere ingredienti di vari piatti.
Se l’utente decide di usare una ricetta che adopera anche ingredienti non presenti nella sua dispensa verrà aggiornata la lista della spesa, aggiungendo tali prodotti mancanti.
Ogni prodotto nella lista della spesa è identificato dall’utente a cui è collegato, dal barcode del prodotto e dalle informazioni per raggiungere la filiale del negozio associato che propone il prezzo più conveniente.
Sarà cura di eTable stimare, per ogni prodotto nella lista della spesa, la quantità che è necessario comprare in base alla ricetta scelta e alla disponibilità in dispensa.
* e.g. Per preparare la ricetta “Carbonara al forno” per quattro persone sono necessari 350 g di pasta, la pasta conosciuta più conveniente è “Vermicelli Pasta Zara” venduta in confezioni da 500 g, l’utente non possiede alcun tipo di pasta in dispensa. In questo caso sarà sufficiente comprare un solo pacco di “Vermicelli Pasta Zara” per poter preparare la ricetta.

## Interfaccia web
HTML e CSS sono relativi ad un template messo a disposizione in forma gratuita sul web, al quale son state apportate modifiche basilari per soddisfare le esigenze del progetto.

## L'idea
L'idea nasce come pretesto per portare a termine il progetto richiesto dall'insegnamento *Basi di dati* proposto all'interno del CdL in Informatica dell'*Università degli studi di Padova*. Gli sviluppi di base sono comunque ampliabili e possono avere spazio di evoluzione, spero quindi di avere tempo e modo di portare avanti questo progetto.
