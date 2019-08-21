# I.C.Y

##### *Preserving genetic diversity by helping practitioners make informed decisions when selecting individuals for reintroduction*



<img src="../Images/logo.png" style="zoom:70%" />



### **<u>What</u>**

I.C.Y stands for **I** **C**hoose **Y**ou and is designed to help practitioners choose which animals are suitable for translocation/reintroduction/genetic rescue based on their theoretical genetic diversity. This web app will provide you with the best available group of individuals based on the input parameters (**number of males, number of females, relatedness threshold**). A downloadable report is also available which will provide a more thorough explanation about how ICY works and provides more information about the individuals within a given population. Users interested in the source code can find ICY on Github here: https://github.com/Mills33/ICY-I-Choose-You-

### **<u>Why</u>**

Zoos and captive breeding programmes are playing an increasingly active role in conservation. The aim of many of these programmes is to be able to provide individuals to help recover and support endangered wild populations. Introducing animals into the wild from captivity can be a lengthy and complicated process with practitioners having to consider a variety of factors ranging from the bureaucratic to the biological.

One of the factors to be considered, should be the genetic diversity and  levels of inbreeding in the individuals selected for reintroduction. However often practitioners do not have access to current genetic data or the expertise to be able to interpret such data. A few projects have some form of pedigree data for the wild population as well as the captive one and can use this data to infer which individuals may be better to reintroduce than others. However some projects have none of these data and in such cases the individuals chosen for reintroduction may be picked almost blind. 

One data type common to almost all projects is the presence of studbook data this data contains information that can be used to calculate a measure of theoretical genetic diversity for each individual in the population. Using this metric (called founder equivalents) groups of individuals can be selected which are as diverse as possible whilst not being related ( the precise relatedness threshold is up to the user and may depend on how inbred the population is).

ICY was designed to be quick and easy for practitioners to use to provide them with good choices based on the theoretical genetic diversity of individuals within the population that could be considered for translocation/reintroduction/genetic rescue. It is aimed at practitioners who do not have any empirical genetic data in particular if they have little to no information on the recipient wild population. Whilst ICY , may not give the optimal result and does not consider pragmatic considerations ( those are up to the practitioners) it should result in genetically healthier decisions than choosing blindly.

### **<u>How</u>**

ICY takes as input three csv files all readily available to download from  studbook software such as Sparks or PmX. See the tab **'How to. . .'** above to make sure the correct files are generated. ICY then uses Python functions to format the data and calculates the number of founder equivalents (Fe) per individual and ranks birds based on Fe and mean kinship coefficient (MK). Finally given the three input parameters (**number of males, number of females, relatedness threshold**) it will calulcate a group (where the group size is equal to number of males + number females specified) of individuals which are the highest ranked individuals that are all less related than the specified relatedness threshold. The methods employed by ICY are deisgned to maximise geentic diversity and help prevent inbreeding. 

Important to note just because ICY suggests a group of individuals does not necessarily mean these are the best individuals for reintroduction/translocation. This because there are many other pragmatic considerations such as age, location, health that may be relevant that ICY does not consider. Many pragmatic decisions can be thought through before generating the data for ICY (for example age) so that the input data only contains a subset of individuals from the whole population deemed most appropriate by the user. Ultimately the decision of which individuals to reintroduce belongs to the practitioners, ICY is designed to provide an easy way for users to integrate genetic health into their decisions in the hope of promoting healthier and more stable populations.

### **<u>Trouble?</u>** 

Please read the FAQs (below) and if they do not help please contact Camilla Ryan (camilla.ryan@earlham.ac.uk) with your question or error message.

#### **FAQs**

1. **Error**: index 0 is out of bounds for axis 0 with size 0 - this means it is not possible to have the number or males and number of females at the threshold you have set because they are all more related than that threshold. To solve this you can try decreasing the threshold (*ie* increasing the allowed realtedness between individuals in a group) or try decreasing either the number or males and/or the number of females.