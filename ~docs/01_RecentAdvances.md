## poznamky k ~18 stranovej survey o Recent advances in glinty appearance rendering

### strana 1
#### abstrakt
ponukaju zhrnutie ku glinty apearance rendering techniques, zacneme definiciou(zalozene na teorii mikrofacetov) potom sumarizouju vedecke clanky v ramci reprezentacie a vyzoru, analyza na ich unified platforme(offline only), limitacie a smery do buducnosti
#### 1. uvod
objekty v realnom zivote casto maju trblietkave efekty, ako napr. lak auta pod slnkom, a drobné škrabance na príbore. Su komplexne a nemaju jasnu strukturu. Ked su ignorovane v renderovani tak dostavame prilis hladke povrchy kde tieto efekty chybaju. Su ale narocne na replikaciu v CGI. Tieto geometricke detaily maju s vysokou frekvenciou variabilny vzhlad ... high-frequency variations in appearance.
Musime teda zacat zo zdroja tychto trblietkavych glinty efektov. Komplexna mikrogeometria a ich interakcia so svelom.

Z toho nam vyjdu 2 problemy: 
1. reprezentacia
		a. exhaustively(without overly simplifying or ignoring any geomety),
		b. compactly(without significant storage/memory consumption)
2. efektivne vyobrazenie-render efektivne a verne 

historicky sa pouzivaju mikrofacetové modely ,specificky  BRDF funkcie

Microfacet theory assumes that a surface is composed of many microfacets. Each
microfacet causes a perfect mirror-like reflection. Traditional methods prefilter glinty appearance and smoothly approximate BRDFs, which results in a
smooth appearance which omits glinty effects. *It is the distribution of the orientations (normals) of the microfacets that determine appearance.*
However, microfacet theory uses a statistical approach (e.g., using 2D Gaussians) to describe the microfacets’ *normal distribution function (NDF)*. 

Since statistical functions are usually smooth and only focus on overall distributions rather than details, they inevitably produce smooth appearances lacking glinty reflections.

### strana 2
Recently, various research has been devoted to extending microfacet theory, especially using actual NDFs, to produce glinty details on surfaces. We call this line of research glinty appearance rendering.
key problems, which we focus on in this survey, are the *representation* and *rendering* of the complex microgeometry.

Most related works concern offline methods.

#### 2 Background and overview
### 2.1 statistical appareance models
mikrofacet - drobné plôšky, tvárnice,fazety
Pri fyzikálne založenom vykresľovaní , BRDF,
sa široko používa na modelovanie povrchov s mnohými malými plôškami, ktoré odrážajú lúče ako dokonalé zrkadlá
Rozloženie normál mikroplôšok je vo všeobecnosti
definované normálnou distribučnou funkciou (NDF)
Pomocou NDF môžeme určiť, koľko
mikrotvárnic odráža svetlo zo smeru dopadu ωi
do smeru vychádzajúceho ωo, alebo koľko mikrotvárnic
normály smerujú presne pozdĺž smeru polovičného vektora
h medzi smermi kamery a svetla.
Cook torrance brdf
tam je D  NDF term. 
Termín NDF je dominantným faktorom pri vykresľovaní lesklého vzhľadu.
Tradičné metódy fungujú tak, že štatisticky modelujú súhrnné správanie súboru mikro tvárnic pomocou hladkej NDF. Táto NDF má tendenciu eliminovať odlesky a výsledkom je hladký vzhľad.

### strana 3
...
### 2.2 glinty appareance, trblietkavy vzhlad


Mnohé povrchy v skutočnosti majú bohaté vysokofrekvenčné premenlivé odrazy pod intenzívnymi zdrojmi svetla.
Náhodné, drobné plôšky na povrchoch s veľkosťou od
niekoľko až stoviek mikrometrov, môžu vytvárať lesklý
vzhľad.

Prvý prístup je path tracing. Problém je že nevedia efektívne spracovať taký vzľad.
Hlavným problémom je, že dokonalé zrkadlové  správanie jednotlivých plôšok bráni tomu, aby sme odoberali vzorky(sampling)  správnych plôšok
a nájsť platné svetelné cesty. Pretože pomedzi tisíckami drobých plôšok, iba pár desiatok môže prispievať do daného pixelového odrazu. Aby nebol obraz zašumený, musíme ich nájsť všetky. To je veľmi náročné a zdĺhavé.

strana 4

