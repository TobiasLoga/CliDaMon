# CliDaMon

### Calculate monthly climate data - heating degree days and solar radiation by postcode

The package consists of the function "ClimateByMonth ()" providing monthly climate data 
for buildings' energy performance calculation for a location specified by postcode. 
As a data source tables from the data package clidamonger
"Climate Data Monthly Germany" are used. The temperature and global radiation data
in clidamonger have been measured and published by "DWD - Deutscher Wetterdienst".

The output consists of the following data frames:

- **DF_ClimCalc:**          
    a dataframe containing climate data for 12 months and the complete year.
    If more than one year is evaluated the resulting values of each month
    is the average of this month and the result data of the year
    is an average year.

- **"DF_Evaluation":**        
    a dataframe containing climate data for all considered months.

- **"DF_StationInfo":**       
    a dataframe containing information about the used climate stations.

- **"DF_FunctionArguments":**   
    a dataframe containing the values of all function arguments (one row).

- **"DF_OutputStructure":**   
    a dataframe containing information about the data structure
    of the output (dataframe names and number of column).


---

### Method

A description of the method can be found in

Loga, Tobias & Großklos, Marc & Landgraf, Katrin. (2020). Klimadaten für die Realbilanzierung - Grundlagen des Tools „Gradtagzahlen-Deutschland.xlsx“ - MOBASY-Teilbericht. 10.13140/RG.2.2.25695.28324.

The source code was developed and used in the MOBASY research project (https://www.iwu.de/forschung/energie/mobasy/). 
The package contains roughly the same algorithms as the IWU Excel workbook "Gradtagzahlen-Deutschland.xlsx"
Download at: https://www.iwu.de/publikationen/fachinformationen/energiebilanzen/#c205

How ever the results may slightly differ due to different averaging procedures.  

---

### Usage

```r
library (CliDaMon)

```
---

### License

<a rel="license" href="https://creativecommons.org/licenses/by/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by/4.0/80x15.png" /></a><br />This work is licensed under a <a rel="license" href="https://creativecommons.org/licenses/by/4.0/">Creative Commons Attribution 4.0 International License</a>.

---


### Variables

A description of the input and output variables of the function ClimateByMonth ()
can be found in the help section of the package.

---

### Views

 <a href="https://trackgit.com">
<img src="https://us-central1-trackgit-analytics.cloudfunctions.net/token/ping/m74l4hq2zgsl8hgm7dm7" alt="trackgit-views" />
</a>
