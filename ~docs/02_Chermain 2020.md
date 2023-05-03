
# Procedural Physically based BRDF for Real-Time Rendering of Glints

## poznamky k ~11 stranovemu papieru 

### strana 1
#### abstrakt
navrhujú fyzikálne založenú BRDF na vykreslovanie trblietok v reálnom čase. Procedurálne vypočítavajú mnohé NDF so stovkami ostrých lalokov(lobe).
používajú normalizované NDF(normalizovane distribuovane funkcie), ich BRDF konverguje do standardnej cookTorrance BRDF ak máme veľa mikroplôšok. Používajú slovník 1D marginálnych/okrajových distribúcii-na každej pozícii sú zvolené 2 dist. zo slovníka a vynásobené(získame NDF), otočené(väčšia rozmanitosť) a naškálované(podľa parametra, rougness)
#### 1. uvod

### strana 2

ich BRDF vedia reprodukovať materiály ako trblietavé-vločky,drsný kov a plast.
používateľ vie ovplyvniť drsnosť-roughness povrchu

keď je počet mikrofacetov vysoký, konvergure k štandardnej BRDF

Používajú P-NDF teda NDF definovanú pre patch/ P na povrchu. Patch P reprezentuje stopu obrazového pixelu na povrchu objektu. 
Ich P-NDF je modelovaná váhovanou sumou vysokofrekvenčných NDF definovaných pre každú bunku priestorovo neohrančenej (spatially unbounded) MIP hierarchie.
Na leveli 0 majú málo lalokov, ktoré reprezentujú málo dikrétnych mikroplôšok. Čím vyšší LOD level, tým viac lalokov. Najvyšší  LOD level je totožný NDF- Beckannovej distribúcii- získaná zoskuponím všetkých lalokov z nižších levelov.

NDF sú generované on the fly výberom 2 náhodných marginálnych distrbúcii.

#### 2 Previous works
Nepodstatné

### strana 3

#### 3 Overview- ich práce
Hlavným cieľom tejto metódy je efektívne vykresliť priestorovo husté, vysokofrekvenčné NDFs.
Ich  metóda používa kompaktnú vyoskofrekvenčnú NDF metódu ktorá vie reprezentovať niekoľko tuctov lalokov.

Všetky ich NDF sú definované pomocou SDFs- Slope Distributions functions. tak ako je to bežné v Beckamann alebo GGX.

Ich model:

1. a- Počas vykresľovania filtrujeú procedurálnu MIP hierarchiu. Procedurálne znamená, že každá bunka hierarchie explicitne neukladá SDF.
2. b- Každá bunka (index) vytvára seed pre pseudonáhodný generátor, ktorý náhodne vyberie dve 1D okrajové distribúcie zo slovníka.
3. c-Súčin dvoch 1D okrajových distribúcií vytvára 2D SDF. Náhodnosť sa vyhýba artefaktom opakovana a zdanlivej periodicite. Okrem toho výrazne znižujú pamäťovú stopu v porovnaní s explicitným ukladaním SDF v bunkách hierarchie.
4. d- Na ďalšie zvýšenie rozmanitosti SDF, stále s použitím malého slovníka, sa na každý SDF aplikuje náhodné otáčanie. Pomáha to aj proti artefaktom zarovnania.
5. e- Škálovanie sa použije aby zodpovedala používateľom definovanej anizotropnej drsnosti.
6.  f- Vážená suma nad bunkami pokrytými stopou vytvára P-SDFs definované na diskrétnej LOD úrovni.
7. g- Interpolácia naprieč LOD úrovňami vedie k finálnej multiškálovej P-SDF. Výsledok je spojený s BRDF na vypočítajte lokálneho tieňovania.





#### 4 describe multiscale high-frequency SDF
Okrem dsitribúcie orientácii, Normal dist.funct. NDF, poznáme aj distribúciu naklonení- slope dsitribution function SDF , P^22 (m~(microslope)).
Obe sú súvisiace.

Aby boli fyzikálne správne musia byť normalizované.

2D SDF je produktom dvoch 1D marginálnych disribúcii viď Fig 4., stačí ukladať pozitívnu časť funkcie.

### 4.2 single scale SDF
ich (matematické vyjadrenie)P na 22  je nezávislá spoločná funkcia hustoty a pravdepodobnosti, ktorá je súčinom dvoch jednorozmerných okrajových distribúcii P (2)− a P (−2) pozdĺž osi x a y (Eq 5.)

P na 22 je normalizovaná ak sú obe 1D okrajové distribúcie normalizované
aby nebol priemer mikronormál odlišný od geometrickej normály(tej reálnej omega g) používajú even, marginal density functions - znižuje to aj nároky na pamäť.

### 4.3 multiscale SDF

Do eq. 5 pridali level l LOD. eq 6 je 2D multiscale SDF. 0- najlepšie,najjemnejšie/finest, nLevels-coarsest-najhrubšie
Experimentom prišli na to, že max l(nLevels) je 16.

