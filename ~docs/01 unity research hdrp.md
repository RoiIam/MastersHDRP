
moj projekt (unity v. 2022.1.5f1) ma hdrp verzie 13.1.8 (najnovsia je 16.x.y) 


2021 hdrp guide, 2020lts guide https://blog.unity.com/technology/it-begins-with-light-the-definitive-guide-to-the-high-definition-render-pipeline
ako korektne vytvarat modely a nastavit pipeline 
https://learn.unity.com/tutorial/creating-believable-visuals?uv=2019.4&projectId=5c514a74edbc2a00206947de#5c7f8528edbc2a002053b548 

## Custom pass
https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@16.0/manual/Custom-Pass.html

Custom Pass allows you to do the following:

-   Change the appearance of materials in your scene.
-   Change the order that Unity renders GameObjects in.
-   Allows Unity to read camera buffers to shaders.

For example, you can use a Custom Pass to blur the background of a camera’s view while the in-game UI is visible.

Unity executes a Custom Pass at a certain point during the HDRP render loop using an [Injection Point](https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@16.0/manual/Custom-Pass-Injection-Points.html).
more, guide: https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@16.0/manual/Custom-Pass-Creating.html

#### vyuzitie
mozme citat camera buffery a manipulovat scenou-*asi moc restriktivne*
*Frame debugger* window - zide sa :) 

pomocne video na tvorbu custom pass https://www.youtube.com/watch?v=vBqSSXjQvCo

## injection point
https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@16.0/manual/Custom-Pass-Injection-Points.html
![[HDRP-frame-graph-diagram.png]]
*bohuzial vyzera ze toto sa priamo nebude dat vyuzit, my ,ked tak, potrebujeme menit NDF v BRDF a ich vstupy(normaly alebo cool lobes)*


priklady hdrp custom passes v hdrp 13.x https://github.com/alelievr/HDRP-Custom-Passes , naj vyzera "Thickness aproximation using a custom pass rendering backfaces in custom depth"
https://user-images.githubusercontent.com/32760367/68871276-76a0db00-06fc-11ea-9f97-db4c7b98dac1.png


### command buffers(CB) v srp (napr hdrp)
nie prave naj poradie:
https://docs.unity3d.com/Manual/srp-using-scriptable-render-context.html
https://docs.unity3d.com/Manual/GraphicsCommandBuffers.html

mozno len URP podporuje CB?
starsia diskusia https://forum.unity.com/threads/hdrp-how-to-render-anything-custom.592093/
resp https://github.com/johnsietsma/ExtendingLWRP ScriptableRendererFeature
nasiel som to v urp, render feature
https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@16.0/manual/urp-renderer-feature.html?q=%20Renderer%20Feature
ale tiez to neposkytuje taky level uprav aky by sme chceli

### urp nepodporuje replacement shaders? 
(nepodporovao do 2022.2) vid https://forum.unity.com/threads/how-to-render-everything-with-a-replacement-shader-with-hdrp.678247/
vid  https://forum.unity.com/threads/urp-camera-replacement-shader.1251825/
	https://developer.arm.com/documentation/102487/0100/Migrating-custom-shaders-to-the-Universal-Render-Pipeline
	https://assetstore.unity.com/packages/vfx/shaders/dynamic-soft-shadows-based-on-local-cubemaps-61640#content pozri ShadowMap_URP.shader je to free...chceck review for guide, some import errors 

custom render feature example v URP
https://www.kodeco.com/22027819-volumetric-light-scattering-as-a-custom-renderer-feature-in-urp

takze vyzera to tak ze priamo menime 
Library/PackageCache/com.unity.render-pipelines.high-definition@13.1.8/Runtime/Material/Lit/Lit.hlsl
presnejsie `C:\Users\robko\Documents\UnityProjects\Grassfolk\Library\PackageCache\com.unity.render-pipelines.high-definition@13.1.8\Runtime\Material\Lit\Lit.hlsl`

ano, *Lit.hlsl*
tam mame napr \#def  LIT_USE_GGX_ENERGY_COMPENSATION 
 pozri \#ifdef LIT_USE_GGX_ENERGY_COMPENSATION
 tam to asi upravuje struct PreLightData, to posiela quote "Precomputed lighting data to send to the various lighting functions"
pouziva sa v LightLoop.hlsl, VFXLit.template,deferred.shader, SurfaceShading.hlsl, AxF.hlsl a AxPFathTracingSVBRDF.hlsl(a pod. RT), SimpleLit.hlsl,LitReferece.hlsl

asi LightLoop.hlsl a SurfaceShading.hlsl budu dolezite
skus aj LightEvaluation.hlsl