###  2.3 solutions, overview
To solve the glinty appearance rendering problem...
Základnou myšlienkou je spracovať videnú časť povrchu (surface patch)  cez jeden pixel obrazovky naraz.(teda pixel zaberá časť povrchu, to je ten patch)
Na to sú buď pre-filter stratégie(aproximácia, lower fidelity), ktoré zvyčajne redukujú variácia a produkujú dosť hladké povrchy. 
Druhý spôsob je zobrať daný povrch ako vstup a vypočítať jeho NDF presne.

### 2.3 Pre-filtering methods
Bruneton and Neyret \[12] present a thorough overview of such pre-filtering methods.

One pre-filtering strategy is to store a large number
of pre-computed or measured reflectances for different
viewing and lighting directions, and organize them
according to P covering a coarse mesh.
Napr v 6D tabuľke,  bidirectional texture function, BTF.
Suykens et al. \[14]
create a BTF for Monte-Carlo simulation on a
geometric surface model.
Ma et al.
\[15] enable
interactive BTF rendering by compressing the BTF
into a manageable representation.


Assuming that surface colors, NDF, visibility, and
shadow-masking are uncorrelated, another strategy
pre-filters these properties separately
The simplest approach is to pre-filter the NDF
as a single lobe in P. Napr Neyret modeluje NDF elipsoidnou funciou.

Olano and Baker \[10] model the NDF with a Gaussian-lobe defined by its mean normal and a covariance matrix. (supports anisotropic highlights efficiently)
Heitz et al. \[17] introduce the SGGX function to represent the spatially varying properties of anisotropic microflakes.
However, these methods cannot deal with surfaces
that have structured microfacets or ones organized
into a pattern.

podme na zlozitejsie
Multiple lobe pre-filtering methods provide the
ability to fit a more complex NDF. 

Fournier \[18] represents the NDF with a sum of Blinn-Phong lobes \[19].  (supports up to 7 lobes and 28 parameters in his implementations.)

Tan et al. \[20, 21] extend the approach by using a mixture of isotropic Gaussian lobes to represent the average NDF

Han et al. \[11] use a convolution method to
model the macroscopic NDF with its decomposition
into spherical harmonics and VMFs.

Wu et al. \[22] define characteristic point maps and present a principal component analysis method to find principal lobes based on their data structure. + \[23]
koniec overview of prefiltering methods
rozdelenie na representation a rendering.
reprezentacia určuje sposob evaluacie NDF, co ma efekt na vykon a ulozisko 

evaulacia/vyhodnocovanie = rendering? 

V časti 3 sa zaoberáme existujúcimi metódami reprezentácie a porovnávame ich z hľadiska uvedených faktorov.
V praxi je spôsob vykresľovania trblietkavého vzhľadu
ďalšou výzvou.

V časti 4 rozoberáme rôzne vyhodnocovacie techniky vrátane akceleračných štruktúr. Diskutujeme aj o  importance sampling a multiple scattering, ktoré majú veľký vplyv na na konečné výsledky.


#### 3 Microstructure representation

Typické vysokofrekvenčné materiály, ako sú hrče(bump), vločky(flake),
škrabance, štruktúra kože, jamky atď., obsahujú rôzne
mikroštruktúry. Reprezentácia takýchto prvkov nie je
jednoduchá úloha. Po prvé, odlesky sú malé a komplexné a reprezentácia všetkých detailov by si vyžadovala mimoriadne veľké množstvo pamäte.

Ďalší problém je, že potrebujeme metódy plošnej integrácie, aby sme presne vyhodnotiť P-NDF každej plochy a reprezentácia musí efektívne podporovať vyhodnocovanie(rendering).

Budeme hovoriť o explicit aimplicit reprezentáciach.

### 3.1 explicit representation

Explicitné reprezentácie ukladajú pôvodné mikro štruktúry povrchu v rôznych formách. Naivnou formou je normálová mapa.
Ukladáme normály a nie geomeriu. Dostatočne veľká normálová mapa umožňuje tvorbu takýchto drobných detailov.
Bohužiaľ, normálové mapy  sa ťažko evaluujú na povrchu P? napr cez importance sampling 

aby sa dalo použiť metódu plošnej integrácie pre evaluáciu PDF, existujúce  metódy  predstavujú mikroštruktúru ako kusové prvky E, napríklad diskrétne trojuholníky, Gaussove laloky alebo sférické histogramy. (represent microstructure
as piece-wise elements E such as discrete triangles, Gaussian lobes, or spherical histograms. ) 
každá forma má nejaké nevýhody.