Finest LOD: potrebujeme málo mikroplôšok a tedad málo tenučkých lalokov. Kvôli eq 5+ even marginal dist. minimum je 4 laloky.
Coarsest LOD: Posledný level sa má správať ako beckmannova distribúcia, čiže najväčši level je počítaný P_target na 22 ( m~).
Becmann má oddeliteľné gaussiány, s napr. GGX to nevieme spraviť.

### 4.4 generovanie single multiscale SDF

gaussianske laloky s malou smerdajnou odchýlkou lalokov (0.02). Pozície-means lalokov sú získané importance samplingom P_target. Viď fig.5

### 4.5 Slovník okrajových distribúcii

aby sme správne vykreslili trblietky, potrebujeme priestorovú variáciu  na povrchu, teda potrebujeme veľa rôznych SDF.
Dosiahnú to tak, že vytvoria slovník N okrajových distribúcii P_i. Sú generované náhodne. Slovník môže mať akúkoľvek veľkosť, s vačším N máme viac rozmanitejšie výsledky ale potrebujeme viac pamäte.

Aby sa dala upravovať drsnosť a anizotropia p\*na 22 musia to robiť nezávisle v x a y. Nechceli ale mať 2 slovníky jeden pre každý smer a jeden pre drsnosť(teda tiež 2 smere x a y?? ) (dokopy 4 slovníky) 
Namiesto toho zostali pri jednom slovníku a praimo pri vykresľovaní ho otočia a naškálujú- vid sekcia 5

#### 5 Spatially-varying and multiscale SDF
alebo, generation of spatial variations as well as the procedural MIP hierarchy

aby priestorovo odlíšili rôzne SDF, rozdelia povrch na švorcové bunky a každá bunka má SDF.  na LODs používajú MIP hierarchiu, na leveli l+1 to znamená 4 susedné bunky na leveli l. fig 3-a

Eq 7.  spatially-varying and multiscale SDF

musia si dať pozor na súdržnosť medzi levelmi a súradnicami bunky. Presné riešenie, predpočítať všetky možnodti, komibinatoricky problém s väčšími l. 
Použili aproximáciu ako aj Ziirr+Kaplanyan: SDF na leveli l+1 získa laloky iba jedného SDF na leveli l. Počet lalokov sa štvornásobí len pre zväčšenie levelu v slovníku, nie zlúčením 4 SDF. 

### 5.1 Koherentné/súdržné indexovanie
index bunky musíme vypočítať  opatrne

### 5.2 Vylepšenie rozmanitosti rotáciou SDF

Vyhneme sa nepekným artefaktom ako napr. zjanvné usporiadania. 
Sám o sebe vie slovník s N okrajovými distribúciami vygenerovať N\*N SDF. môžeme to vylepšiť pridaním náhodnej rotácie  vygenerovabej z bunkového indexu s0  v rozmedzi (0-2xPI)
SDF musíme pri evaluácii použiť inverznú rotáciu sklonu. Eq. 9 

### 5.3 kontrola drsnosti cez škálovanie SDF
Umožníme nastavovanie a_x a a_y. Lineárne transformujeme  parameter sklon/slope.  Celé je to zhrnuté v Eq 11.

#### 6 Reflectance model
alebo derive the P-SDF and the BRDF model

### 6.1. Patch-SDF based on a MIP hierarchy
Keď použijú MIP hierarchiu spolu so škálovanou, orientovanou, priestorovo  líšíacu sa a multiškálovú SDF tak 
P-SDF je výsledok filterovania  MIP hierarchie eq 12.


### 6.2. Multiscale microfacet based BRDF

Takmer štandardná Cook-Torrance s novou NDF(D_P(omega)) a zmenenou shadow-masking funkciou-G-geometry

Nemôžu použiť Smith masking-shadowing funkciu. Použili V-cavity masking shadowing funkciu, tá nepotrebuje tvar P-NDF.

#### 7 výsledky 

Nastaviteľné parametre:
Možnosť zmeniť drsnosť a_x a_y - veľkosť plochy na povrchu kde sú takmer všetky mikroplôšky 
hustotu mikroplôšok Ró - počet spekulárnych mikroplôšok na jednotkovú plochu, malé Ró je trbletkavejšie a veľké je hladšie
relatívnu plochu mikroplôšok Beta - Percento povrchu ktorú pokrýva trblietkavá BRDF   1 je drsný plast/kov a  malá Beta je napr. kameň s trblietkavým materiálom. Správa sa ako maska na povrchu a nie je závislá od parametra Ró.  

7.5
na RTX 2080, forward rendering,1080p :
Sponza scéna: 3ms vs C-Torrance 0.7ms
citroen 2CV 9.2 vs 2.0

náročnosť vykresľovania stúpa s obrazovou plochou kotrú zaberajú trblietky a teda aj hodnotami Beta a alfa(tie zväčšujú plochu trblietok na ktorej sa nachádzajú). 