v SurfaceShading.hlsl : DirectLighting ShadeSurface_Infinitesimal ?
	EvaluateBSDF je v Lit.hlsl ako CBSDF EvaluateBSDF

note rider poriadne nefunguje lebo hrdp package nema ziadnu solution... fix? idk https://www.jetbrains.com/help/rider/Unreal_Engine__HLSL_Shaders.html

GGX paper
https://www.cs.cornell.edu/~srm/publications/EGSR07-btdf.pdf
hlavne cast 5 o brdf, konkretne zlozka microfacet distribution function -D (to je ta nasa NDF), kde je ich magia v GGX , zirr + kaplanyan ju spominaju [37] tiez v 2Previous work
co je ... Schlick? fresnel?
	https://belcour.github.io/blog/slides/2020-brdf-fresnel-decompo/index.html#/2 - this is impressive ale je to fresnel term, F nie D

... kde robime NDF, D cast... DV_SmithJointGGX? f_d_reflection? D_GGX?

DV_SmithJointGGX je v BSDF.hlsl Library/PackageCache/com.unity.render-pipelines.core@13.1.8/ShaderLibrary/BSDF.hlsl
smith microsurfaces....
sme blizsie vid leather https://belcour.github.io/blog/research/publication/2017/05/01/brdf-thin-film.html

aaah 
sekcia Specular BRDF
D_GGXNoPI, G_MaskingSmithGGX
hmmm? https://jcgt.org/published/0003/02/03/paper.pdf search for walter ofc
a mozno este lepsie https://hal.inria.fr/file/index/docid/942452/filename/RR-8468.pdf
![[Pasted image 20230225194358.png]]
mame tu kalkulacie aj  pre cloth a hair atd, 
Diffuse Lighting for GGX + Smith Microsurfaces, p. 113.


nieco novsie? 
https://hal.science/hal-01509746/document z https://schuttejoe.github.io/post/ggximportancesamplingpart2/

pouzivaju ggx+smith - iba diffuse
https://ubm-twvideo01.s3.amazonaws.com/o1/vault/gdc2017/Presentations/Hammon_Earl_PBR_Diffuse_Lighting.pdf

spec, specular, glossy, metal

D_GGXNoPI a D_GGX su funkcie na vypocet D pre ggx, v  casti specular brdf
pouzivaju sa v  SolidAngleKernelGenerator.cs a ReflectionKernelGenerator.cs

Spherical Pivot Transformed Distributions?
stratilo sa: Surface shading (all light types) below - v Lit.hlsl 

v AxF.hlsl najdeme  clearcoat, carpaints
a dokonca aj FLAKES_JUST_BTF

axf---- https://www.xrite.com/axf/sample-library
appareance exchange format...

hmmm
```
preLightData.flakesFGD =  
//  
// For flakes, even if they are to be taken as tiny mirrors, the orientation would need to be  
// captured by a high res normal map with the problems that this implies.  
// So instead we have a pseudo BTF that is the "left overs" that the CT lobes don't fit, indexed  
// by two angles (which is theoretically a problem, see comments in GetBRDFColor).  
// If we wanted to add more variations on top, here we could consider  
// a pre-integrated FGD for flakes.  
// If we assume very low roughness like the coat, we could also approximate it as being a Fresnel  
// term like for coatFGD below.  
// If the f0 is already very high though (metallic flakes), the variations won't be substantial.  
//  
// For testing for now:  
preLightData.flakesFGD = 1.0;
```
//Apply flakes
a  CarPaint_BTF, coatFGD
// Sample flakes as tiny mirrors
	a kopa // Todo_Flakes :) 

https://github.com/Unity-Technologies/Graphics/search?q=flake ? \_CarPaint2_FlakeMaxThetaIF
pozri *AxF-Shader.md*

D termy NDF pozname phong, becmann, GGX


### random links
 napr trocha o ggx a kopa inej teorie http://www.neilblevins.com/art_lessons/art_lessons.htm
GGX paper: https://www.cs.cornell.edu/~srm/publications/EGSR07-btdf.pdf
https://wenjian-zhou.github.io/2022/03/16/microfacet.html  microfacet
https://archive.org/details/GDC2015McAuley/page/n77/mode/2up fc4
https://www.yumpu.com/en/document/read/51943795/physically-based-shading-at-disney disney
https://github.com/wdas/brdf , https://blog.selfshadow.com/publications/s2012-shading-course/burley/s2012_pbs_disney_brdf_notes_v3.pdf disney bdrf
https://pbr-book.org/3ed-2018/contents

https://pbr-book.org/3ed-2018/Reflection_Models/Microfacet_Models microfaced NDFs

https://dl.acm.org/doi/10.1145/2601097.2601155 4ta minuta