Yan et al. \[3] discretize the high-resolution position–normal distribution as a large number of triangles. Each triangle contains position and normal information.
They then evaluate the P-NDF by accumulating the contributions of triangles located in P (see Fig. 7). This representation is very accurate. 
However, since integration must be performed for
each triangle element, evaluation is quite expensive.

To simplify evaluation, Yan et al. \[1] define 4D Gaussian elements to describe the distribution of normals in one tiny area.
The method requires a large amount of memory ale je rýchlejšia ako integrácia trojuholníkov.
... \[25-27] mnoho prác využiva podobné prvky  na reprezentáciu mikroštruktúry.

Gamboa et al. \[28] use a spherical histogram to represent microstructure. (tiež potrebuje veľa pamäte), dá sa to zlepšiť napr SAT( summed
area table for arbitrary range) alebo Atanasov et al. \[29]
further introduce inverse bin maps (IBMs) which use
constant memory (36 MB) to store the inverses of
histograms.

problem je ze we usually need extremely high-resolution normal maps.
keby sme sa ich pokusili generovat on the fly, tak teoreticky usetrime ulozisko. 

The inverse Fourier transform method \[30] can
generate tileable noise-like bumps. Texture synthesis
methods can also turn normal maps into tileable
patches, stitch patches, and obtain high-resolution
representations. Texture synthesis methods can be
categorized into three different kinds:
expansion \[31, 32], blending \[33], and tiling \[34, 35].
tiling sa pouiziva pre implicitne
(even if synthesis methods generate
representations on the fly, we still consider them to be
explicit representations, as the input normal map is
in an explicit form,)

The expansion method \[31, 32] extends a small texture into a new larger texture dynamically. 

Zhu et al. \[26] apply the expansion idea to high-frequency rendering.

Blending methods \[33] assume that any pixel in
the resulting texture is a blend of several blocks
sampled from the input texture.

Wang et al. \[25] apply blending-based texture synthesis in their work.They take small microstructure samples as input and generate Gaussian elements on the fly, using constant storage.

However, the glinty effects can be blurred
in some cases, especially for materials with scratches.(fig9)
Exitujúce metódy riešia problém s pamäťou ale majú problém s globálnou distribúciou škrabancov.


### 3.2 implicit representation
pomocou implicitnej reprezentácie je možné generovať
nekonečne veľké, neopakujúce sa mikroštruktúry počas behu programu s malým dodatočným úložiskom

použivajú niekoľko parametrov na ovládanie vzhľadu/tvaru funkcie šumu  v nekonečne veľkom priestore.
Tieto metódy môžu generovať náhodné vzory riadené
šumom, ako sú napríklad hrbole.


Guo et al. \[42] propose an implicit representation method for procedural material parameter estimation.
They introduce a Bayesian inference approach using Hamiltonian Monte Carlo methods to sample the space of plausible material parameters, and fit procedural models to a range of materials such as wall plaster, leather,wood, anisotropic brushed metals, and metallic
paints.

Avšak, pre vykreslenie lesklého vzhľadu
potrebujeme nielen mikroštruktúru, ale aj
zodpovedajúcu akceleračnú metódu  na vylúčenie neprispievajúcich oblastí. Bohužiaľ, žiadna z týchto
metód v súčasnosti nepodporuje dotazy v ľubovoľnom
rozsahu.( queries in an arbitrary range.)


Zatiaľ môžu byť implicitne reprezentované  len dva druhy *glinty appearances* pozri ake vsetky existuju :
trblietavé materiály a poškriabané materiály.(glittery  and scratched ) Zrkadlové vločky spôsobujú trblietavé efekty. 

na rozdiel od všeobecného mikrofacet modelu , trblietavý povrch obsahuje súbor drobných a diskrétnych vločiek ktoré sa majú definovať pomocou nehladkého, priestorovo sa meniaceho BRDF. 

Niektoré metódy \[43 Ershof, 44 Durikovic] považujú diskrétne vločky za náhodné normály s polohami.

Gunther et al. \[45] ukladajú normály a pozície vločiek, aby sa zabránilo blikaniu medzi snímkami ale vyžaduje si to veľa pamäte.

Jakob et al.  \[36] reprezentujú trblietavý materiál stochasticky generovaním vločiek na povrchu. Predpokladajú, že povrchy sú súborom špecifickej množiny náhodne orientovaných facetov a používajú náhodný index na uloženie počtu trblietok v určitej oblasti a uhla telesa. Táto metóda podporuje rozsahové dotazy na mikroštruktúru

