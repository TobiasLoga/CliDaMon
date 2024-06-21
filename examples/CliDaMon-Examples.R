
myClimateData_PostCodes <-
  as.data.frame (clidamonger::tab.stationmapping)
# Name of the original table is misleading --> better to be changed
# (also in the Excel workbook)

myClimateData_StationTA <-
  as.data.frame (clidamonger::list.station.ta)

myClimateData_TA_HD <-
  data.frame (
    clidamonger::data.ta.hd,
    row.names = clidamonger::data.ta.hd$ID_Data
  )

myClimateData_Sol <-
  as.data.frame (clidamonger::data.sol)

myParTab_SolOrientEst <-
  as.data.frame (clidamonger::tab.estim.sol.orient)


Indicator_Type_LocationBuilding <- 1
# Type of input for locating the building and assigning weather stations
# 1: by post code, 2: by weather station

Indicator_Type_AssignStationToPostcode <- 2
# In case of Indicator_Type_LocationBuilding == 1 (postcode): Use the ...
# 1: the closest, 2: the three closest stations (weighted by reciprocal distance)

PostCode <- "13469"
# Input of the postcode, used when
# Indicator_Type_LocationBuilding == 1 (postcode)

Code_ClimateStation <- "917"
# ID of the climate station "ID_Station"
# (first column of table "List.Station.TA")

Indicator_ExcludeSelectedStation <- 0
# 0: Do not exclude = standard entry
# 1: Exclude the selected station ID in the search
# of the three nearest stations / Only useful for test purposes

Month_Start <- "7"
# Index of the first month of the considered period

Year_Start <- "2003"
# Year in which the first month of the considered period is located

n_Year <- "12" # additional feature, not included in "Gradtagzahlen.xlsx"
# Number of years to be considered.
# If more than one year is considered, the output quantities will be
# values averaged over all years

Temperature_HDD_Base <- 12 # [°C]
# Specification of the base temperature in degree Celsius
# When the average day temperature is below this base temperature
# the day is counted as heating day

Temperature_HDD_Room <- 20 # [°C]
# Specification of the room temperature in degree Celsius,
# only used for RHDD

Degree_Inclination_Solar <- 45 # arc degree
# Specification of the inclination angle of the inclined surface
# for which the global radiation is estimated

ResultOfFunction <-
  ClimateByMonth (
    myClimateData_PostCodes,
    myClimateData_StationTA,
    myClimateData_TA_HD,
    myClimateData_Sol,
    myParTab_SolOrientEst,
    Indicator_Type_LocationBuilding,
    Indicator_Type_AssignStationToPostcode,
    PostCode,
    Code_ClimateStation,
    Indicator_ExcludeSelectedStation,
    Month_Start,
    Year_Start,
    n_Year = 5,
    Temperature_HDD_Base,
    Temperature_HDD_Room,
    Degree_Inclination_Solar
  )

ResultOfFunction$DF_ClimCalc          # Result for an average year in the period
ResultOfFunction$DF_Evaluation        # Result for all considered months
ResultOfFunction$DF_EvaluationByYear  # Annual values vor all evaluation years
ResultOfFunction$DF_StationInfo       # Meta data of the used weather stations
ResultOfFunction$DF_FunctionArguments # Values of all function arguments
ResultOfFunction$DF_OutputStructure   # Information about output structure

# Main Result (extract / first columns of the resulting dataframe "DF_ClimCalc"):

#          ID Month     D     TA  TA_HD     HD     HDD    RHDD CT   G_Hor    G_E G_E_Inclined   G_SE G_SE_Inclined    G_S G_S_Inclined
# M01     M01     7  31.0 20.287    NaN   0.00    0.00    0.00  1  164.87 119.59       155.45 115.10        173.85  98.25       160.59
# M02     M02     8  31.0 19.028    NaN   0.00    0.00    0.00  1  142.55 103.55       134.20 110.05        153.76 102.15       151.92
# M03     M03     9  30.0 15.890 10.946   2.90    3.10   26.34  1  104.83  76.39        98.39  95.02        118.40  98.62       129.00
# M04     M04    10  31.0 10.269  8.187  19.70   75.07  232.64  1   61.16  44.80        57.09  65.03         74.88  74.43        86.53
# M05     M05    11  30.0  5.900  5.634  28.86  183.73  414.61  1   25.78  19.05        23.85  30.58         35.93  37.66        39.71
# M06     M06    12  31.0  3.262  3.221  30.85  270.87  517.68  1   15.47  11.49        14.25  21.16         23.28  27.45        27.08
# M07     M07     1  31.0  1.816  1.753  30.80  315.62  562.02  1   20.83  15.43        19.24  29.84         29.93  38.71        38.43
# M08     M08     2  28.4  2.522  2.372  27.95  269.07  492.65  1   35.63  26.24        33.09  44.42         47.28  54.70        58.07
# M09     M09     3  31.0  4.938  4.396  29.05  220.93  453.34  1   77.97  56.98        72.96  86.01         92.04  98.44       115.00
# M10     M10     4  30.0 10.468  8.411  20.22   72.57  234.33  1  125.71  91.43       118.20 117.22        138.06 121.66       159.76
# M11     M11     5  31.0 14.878 10.059   7.53   14.64   74.90  1  162.04 117.56       152.75 127.59        171.38 118.44       176.61
# M12     M12     6  30.0 18.214 10.929   1.90    2.08   17.32  1  171.07 124.04       161.34 119.97        179.53 102.40       167.47
# Total Total     0 365.4 10.623  4.853 199.77 1427.68 3025.82  1 1107.92 806.55      1040.81 962.00       1238.32 972.91      1310.16