https://dl.acm.org/doi/10.1145/2601097.2601155
https://alexsabourindev.wordpress.com/2020/09/13/diary-of-a-path-tracer-multiple-importance-sampling/ 

https://agraphicsguy.wordpress.com/2015/11/01/sampling-microfacet-brdf/
	https://stupidrenderer.wordpress.com/2015/08/10/a-good-summarization-of-microfacet-models/
	http://graphicrants.blogspot.com/2013/08/specular-brdf-reference.html/
	https://agraphicsguynotes.com/posts/sample_anisotropic_microfacet_brdf/
 ggx+smth aj na diffuse nie len spec: https://media.oiipdf.com/pdf/daee2660-db96-4eda-a155-4beec423c387.pdf
chermain nove poznatky od procedurall...
https://xavierchermain.github.io/data/pdf/Chermain2021RealTime.pdf
https://xavierchermain.github.io/data/pdf/Chermain2021ImportanceSampling.pdf

https://www.cs.cornell.edu/courses/cs6630/2012sp/slides/Wang-Khungurn-NonlinearPrefiltering.pdf prefiltering simple ndf


# 2 pokus, narabanie s unity materialmi, shadermi


TLDR v unity vieme (s miernymi tazkostami) upravovat HDRP kod az na najnizsej urovni(teda BRDF, frag,vert shadery. nemame pristup do c++ kodu Unity-to ani nepotrebujeme)

Najblzsie trblietkam, Unity ma carPaints v HDRP ako shaderGraph material  postaveny na stackLit-e(ale aj Lit ide) 
pretoze je tam len navyse pridane samplovanie normaly trblietok ako vstup do lit/stackedLit.
Aspon skuska AxF nevysla, je tazke(skor nemozne) vytvorit a importovat materialy.

Hladanie uz existujucej implementacie:
1. oficialne vzorky
2. pozrieť prácu iných na Asset store a pod

### 1. Oficialne "vzorky": 
Pozrieme sa na to ako sú v unity HDRP reprezentované materiály, našiel som 3 roky neupdatovany repozitar materialov- ma *carPaint* shaderGraph. 
https://github.com/Unity-Technologies/MeasuredMaterialLibraryHDRP
Je spraveny pouzitim Stacklit shaderu v shaderGraph-e.
https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@12.0/manual/master-stack-stacklit.html



stacklit shader(vieme si pozriet .hlsl)
má základnú povrchovú farbu, clear coat a haziness
*Stacklit* je viac rozobraty tu:
V odpovedi na  https://forum.unity.com/threads/how-does-clear-coat-work-in-hdrp.556153/ je potvrdene autormi ze
clear coat puziva 2 sposoby:

v Lit.shader je to spominane v prezentacii:  https://advances.realtimerendering.com/s2018/Siggraph%202018%20HDRP%20talk_with%20notes.pdf
v stacklit je to tento papier+ prezentacia:
Eﬀicient Rendering of Layered Materials using an  Atomic Decomposition with Statistical Operators  Laurent Belcour
https://hal.science/hal-01785457/document
https://belcour.github.io/blog/slides/2018-brdf-realtime-layered/slides.html#/1