Zirr a Kaplanyan*\[*37]* tiež modelujú trblietavý
vzhľad ako súbor implicitne reprezentovaných prvkov vločiek.  Odvodili stochastický dvojrozmerný model
na základe vločkových prvkov a implementujú tento model v v reálnom čase.

V prípade škrabancov musíme zvážiť dve úrovne rozloženia mikroštruktúry. Prvá úroveň opisuje globálne trajektórie škrabancov viditeľné voľným okom,
definované ako krivky. Druhá úroveň charakterizuje mikroštruktúrny profil jedného škrabanca ako prvok.

Raymond a kol. \[38] modelujú mikroštruktúrny profil pre jeden škrabanec ako viacškálový priestorovo sa meniaci BRDF(multi-scale spatially varying BRDF). Používajú šum funkcie na generovanie distribúcií škrabancov, a štatistikou určujú orientáciu a polohu
škrabancov.
Na dopytovanie rozsahu používajú jednoduchú myšlienku, pričom vypočítajú plochu, ktorú zaberá
v pixeli. Ďalej používajú plochu a BRDF jedného prvku na vyhodnotenie príspevok prvku so škrabancami. Avšak ich metóda neberie do úvahy prierez dvoch prvkov do úvahy.

Vyššie uvedené metódy implicitnej reprezentácie môžu
generovať nekonečne veľké parametrizované mikroštruktúry neopakujúcich sa vzorov. Spoločnou výzvou pre takéto metódy však efektívne integrovať a vyhodnotiť P-NDF. Ďalším obmedzením je, že dokážu reprezentovať len niekoľko druhov glinty appearances, pričom používajú špeciálne navrhnuté metódy generovania.

Zhrnieme  explicitné a implicitné metódy reprezentácie  v tabuľke 1.

malý záver


#### 4 Rendering solutions

V tejto časti sa zaoberáme tým, ako integrovať glinty
reprezentácie vzhľadu do klasického Monte Carlo na path traing wokrflowu/pipeline.

### 4.1 Evaluácia
Integrál (2), spojité

researchers use discrete piece-wise elements to describe the microstructure(výskumníci používajú na opis mikroštruktúry diskrétne prvky)
v celkovom querry patch(plocha zodpovedajúca pixelu) G(u) môžu byť milióny prvkov. ale iba niekoľko z nich má  nezanedbateľný príspevok k danému vektoru dopytu(querry vector)

P-NDF v diskretnej forme (3)
Vyhodnotenie možno opísať touto rovnicou vo všetkých metódach s explicitnou reprezentáciou.
Hodnotenie v metódach s implicitneou reprezentáciou
NDF \[36, 38] nemožno zjednodušiť pomocou rov. 3 pretože NDF neukladá (vzťah?) medzi polohou a normálou.

Raymond et al. \[38] priamo vypočítať pomerp oškriabanej plochy k ploche   P a vyhodnocujú NDF podľa toho, pomeru, orientácie škrabancov a nameranej BRDF.

vločky flakes
trblietky glitter

metódy pre vysokofrekvenčné Vločkové materiály(najs preklad)  ako \[36] generujú postupnosť náhodných čísel, ktoré predstavujú rozloženie vločiek. Potom spočítajú častice ktoré prispievajú k osvetleniu bez toho, aby ich skutočne generovali. V ich stochastickom prístupe náhodná aproximácia vločiek nahrádza vyhodnotenie/eval P-NDF. Používajú akceleračné hierarchie? fig 10.11 

Yan et al. \[3] a Wang et al. \[46] vytvárajú 4D ohraničený box(bounding box) pre každý prvok a vytvoria min-max štruktúru na usporiadanie týchto ohraničujúcich boxov zhora nadol ( obr. 11)

metóda querries hierarchický strom prechádzaním zhora nadol s cieľom nájsť prispievajúcich Gaussianov

proces eval v  \[36] sa vykonáva na 4D vyhľadávacom strome, ako je znázornené na obr. 10.

big brain
Každý strom obsahuje aj 4D ohraničujúci box definovaný ako karteziánsky súčin ohraničujúceho poľa v textúrnom/texturovom priestore a sférického trojuholníka v smerovom priestore.
Každž vetva je ďalej rozdelená v textúre aj v smerovom priestore. V textúrnom priestore je ohraničujúci box
rozdelený na štyri rovnako veľké pod-boxy a v smerovom priestore je sférický trojuholník rozdelený na štyri pod-trojuholníky vložením vrcholov do stredov
hrán. Vyhľadávanie prebieha striedavo v priestorej a v smerovej oblasti.

