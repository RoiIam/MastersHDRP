zmeny v unity: 
Assets settings/HDRPDefaultResources pridane 
Custom_HDRenderPipelineGlobalSettings.asset
a
Assets settings/ pridane 
HDRPPerfFwd a HDRPPerfBoth -nastavuje rendering lit shader mode na Def/Fwd/Both
tieto assety treba dat ako Project settings-Quality ako nove levely
potom sa zobrazia v 
v project settings - graphics treba dat ten settings asset


teraz treba povypinat co nemenime, treba vypnut lights a Scene-sceneSettings
v project settings hdrp global settings treba vypnut hdri sky


Lit.hlsl 
prepinanie LIT_USE_GGX_ENERGY_COMPENSATION alebo USE_DIFFUSE_LAMBERT_BRDF

SHADERPASS == SHADERPASS_FORWARD

LightLoop.hlsl handluje spracovanie svetiel, aky typ svetla to je zisit cez LIGHTFEATUREFLAGS_XX napr LIGHTFEATUREFLAGS_DIRECTIONAL alebo PUNCTUAL alebo AREA alebo ENV alebo SKY alebo ssrefraction a ssrrefrlection
tie volaju potom EvaluateBSDF_Punctual atd ktore su definovane v Lit.hlsl

pridajme vlastny ShaderPassForward.hlsl z renderpasses tam je Frag() a vola LightLoop()-ten LightLoop.hlsl

svetlo zo vsetkych svetelnych zdrojov sa akumuluje do aggregateLighting variable, ta sa posiela do postEvaluateBSDF-v lit

pokus zmenit aby directional light daval iba jednu farbu
v lit shaderi, Evaluate_BSDF_dir nastavime base color na vlastnu

(agregate)lighting.direct.specular je stale menena cez base color
lighting.indirect.specularReflected dava base color farby,treba zistit preco

kedy sa pouziva GetPreIntegratedFGDGGXAndDisneyDiffuse?? v GetPrelightData a to v ShaderPassForwad.hlsl

meni sa cez 2140 lightLoopOutput.diffuseLighting = modifiedDiffuseColor * lighting.direct.diffuse + builtinData.bakeDiffuseLighting + builtinData.emissiveColor;
presnejsie builtinData.bakeDiffuseLighting WTF nic som nebakeoval...

za to moze setting v project settings nazvane VisualEnvironment, ked davame sky a nie je none
\Runtime\Sky\HDRISky\ ale co ho spusta...

nasli sme to v lit.hslsl vo funkcii ModifyBakedDiffuseLighting ale teraz je to sede? nie stale cierne...
musime niekde vypnut tie hdri cubemapy ale netusim kde. najlepsie bude vypnut sky kompletne a neskor sa k tomu vratit

uh nepomohlo to? diffuse sa stale meni? aj s none sa meni...

ked zmenim priamo vysledok dirLightu spec a diff, tak postEval stale neni dobre modifiedDiffuseColor a 

ak zmenim pred vypoctom len bsdfData.diffuseColor mame problem, dirlight stale ovplyvnuje daco,
treba zmenit aj bsdfData.fresnel0

kde sa vypocitava fresnel0? asi ConvertSurfaceDataToBSDFData
jup
vysvetli ale preco je to teraz malo diffuse- lebo smoothness... a /alebo metallic
teraz mozme vsetko povracat

podme spravit ako nacitat dictionary- 
najprv zistime ako sa nacitava textura, potom ako nacitat array textur-v opengl sa to robilo v cpp, tu netusim ako 
_BaseColorMap_ v LitData

a haaa nacitavanie map je robene v LitDataIndividualLayer.hlsl, presnejsie line 206:
`float4 color = SAMPLE_UVMAPPING_TEXTURE2D(ADD_IDX(_BaseColorMap), ADD_ZERO_IDX(sampler_BaseColorMap), ADD_IDX(layerTexCoord.base)).rgba * ADD_IDX(_BaseColor).rgba;`