### AxF (appaerance exchange format)
AxF je X-rite-pantone vlastny proprietary material https://www.xrite.com/axf  
AxF: problem najst a importnut materialy
(nejake sample materialy sa sice daju stiahnut https://www.xrite.com/axf/sample-library -chce to vela osobnych info na "free sample") 
navyse unity axf importer je len v specialnej industry verzii(trial/platene), neviem ako by mi teda tie materialy pomohli
https://docs.unity3d.com/Packages/com.unity.render-pipelines.high-definition@16.0/manual/AxF-Shader.html , 
chcel som ho skusit, lebo maju tam zmienky o trblietkach, presnejse car paint flakes

### CarPaint ShaderGraph
CarPaint shader graph iba na vstup dáva normálovú mapu ktorú vieme tilovať, zväčšiť počet a intenzitu flakov a to je všetko, viď shaderGraph. 
Takže to môžme dať aj len do Lit shadera. 
Skúsil som viacero normálových textúr, škrabancov, brúseného kovu, ľadu(niektoré sú horšej kvality)
v podstate je to implicitná reprezentácia cez normálovú mapu ktorú tilujeme a pri renderingu ju nejako špeciálne nesamplujeme- žiadny hĺbkový efekt

Co to vie: pridat normalovu texturu flakes. Mame base color paint a potom Coat nastavenia s pridanymi trblietkami, flakes
Vieme menit IOR.Thickness, Tint, hazines, intensitu, tiling

### Manualne pisanie vastnych shaderov v Unity SRP  
https://docs.unity3d.com/Manual/SL-SurfaceShaders.html surface shadery iba pre built-in pipeline
viac menej Unity odporuca shader graph pre URP a HDRP
https://docs.unity3d.com/Manual/shader-writing-vertex-fragment.html
It is not recommended to write your own shader programs for HDRP, due to the complexity of the code. Instead, use [Shader Graph](https://docs.unity3d.com/Manual/shader-graph.html) to create **Shader objects**[](https://docs.unity3d.com/Manual/shader-objects.html)  [](https://docs.unity3d.com/Manual/Glossary.html#Shaderobject)without writing code.

Ale da sa pracovat s tym, problem je ze treba hladat v tej spleti suborov(variantov-includov) co kde sa napaja 

### 2. praca inych 1/2
Repo kde niekto robil custom HDRP
https://github.com/keijiro/TestbedHDRP  (ziskane z fora https://realtimevfx.com/t/hdrp-renderer-with-custom-shader-code-unity/7557/5)
blizsie:
https://github.com/keijiro/TestbedHDRP/tree/master/Assets/CustomShader/Spiralizer/Shader
tam ma *Spiralizer.shader*  s vlastnym vert a frag shaderom, pricom pouziva FragInputs a cutomizovanu ale copy paste void Frag(...)

Cele je to take zvlastne, nebolo to navrhnute aby sa tak lahko upravovali, vytahovali a udrziavali vlastne modifikacie na HDRP. Asi preto odporucaju shaderGraph.  Napr. ked vyjde nova verzia HDRP, cely shader treba prejst a vsetky includes co sme upravili my, porovnat s novou verziou HDRP.

Priklad jednoducheho shadera v URP , priamo v docs URP
https://docs.unity3d.com/Packages/com.unity.render-pipelines.universal@12.1/manual/writing-shaders-urp-unlit-texture.html

### 2. praca inych 2/2:
### prehladanie asset storu:
## su to len trblietky pre auta, asi vsetko platene
zoradene podla naj
https://assetstore.unity.com/packages/vfx/shaders/directx-11/car-paint-pro-76361#description -lots of stuff, flakes
	docs http://beffio.com/car-paint-documentation 
	complex material with four layers: a base diffuse layer, a base glossy layer, reflective coating layer, overlay layer, fresnel layer, metallic flakes layer, and clear coat layer. The material allows the adjustment of each of these layers separately.
	
https://assetstore.unity.com/packages/vfx/shaders/advanced-metallic-paint-shader-53153 -flake attenuation


https://assetstore.unity.com/packages/vfx/shaders/directx-11/pro-car-paint-shader-102063#content

da sa prezriet suborova struktura toho assetu a vsetky nemaju priamo vlastny "Lit.shader", urcite ale v tych svojich implementaciach nejako importuju/dosadzuju do toho pipelinu svoje modifikacie.   

nejake nezotriedene linky
 How to Create a Custom PBR Lit Shader for Unity's Universal Render Pipeline in HLSL, No ShaderGraph - celkom dobre URP: https://www.youtube.com/watch?v=3TULxrZCAdM  
pre HDRP, mozno zastarale:
https://www.youtube.com/watch?v=q9X0Te0bU9A a https://github.com/Paltoquet/HDRPCustomShader  a https://forum.unity.com/threads/hdrp-custom-shaders-examples.678931/
https://forum.unity.com/threads/hdrp-custom-shaders.521102/ 

sice na toto som prisiel aj ja sam ale pomocka na hladanie kde je frag a vert:
https://forum.unity.com/threads/where-can-i-find-the-source-code-of-the-vert-and-frag-in-hdrp-lit-shader.1409265/

trocha diskusie o AxF
https://forum.unity.com/threads/what-is-the-axf-shader.616828/

debugger pomocka
https://docs.unity.cn/Packages/com.unity.render-pipelines.high-definition@12.0/manual/Render-Pipeline-Debug-Window.html

https://github.com/Unity-Technologies/MeasuredMaterialLibraryHDRP Verified in Unity 2019.3.14f1 using HDRP 7.3.1

https://forum.unity.com/threads/i-cant-figure-out-how-to-get-the-clear-coat-working-with-hdrp-lit-and-stacklit-shader-graphs.1335131/

random https://dassaultsystemes-technology.github.io/EnterprisePBRShadingModel/spec-2022x.md.html
co je vlastne specular color v stacklite https://forum.unity.com/threads/stacklit-shader-and-specular-color.1166234/

https://forum.unity.com/threads/what-is-stacklit.798972/

linky na sigggraph a bencour  https://forum.unity.com/threads/how-does-clear-coat-work-in-hdrp.556153/
https://belcour.github.io/blog/ a aj ostatnych unity clenov https://unity-grenoble.github.io/website/index.html