### 4.2 Importance sampling

Importance sampling def.
v podstate ide o urýchlenie výpočtu monte carlo estimatora, tak že, znižime rozptyl vhodnou PDF(probab.dens.func.), teda výpočet je rýchlejší lebo samplujeme dôležitejšie smery(tie čo majú veľký dopad)

 Yan et al. \[3]  zoberu normalu nahodneho bodu a perturbuju ju hodnotou rougness(teda potrebuju normalovu mapu)
 Yan et al. \[1] sampluju z diskretnych gausianskych elementov
Raymond et al. \[38] sampluju smery  okolo ωi
ktore su randomly generated within the reflection
cone following a 1D probability distribution function
based on the mirror scratch BRDF.

Jakob et al. \[36] definuju
smooth density function to describe the distribution of flakes and use for sampling(rychle ale nevie vsetko vykreslit dokonale)

### 4.3 Multiple scattering
we mean self-scattering between microstructures.
teda ozptylenie medzi mikrostrukturami

vedie to k lepsim vysledkom za cenu vacsich narokov na pamet a vypocet 

nemame physically based analytical Multiple scattering model, iba empiricke-results based
Raymond et al. \[38] simulate multiple-scattering
by pre-computing distributions of scratch profiles.

Chermain et al. \[27] derive an energy-compensation
BRDF(fake normal perturbations)

Turquin \[47] deduces a compensated P-BRDF for
glinty appearance(good results)

#### 5 Experimenty
#### 6 Rozšírenia

### 6.1 Wave optics
Môžu sa vyskytovať farebné odlesky aj keď objekt osvetľuje zdroj bieleho svetla.Vo vlnovej optike sa svetlo opisuje pomocou komplexných poliami s komplexnými veličinami. Harvey–Shack \[50, 51] or Kirchhoff \[52, 53],
Werner et al. \[54] derive a wave-optical and analytical shading model based on Harvey–Shack theory \[50], where the surface is represented as a collection of randomly oriented scratches over a smooth BRDF.
(extended to real time by Velinov et al. \[55])

Guo et al. \[56] extend the stochastic model [36] to take wave-optical effects due to thin- film interference into account, reproducing iridescent reflection.

Yan et al. \[57] present a solution to derive a wave effect-aware BRDF model on surfaces described as a discretized height field( support arbitrary glint features.).

### 6.2 Machine learning methods
zaoberaju sa reprezentaciou
2kategorie: inverse model to provide an explicit representation, and the other uses a procedural model for an implicit one.
napr https://mworchel.github.io/svbrdf-estimation/
a skip

### 6.3 Real-time rendering
Súčasné práce v reálnom čase sa zaoberjú implicitne reprezentovanými materiálmi.

Zirr a Kaplanyan \[37] navrhujú stochastický dvojrozmerný mikrofacetový
model( stochastic bi-scale microfacet
model ) na vykresľovanie viacškálových odleskov v reálnom čase vrátane diskrétnych vločiek a štetcových? značiek.

Wang a kol.\[25] navrhujú metódu  pre-filtrovania pre stochastický diskrétny mikrofacetový model na simuláciu odleskov pri environmentálnych mapách(prostredia) aj bodových svetelných zdrojoch v reálnom čase. 

Velinov et al \[55] spracúvajú škrabance pomocou vlnovej optiky. 

Chermain et al. \[67] navrhujú metódu na vykresľovanie vločiek v reálnom čase. Používajú mip-mapy  na urýchlenie vykresľovania. Ďalej navrhujú metódu antialiasingu \[68] v reálnom čase.

Žiadne existujúce riešenia v reálnom čase nedokážu konzistentne spracovať lesklý/glinty vzhľad explicitne definovaný normálovými mapami s vysokým rozlíšením, čo obmedzuje rozmanitosť týchto glinty vzhľadov pri vykresľovaní v reálnom čase.

Pamäť nie je dostatočná na uchovanie kompletnej informácie o škrabancoch.
Taktiež syntézu textúr je náročné implementovať a urýchliť aby  mala dostatočný výkon v reálnom čase.


#### 7 zhrnutie 




https://schuttejoe.github.io/post/ggximportancesamplingpart1/ sggx importsnce sampling part1, 2