vieme zistit `#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitDataIndividualLayer.hlsl`
a to je v LitData.hlsl
pridame do LitProperties TEXTURE2D_ARRAY a Sampler
pridame do Lit.Shader `_testDict("testDict", 2DArray) = "" {}`
ale stale sa neukaze v gui, treba zmenit : Packages/com.unity.render-pipelines.high-definition/Editor/Material/UIBlocks/LitSurfaceInputsUIBlock.cs

potom je tu dake `SetMaterialTextureProperty("_BaseColorMap", material, textureProperty);` teda material.SetTexture(...)


po prehodeni HDRP na local package, spravili sme tieto zmeny - stale cez //RCC
 vsimnime si ze niektore jetbrains inteliij nefunguju zase... tazsie zistit co/kde je vlastne BuiltinData-stacilo spustit unity znova a refreshlo to jetbrains
 1. uz nejdeme pouzivat custom Lit shader, iba defaultny Lit.hlsl ideme upravovat
 2.  pridana `_MyColor("MyColor", Color) = (1,0,0,1)//RCC` do *Lit.shader*
 3. Lit.hlsl a LightLoop ziadne zmeny
 4. do *LitProperties.hlsl* pridane `float4 _MyColor; //RCC` a `PROP_DECL(float4, _MyColor);`
 5. v *LitSurfaceInputsBlock.cs* :  
	 1. nova `MaterialProperty[] myColor = new MaterialProperty[kMaxLayerCount];//RCC`
	 2. v LoadMaterialProperties() `myColor = FindPropertyLayered("_MyColor", m_LayerCount);`
	 3. a treba to vykreslit `materialEditor.TexturePropertySingleLine(Styles.baseColorText, baseColorMap[m_LayerIndex], myColor[m_LayerIndex]);//RCC` vsimnime si ze este tam davame aj baseColorMap-compatibility reason-netreba to mozme cele rovno vymazat a vytvorit vlastne *GUIContent*
 6. v *LitDataIndividualLayer.hlsl* `surfaceData.baseColor = ADD_IDX(_MyColor).rgba;` na test, funguje
 teraz mame vsetko nastavene nech dava myColor a defaultne je cervena, nerobime podla bodu 6 nacitavanie z textury
nic sa nerobilo automaticky, ani UI :/
dalsi step:
pridat nas dictionary...


ako unity handluje 2D arrays:
nevieme robit s 1D arrays- hlsl vie ale unity vsetko budu 2Darrays-ved maju len 2dimenziu 1 :)
https://forum.unity.com/threads/solved-1d-textures.30103/  `Unity doesn't support 1D texture properties, so you can't get as far as accessing them in a shader. A 1D texture in a 2D texture property won't lose you any meaningful performance`
https://docs.unity3d.com/Manual/class-Texture2DArray.html - tiez navadzaju na vytvorenie skrpitu ktory generuje 2D array ako unity .asset
https://docs.unity3d.com/Manual/SL-Properties.html ShaderLab material properties-pozor mozu byt rozdiely s built in a HDRP
catlikecoding ma priklad https://catlikecoding.com/unity/tutorials/hex-map/part-14/ robi tu aj s 2DArrays, sekcia 2.5
	https://forum.unity.com/threads/struggling-with-2darray-using-texture2darray.685387/

1. vytvorme asset 2D Arrays a pridajme tam nasich 64levelov, kde kazdy level ma 16 dist-1024 samostatnych exr suborov
	podla catlikecoding
	1. wizard vytvoreny, mozme presunut textury do unity assetov
	2. nastavi texture 0 , zvol vsetky 2d textury a pretiahni do wizardu, bum hotovo
	3. `C:\Users\robko\Documents\UnityProjects\Grassfolk\Library\PackageCache\com.unity.shadergraph@13.1.8\Editor\Generation\Targets\BuiltIn\ShaderLibrary\Shim\HLSLSupportShim.hlsl` obsahuje makro na define *UNITY_SAMPLE_TEX2DARRAY* 
		1. v LitDataIndividualLayer.hlsl vytvorme SurfaceData *surfaceData.sampledDict* a nastavme ju
	

