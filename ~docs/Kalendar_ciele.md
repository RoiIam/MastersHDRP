# Ciele

- Zoznámenie sa s prostredím Unity3D HDRP, HLSL – Lit shader, modifikácie pipeline,AxF -hotovo

- Implementácia existujúceho riešenia v HDRP –Chermain20 -hotovo

- Prečítanie najzaujímavejších článkov -hotovo

- Otestovanie nejakej offline metódy -tbd

- Implementácia vlastnej metódy -vo fáze návrhu

Priamo vkladať individuálne trblietky, do scény, tak že máme nejaký zaseedovany procedurálny noise grid. Problémy môžu byť stabilita-aby boli na mieste a neflickerovali- rušivé artefakty pri pohybe kamery, počet a rozloženie trblietok môže byť problém 

- Prečítať viac o vrstvení materiálov Weidlich&Wilkie, Oskar Elek
	- ako nám to vie pomôcť

- Porovnanie zhrnutých, zvolených metód
	- offline, vlastná, chermain/zirr
	- ako to porovnáme? tažko ak bude každé vo vlastnom frameworku, a offline metódu dávať do unity bude asi dosť ťažké



# Kalendár

vždy je postup (od predchádzajúceho stretnutia) spísaný v deň prezentácie priebežnej práce na YACGS 


## WS 23

### 19.9.2023 
Zmena stránky.
Objavenie a začatie čítania Deliot. Belcour. Real-Time Rendering of Glinty Appearances using Distributed Binomial Laws on Anisotropic Grids.
### 3.10.2023 

Prezentácia článku Deliot. Belcour. Real-Time Rendering of Glinty Appearances using Distributed Binomial Laws on Anisotropic Grids.

### 17.10.2023 
Implementácia metódy od Deliot a Belcour.
Prečítanie metódy Wang, Bowles. 
### 31.10.2023 
Implementácia metódy od Zirr et al.
Začiatok písania kapitoly úvod.
### 21.11.2023

Návrh vlastnej metódy ako vylepšenie Zirr pomocou návrhov Deliot.
Písanie kapitol úvod, súčasný stav.
### 5.12.2023 
Dokončenie kapitoly úvod.
Úprava zadania, tak aby lepšie reflektovalo náš cieľ.
### 12.12.2023
Prezentácia pokroku.




## SS23
### 28.02.2023
- prečítaná polovica článku recent advances in glinty appareance rendering 2022,
- študovanie problému- aj cez prednášky ACG1,2 lepšie pochopenie problému, BRDF- laloky a pod

### 15.3.2023 
- dočítaný článok recent advances 22
-  vytvorenie projektu a git repozitára,
- tvorba latex dokumentu podľa šablóny- úvodné stránky a kostra

### 28.03.2023
- prvé zoznámenie sa s HDRP, ako funguje-high level, čítanie  dokumentácie, ešte nie tak detailne kód
- Lit a Stacklit, AxF shadery
- customPass, injectionPoints
- prehľadávanie webu a dokumentácie , *MeasuredMaterialLibraryHDRP* moc nepomohol má jednoduchý carPaint shaderGraph

### 18.04.2023
- prečítaný článok chermain2020 Procedural glinty appareance rendering
- vyskúšaná ich OpenGL implementácia
- študovanie HDRP, viac v kóde hlsl, ako sa dá modifikovať

### 02.05.2023
- implementovanie chermain20 metódy v HDRP, bolo to trochu náročné, chýba najmä poriadna dokumentácia HDRP, 
- poznámky k tejto ceste v 02 Unity.md 

### 09.05.2023
- prerobené usporiadanie projektu, je to prehľadnejšie, bez zbytočných assetov, 
- návrat k CustomLit.shader(teda nemeníme už všetko v HDRP lokálne iba to čo potrebujeme v CustomLit.shader) 
- zjednotenie poznámok


## Zostávajúce, plánované úlohy:

Implementácia vlastného riešenia: prázdniny, nasledujúce 3 mesiace
Otestovanie offline metódy, napr. v Mitsuba 3 rendereri
prečítať viac o viac-vrstvových metódach a či to nájde využitie v trblietkach

