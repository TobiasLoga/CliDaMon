
myClimateData_PostCodes <-
  as.data.frame (clidamonger::tab.stationmapping)
# Name of the original table is misleading --> better to be changed
# (also in the Excel workbook)

myClimateData_StationTA <-
  as.data.frame (clidamonger::list.station.ta)

myClimateData_TA_HD <-
  as.data.frame (clidamonger::data.ta.hd)

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

Month_Start <- "1"
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
ResultOfFunction$DF_StationInfo       # Meta data of the used weather stations
ResultOfFunction$DF_FunctionArguments # Values of all function arguments
ResultOfFunction$DF_OutputStructure   # Information about output structure

# Main Result (extract / first columns of the resulting dataframe "DF_ClimCalc"):
#
#          ID     D     TA  TA_HD     HD     HDD    RHDD      CT   G_Hor    G_E G_E_Inclined    G_SE G_SE_Inclined     G_S
# M01     M01  31.0  0.348  0.267  30.81  361.46  607.91 1.00000   25.89  19.13        23.96   38.24         36.07   49.61
# M02     M02  28.2  0.460  0.441  28.14  325.23  550.32 1.00000   43.16  31.72        40.15   55.42         55.60   68.24
# M03     M03  31.0  4.178  3.337  28.36  245.72  472.62 1.00000   90.92  66.34        85.21  102.59        104.90  117.41
# M04     M04  30.0  9.539  6.761  19.99  104.76  264.70 1.00000  141.98 103.14       133.67  134.79        153.14  139.91
# M05     M05  31.0 12.644  8.339  14.20   51.94  165.51 1.00000  155.20 112.65       146.23  121.31        165.32  112.60
# M06     M06  30.0 16.939  9.277   4.55   12.44   48.87 1.00000  184.90 133.96       174.52  131.23        191.74  112.01
# M07     M07  31.0 18.241 10.192   3.41    6.19   33.49 0.99427  174.39 126.42       164.51  122.69        182.44  104.73
# M08     M08  31.0 17.024 10.200   4.55    8.15   44.52 0.95036  146.12 106.11       137.60  113.30        156.94  105.18
# M09     M09  30.0 14.197  9.405   9.05   23.48   95.88 0.99332  112.46  81.89       105.63  103.05        125.66  106.95
# M10     M10  31.0  9.032  7.401  23.10  106.27  291.10 0.99427   66.66  48.79        62.28   71.79         80.59   82.17
# M11     M11  30.0  4.412  4.274  29.51  227.99  464.07 1.00000   29.09  21.47        26.95   35.13         39.83   43.25
# M12     M12  31.0  1.146  1.136  30.76  334.14  580.19 0.99427   20.53  15.21        18.96   29.29         29.62   38.00
# Total Total 365.2  9.013  4.016 226.42 1807.76 3619.15 0.99387 1191.30 866.85      1119.67 1058.83       1321.85 1080.05