mame problem-ked pridame Lit.shaderu veci ako surfaceData, tak to potrebuje aj LayeredLit inac sa stazuje

dalesi problem
surface data musime preniest do bsdf data... ConvertSurfaceDataToBSDFData( ) aby sme ich mohli pouzit v LightLoope, respektive v surfaceShading.hlsl- resp. v  - ShadeSurface_Infinitesimal- EvaluateBSDF( v Lit.shader

skusme znova,
od main()
mame VertexNorm-  z vert shadera norm je normalize(model* Vertexnormal) teda je vo world space
	v unity mame surfaceData normalWS a aj tangentWS. aky je rozdiel medzi normalWS a geomNormalWS???
	bitangentWS si vieme dopocitat
	vertexpos ma byt tiez vo world space, ako sa k tomu dostanem? :D idk
	teraz musime spravit mat3 to local- to vieme
dalej spravit *wi*- potrebujeme uz poziciu svetla, cize toto *robime uz v svetle*
dalej *wo*
spravit distanceSquared
Li =
pocitanie f_P(wo,wi)\*Li:
	ako sa robi dFdx a dFdy v hlsl?
	MaxAnisotropy pridat
	teraz pocitame D_P cez *ndf beckman* - material  aX a Ay- zistit ci nemame uz preddefinovane alebo vytvorit nove float1y
	else - pocitame P22_P cez funkciu *P22__P_* tu neskor popiseme
	pocitame G1wowh a G1wiwh na G
	pocitame Fresnel
	return FGD/(4\*wo.z)
teraz funkcia P22__P_
	potrebujeme funkciu *pyramidSize* -len maly prepocet
	vela kodu 
	teraz scan over ellipse s SDF
	potrebujeme *P22_theta_alpha* funkciu
teraz funkcia pyramidSize
	len maly prepocet
teraz funkcia P22_theta_alpha
	potrebujeme *hashIQ* funkciu
	potrebujeme *sampleNormalDistribution* funkciu -tam zase funkciu *erfinv*
	vela kodu
	a az teraz samplujeme P_i a P_j 

teraz f_diffuse - tu len spojime difuznu texturu \*m_i_pi\*wi.z

potrebujeme aj ine variables napr MaxAnisotropy

zaciatok: musime zistit kde sa pocitaju relevantne info, naj miesto je pocitat v surfaceShading.hlsl, upravime *ShadeSurface_Infinitesimal* na *ShadeSurface_Infinitesimal_Glints*
alebo je to lepsie v Lit.hlsl kde mame EvaluateBSDF_Glints

pozor vsetko v unity je defaultne nastavene na camera relative pozicie
	vid https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@16.0/manual/Camera-Relative-Rendering.html - RWS relative came World space, da sa to ale prepnut na vypnute v ShaderConfig.cs
	mozno aj toto zaujme https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@14.0/manual/Custom-Pass-Creating.html
	https://stackoverflow.com/questions/16578765/hlsl-mul-variables-clarification mul namiesto \*  pri pocitani float3x3 a krat float3
	https://anteru.net/blog/2016/mapping-between-HLSL-and-GLSL/ viac HLSL vs GLSL
	viac ku kamera space...
	https://forum.unity.com/threads/what-is-eye-space-in-unity-shaders-nb-its-not-view-space.797775/
ako to vlastne funguje
 v PostEvaluateBSDF() sa pocita s finalnym agregate svetlom, vola sa v LightLoop()(LightLoop.hlsl)
 v LightLoope() mame EvaluateBSDF_Punctual() ktora sa nachadza v Lit.hlsl a vola  ShadeSurface_Punctual()(ta je v SurfaceShading.hlsl) v nej sme zmenili ShadeSurface_Infinitesimal na ShadeSurface_Infinitesimal_Glints, ta vola EvaluateBSDF()(zase v Lit.hlsl) zmenime na (EvaluateBSDF_Glints) a pocita Fresnel, DV-spec a diffuse.
 musime to nejako rozumne spojit 

musime zistit ako ziskat textcoords presnejsie texCoord0, ktory je v FragInputs. , ziskava sa to v  `GetSurfaceAndBuiltinData` a
nejako v hlsl hapruje if testovanie &&? akoby kompiler myslel ze to moze byt compile time brach a optimalizuje to tak ze vnutri deli nulou? wut skusme texcoord nedavat natvrdo
vyzera ze to to fixlo ale teraz mame unroll loop problem-ked to kompiluje vsetko, tak to vyzerie celu pamat

commit
ideme zistit v com je problem
light loop je scalarized, co to znamena? idk presne skus citat komenty a https://flashypixels.wordpress.com/2018/11/10/intro-to-gpu-scalarization-part-1/
iny problem, vsetko co upravujem meni aj layered lit aj tesselated aj terrain shadery, asi sa musime vratit k customLit

dajme pred loop UNITY_LOOP hned pred while aby sme ho forcli aby bol dynamic
https://forum.unity.com/threads/custom-function-in-hdrp-shadergraph-unable-to-unroll-a-loop.893887/
viac v d3d11.hlsl cez // flow control attributes

dostal som aj tento funny error ked som skusil unroll light loopu
`Shader error in 'HDRP/Lit': Compiler timed out. This can happen with extremely complex shaders or when the processing resources are limited. Try overriding the timeout with UNITY_SHADER_COMPILER_TASK_TIMEOUT_MINUTES environment variable.`

takze dali sme UNITY_LOOP pred 2 vnorene fory v P22__P_ funkcii
a este aj v lightLoop line 285: UNITY_LOOP while (v_lightListOffset < lightCount)
teraz to vsetko poriadne skompiluje a na nic(okrem ostatnych shaderov) v Lit standard - lit.cs sa nestazuje, uz len vlozit tie trblietky...
teraz 2 veci: 1. pridat trblietky do vysledku a 2. zistit ako ziskame Texcoord v surface shading :D mozno 3. prepisat nech je to zase customLit, lebo teraz vsetko trpi.... zbytocne mi to kompiluje dalsie shadery   
musime nejako vysledok  dat do Lit.hlsl func. EvaluateBSDF_Glints( ) line 1470 ->  float3 specTerm = F * DV;

	nieco mame zle: asi to suvisi s vstupom pre f_p - 
![[Pasted image 20230429104503.png]]


```if (wo.z <= 0.)  
    return float3(1,0,0); //to je na zatienenej strane if (wi.z <= 0.)  
    return float3(0,1,0); // to je na pravej diagonale-cudne  
  
// Alg. 1, line 1  
float3 wh = normalize(wo + wi);  
if (wh.z <= 0.)  
    return float3(0., 0., 0.);//totosa nenaslo   
// Local masking shadowing  
if (dot(wo, wh) <= 0. || dot(wi, wh) <= 0.)  
    return float3(0,0,1);
a totalny return je float2(0,0,1);
```


konecne riesenie:
porovnaval som co mam v opengl vs hlsl podla zelenej/cervenej farby
usudil som ze treba prestat pouzivat camera relative space, takze zmenili sme package hdrp.config 
prepli sme  CameraRelativeRendering, lepsie, lahsie sa pozita wo, wi, bez toho  mi to moc neslo napravit dik unity...
samozrejme bolo treba edit-rendering-gen shader includes 
dalej sme mali chybu niekde sme mali nastavene NLevels na 64 a ma to byt 16
namisto bsdfData pouzivame surfaceData bolo treba ich dat do LightLoop-u


niektore float1 sme prepisali do float, neni to problem ale mali by sme to 

zmenili sme nech to normalne berie texturu v LitDataIndividualLayer
objekty su presvetlene ale co uz
takze oteraz maju nielen FragInputs ale aj SurfaceData v lightLoop(), EvaluateBSDF_Punctual() ShadeSurface_Punctual()   a f_P()
zmeny cisel zadanych 0. na  0.0 alebo 0
lit.hlsl PostEvaluateBSDF zatial nepridavame lightLoopOutput.specularLighting posledne 2 riadky
odstranene real3 sampledDict z lit.cs.hlsl (aby neboli chyby)
dalej by sme sa mali vratit k CustomLit, je to otravne same chyby nam davaju vsetky ostatne shadery ked sme popridavali veci a u tych dalsich shaderoch ich neinit. a navyse to zvysuje compile times 

skusali sme napr transponovanu maticu tolocal, skusali sme zmenit znamienka z suradnic
este precistene a commitnute v pondelok 1.5

zaujimalo ho ten silny odlesk z trblietky ked  otacame kamerov v unity to tak dobre nebolo vidno
ked som ukazal shadertoy zirr+kaplanyana https://www.shadertoy.com/view/ldVGRh tak to v snehu na zemi  hlavne v dialke bolo dolezite vid zosit

chce aj webstranku, github s linkami na vsetko

dalsi krok
presun do uplne noveho projektu, nepouzivame local packages
novy projekt sa vola MastersHDRP
teraz mame vsetko customLit museli sme zmenit trocha ako sa v ui zobrazuje testDict
https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@11.0/manual/hdrp-custom-material-inspector.html
https://docs.unity3d.com/ScriptReference/ShaderGUI.html
a customLit.shader ma na spodku definovany custom editor
este treba zmenit camera relative rendering na 0.. ktovie ci sa to da len cez unity editor
neda sa treba to mat lokalne vid https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@15.0/manual/HDRP-Config-Package.html
a zase tento link
https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@16.0/manual/Camera-Relative-Rendering.html

este zostava presunut notes do priecinka docs
a pridat linky a text v readme, pridat kalendar cielov atd
prezentacia pptx

other:
prechod na local verziu package 
https://forum.unity.com/threads/editing-and-tracking-changes-to-package-files.647407/
https://support.unity.com/hc/en-us/articles/9113460764052-How-can-I-modify-built-in-packages-
https://forum.unity.com/threads/how-to-modify-unity-packages-using-custom-code-and-files-and-also-export-custom-package.799170/ yes prerabat celu package je nanic ak sa povodna upgradne, ale co uz

stare ale dobre zhrnutie LWRP-teraz URP https://lantertronics.blogspot.com/2019/07/customizing-lit-shader-in-unitys.html
	alebo https://medium.com/@antoinefortin_64750/unity-hdrp-dissection-ca7b28ec583b aj ked tak do hlbky to nejde ako tvrdi nazov clanku... a dalsiu cast nikdy nenapisal ako tvrdil v zavere :D
https://forum.unity.com/threads/how-to-declare-sample-texture-2d-array-in-hdrp.830757/  + shadergraph Docs https://forum.unity.com/threads/how-to-declare-sample-texture-2d-array-in-hdrp.830757/ (older but good)

glsl to hlsl 
https://learn.microsoft.com/en-us/windows/uwp/gaming/glsl-to-hlsl-reference

co robi textureLod
https://docs.gl/sl4/textureLod

mozno relevantne info 
https://forum.unity.com/threads/sampling-from-diffuse-and-other-gbuffers-for-deferred-hdrp-post-processes.929766/

https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@12.1/manual/Default-Settings-Window.html
https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@12.1/manual/Frame-Settings.html
https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@10.2/manual/Override-HDRI-Sky.html
https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@10.2/manual/Override-Visual-Environment.html

another cool thread
https://forum.unity.com/threads/trying-to-replicate-the-hdrp-lit-shader-i-need-help-with-the-detail-input-part.660538/

apparently c# classes- nemozu zacinat cislom 
https://stackoverflow.com/questions/950616/what-characters-are-allowed-in-c-sharp-class-name