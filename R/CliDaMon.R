#####################################################################################X
##
##    File name:        "CliDaMon.R"
##
##    Module of:        "EnergyProfile.R"
##
##    Task:             Climate data by month
##                      Estimate monthly heating degree days and solar radiation
##                      by use of building localisation (postcode)
##                      Currently working only with data from Germany (package clidamonger)
##
##    Method:           MOBASY real climate
##                      (https://www.iwu.de/forschung/energie/mobasy/)
##
##    Project:          MOBASY
##
##    Author:           Tobias Loga (t.loga@iwu.de)
##                      IWU - Institut Wohnen und Umwelt, Darmstadt / Germany
##
##    Created:          22-04-2022
##    Last changes:     14-07-2023
##
#####################################################################################X
##
##    R-Script derived from
##    > Excel workbook "EnergyProfile.xlsm" sheet "Data.out.TABULA"
##    > Excel workbook "Gradtagzahlen-Deutschland.xlsx"
##
#####################################################################################X

# renv::init()
# renv::status()
# renv::install (packages = "TobiasLoga/AuxFunctions")
# renv::snapshot()


#####################################################################################X
## FUNCTION "ClimateByMonth ()" -----
#####################################################################################X


#' @title Calculate monthly climate data - heating degree days and solar radiation by postcode
#'
#' @description
#' Monthly and annual climate data are provided for specific periods
#' allocated to German postcode zone. The climate data can be used to calulate
#' the energy demand for space heating. Temperature and solar radiation during heating days
#' as well as degree days are provided for specific base temperatures (10°C, 12°C, and 15°C).
#'
#' As a data source tables from the data package clidamonger
#' "Climate Data Monthly Germany" are used. The temperature and global radiation data
#' in clidamonger have been measured and published by "DWD - Deutscher Wetterdienst".
#' More information about the data sources can be found in the
#' IWU Excel workbook "Gradtagzahlen-Deutschland.xlsx"
#' Download at: https://www.iwu.de/publikationen/fachinformationen/energiebilanzen/#c205
#' The procedures of this package are similar to those of the Excel workbook but not identical.
#'
#' @param myClimateData_Postcodes a dataframe from the data package clidamonger
#' containing all German postcodes (variable "ID_Location_StationMapping",
#' example: "DE.PC.01.64295" for the postcode 64295)
#' and their geographical coordinates (variables "Latitude" and "Longitude").
#' The dataframe can be assigned as a function parameter by the statement:
#' as.data.frame (clidamonger::tab.stationmapping)
#'
#' @param myClimateData_StationTA a dataframe from the data package clidamonger
#' containing the geographical coordinates (variables "Latitude" and "Longitude") of the
#' climate stations included in the database, identified by its serial number
#' (variable "ID_Station").
#' The dataframe can be assigned as a function parameter by the statement:
#' as.data.frame (clidamonger::list.station.ta)
#'
#' @param myClimateData_TA_HD a dataframe from the data package clidamonger
#' containing monthly temperature data of German weather stations
#' The column names identifying the months have the format "M_2022_01" (= January 2022).
#' The codes of the row names (example: "DE.MET.000917.TA_12") give information about the
#' serial number of the climate station (917) and the type of data value in the row
#' ("TA_12" = average monthly air temperature during heating days, average temperature of the
#' day below base temperature 12°C).
#' Data content of the dataframe:
#'   By month and by DWD climate station:
#'   average external air temperature (TA) in °C;
#'   for specific base temperatures: heating and cooling days
#'       (HD_10, HD_12, HD_15, CD_18, CD_20, CD_22);
#'   external air temperature during heating and during cooling days
#'       (TA_10, TA_12, TA_15, TAc_18, TAc_20, TAc_22).
#' The dataframe can be assigned as a function parameter by the statement:
#' as.data.frame (clidamonger::data.ta.hd)
#'
#' @param myClimateData_Sol a dataframe from the data package clidamonger
#' containing average monthly shortwave radiation data by geographical coordinates.
#' The column names identifying the months have the format "M_2022_01" (= January 2022).
#' The codes of the row names (example: "DE.MET.lat450.lon050.I_Hor") give information about the
#' latitude (example: 45.0 degrees) and longitude (example: 5.0 degrees).
#' Data content of the dataframe:
#'   By geographical coordinates for Germany (latitude and longitude distances 0.02°):
#'   average shortwave radiation on horizontal surfaces (I_Hor) in W/m², listed by coordinates.
#' The dataframe can be assigned as a function parameter by the statement:
#' as.data.frame (clidamonger::data.sol)
#'
#' @param myParTab_SolOrientEst a dataframe from the data package clidamonger
#' containing empirically derived parameters for the data transformation.
#' A documentation of the estimation method can be found in the MOBASY report:
#' "Klimadaten für die Realbilanzierung. Grundlagen des Tools 'Gradtagzahlen-Deutschland.xlsx'".
#' available at: https://www.iwu.de/fileadmin/publikationen/energie/mobasy .
#' Data content of the dataframe:
#'   By orientation and inclination: parameters for estimating the solar radiation
#'   for vertical and inclined surfaces on the basis of horizontal radiation data.
#' The dataframe can be assigned as a function parameter by the command:
#' as.data.frame (clidamonger::tab.estim.sol.orient)
#'
#' @param Indicator_Type_LocationBuilding an (optional) integer indicating the type of
#' input for locating the building and assigning weather stations.
#' Signification of the argument:
#'   1: by postcode;
#'   2: by weather station;
#' default value: 1.
#'
#' @param Indicator_Type_AssignStationToPostcode an (optional) integer indicating the method
#' to assign weather stations to post codes.
#' Signification of the argument:
#'   1: Use the the closest station;
#'   2: Use the three closest stations (weighted by reciprocal distance);
#' default value: 2.
#' This argument is only used if Indicator_Type_LocationBuilding == 1 (postcode).
#'
#' @param PostCode an (optional) character string indicating the 5 digits of the German postcode.
#' This argument is only used if Indicator_Type_LocationBuilding == 1 (weather station)
#'
#' @param Code_ClimateStation an (optional) character string or number indicating the
#' ID of the climate station "ID_Station" (first column of dataframe myClimateData_StationTA).
#' Default station: Potsdam Code_ClimateStation = "3987".
#' This argument is only used if Indicator_Type_LocationBuilding == 2 (postcode)
#'
#' @param Indicator_ExcludeSelectedStation an (optional) integer used to exclude
#' the selected station.
#' Signification of the argument:
#'   0: Do not exclude ...
#'   1: Exclude ...
#'   ... the selected station ID in the search of the three nearest stations.
#'   Default value: 0.
#'   Only useful for research and development purposes.
#'
#' @param Month_Start an (optional) integer indicating the first month of the considered period;
#' default value: 1.
#'
#' @param Year_Start an integer indicating the year in which
#' the first month of the considered period is located.
#'
#' @param n_Year an (optional) number of years to be considered.
#' If more than one year is considered, the output quantities will be
#' values averaged or summed upt over all years (additional feature,
#' not included in "Gradtagzahlen.xlsx").
#' Default value: 1.
#'
#' @param Temperature_HDD_Base an (optional) integer indicating the base temperature
#' in degree Celsius. When the average day temperature is below this base temperature
#' the day is counted as heating day.
#' Possible values: 10, 12, 15 [°C];
#' default value: 15 [°C].
#'
#' @param Temperature_HDD_Room an (optional) integer indicating the room temperature
#' in degree Celsius, used for calculating the room heating degree days RHDD.
#' Default value: 20 [°C].
#'
#' @param Degree_Inclination_Solar an (optional) integer indicating the inclination angle
#' of the inclined surface for which the global radiation is estimated.
#' Possible values: 0, 30, 45, 60, 90 [°] (arc degree).
#' Default value: 45 [°] (arc degree).
#'
#' @return A list of 5 dataframes:
#'
#' DF_ClimCalc:          a dataframe containing climate data for 12 months and the complete year.
#'                       If more than one year is evaluated the resulting values of each month
#'                       is the average of this month and the result data of the year
#'                       is an average year.
#'
#' DF_Evaluation:        a dataframe containing climate data for all considered months.
#'
#' DF_EvaluationByYear:  a dataframe containing annual data for all considered evaluation years.
#'
#' DF_StationInfo:       a dataframe containing information about the used climate stations.
#'
#' DF_FunctionArguments: a dataframe containing the values of all function arguments (one row).
#'
#' DF_OutputStructure:   a dataframe containing information about the data structure
#'                       of the output (dataframe names and number of column).
#'
#' @example examples/CliDaMon-Examples.R
#'
#' @export
ClimateByMonth <- function (

  # Tables from  data package: "clidamonger" "Climate Data Monthly Germany"
  myClimateData_PostCodes,
  myClimateData_StationTA,
  myClimateData_TA_HD,
  myClimateData_Sol,
  myParTab_SolOrientEst,

  Indicator_Type_LocationBuilding = 1,
      # Type of input for locating the building and assigning weather stations
      # 1: by post code, 2: by weather station

  Indicator_Type_AssignStationToPostcode = 2,
      # In case of Indicator_Type_LocationBuilding == 1 (postcode): Use the ...
      # 1: the closest, 2: the three closest stations (weighted by reciprocal distance)

  PostCode = NA,
      # A character string indicating the 5 digits of the German postcode, used when
      # Indicator_Type_LocationBuilding == 1 (postcode)

  Code_ClimateStation = "3987", # Default station: Potsdam
      # ID of the climate station "ID_Station"
      # (first column of table "List.Station.TA")

  Indicator_ExcludeSelectedStation = 0,
      # 0: Do not exclude = standard entry
      # 1: Exclude the selected station ID in the search
      # of the three nearest stations / Only useful for test purposes

  #2023-02-10 Not yet implemented
  # Indicator_ApplyHeightCorrection	= FALSE,
  #     # Apply a simple height correction for the temperature.
  #     # Input in "Altitude_Building" is needed then.
  #
  # Altitude_Building = NA,
  #     # Altitude of the building in m,
  #     # Used for a simple height correction for the temperature.

  Month_Start = 1,
      # Index of the first month of the considered period

  Year_Start = NA,
      # Year in which the first month of the considered period is located

  n_Year = 1, # additional feature, not included in "Gradtagzahlen.xlsx"
      # Number of years to be considered.
      # If more than one year is considered, the output quantities will be
      # values averaged over all years

  # # 2023-02-10 Not yet implemented
  # Index_TypeConditioning = 1,
  #     # Type of the conditioning to be considered
  #     # 1: Heating, 2: Cooling

  Temperature_HDD_Base = 15, # [°C]
      # Specification of the base temperature in degree Celsius
      # When the average day temperature is below this base temperature
      # the day is counted as heating day

  Temperature_HDD_Room = 20, # [°C]
      # Specification of the room temperature in degree Celsius,
      # used RHDD

  Degree_Inclination_Solar = 45 # arc degree
      # Specification of the inclination angle of the inclined surface
      # for which the global radiation is estimated

) {


  ###################################################################################X
  # 1 PREPARATION  -----
  ###################################################################################X

  ###################################################################################X
  ## 1.1 Constants  -----


  ## Scaling of degrees for determination of distance
  Coefficient_Latitude_km_per_Degree <- 111.13 # km per degree latitude
  Coefficient_Longitude_km_per_Degree <- 71.44 # km per degree longitude

  ## Constant used in the formula to estimate the global radiation during heating days
  ## from the monthly global radiation
  p_Sol_HD <- 0.19
  # Value determined by parameter study,
  # see MOBASY report "Klimadaten für die Realbilanzierung"


  ## ID of a default temperature station
  ID_TemperatureData_Station_Default <-
    "DE.MET.003987" # default station: Potsdam

  ## Completeness criterion for proximity
  MinimumCriterion_Completeness <- 0.8
  # The completeness factor of all monthly tempeature values
  # must not below this criterion.
  # Otherwise the dataset is omitted in the proximity calculation.

  ## Decimal places of the result values
  n_Decimal_TA <- 3 # External temperature
  n_Decimal_HD <- 2 # Number of heating days
  n_Decimal_CT <- 5 # Completeness indicator
  n_Decimal_G  <- 2 # Global radiation


  ###################################################################################X
  ## 1.2 Transform input values  -----

  n_Station_Consider <-
    if (Indicator_Type_LocationBuilding == 2) { # Use of the weather station ID
      if (Indicator_ExcludeSelectedStation == 1) { # selected station excluded
        3   # Only for test purposes, the calculation is performed
            # by use of the three stations which are closest to the selected station
      } else {
        1   # Standard case
      }
    } else { # Use of the postal code
      if (Indicator_Type_AssignStationToPostcode == 2)  {
        3
      } else {
        1
      }
    }

  n_Year_Evaluation <- as.integer (n_Year)
  n_EvaluationMonths <- n_Year_Evaluation * 12


  ###################################################################################X
  ## 1.3 Prepare the evaluation data frame "DF_Evaluation"  -----

  ColNames_EvalDF <-
    c(
      "ID",
      "Index_EvalYear",
      "Index_EvalMonth",
      "Year",
      "Month",
      "D",
      "CT.Input.01",
      "CT.Input.02",
      "CT.Input.03",
      "CT",
      "TA.Input.01",
      "TA.Input.02",
      "TA.Input.03",
      "TA",
      "HD.Input.01",
      "HD.Input.02",
      "HD.Input.03",
      "HD",
      "TA_HD.Input.01",
      "TA_HD.Input.02",
      "TA_HD.Input.03",
      "TA_HD",
      "HDD",
      "RHDD",
      # "TA_HCorr", # "HCorr" = height corrected, not yet implemented
      # "TA_HD_HCorr",
      # "HD_HCorr",
      # "HDD_HCorr",
      # "RHDD_HCorr",
      "I_Hor.Input",
      "G_Hor",
      "G_E",
      "G_E_Inclined",
      "G_SE",
      "G_SE_Inclined",
      "G_S",
      "G_S_Inclined",
      "G_SW",
      "G_SW_Inclined",
      "G_W",
      "G_W_Inclined",
      "G_NW",
      "G_NW_Inclined",
      "G_N",
      "G_N_Inclined",
      "G_NE",
      "G_NE_Inclined",
      "f_Sol_HD",
      "G_Hor_HD",
      "G_E_HD",
      "G_E_Inclined_HD",
      "G_SE_HD",
      "G_SE_Inclined_HD",
      "G_S_HD",
      "G_S_Inclined_HD",
      "G_SW_HD",
      "G_SW_Inclined_HD",
      "G_W_HD",
      "G_W_Inclined_HD",
      "G_NW_HD",
      "G_NW_Inclined_HD",
      "G_N_HD",
      "G_N_Inclined_HD",
      "G_NE_HD",
      "G_NE_Inclined_HD"
    )

  n_Col_EvalDF <-
    length (ColNames_EvalDF)

  RowNames_EvalDF <-
    AuxFunctions::Format_Integer_LeadingZeros (1:n_EvaluationMonths, 4, "EM_")

  myDF_Evaluation <-
    as.data.frame (
      cbind (RowNames_EvalDF,
             matrix (NA,
                     nrow = n_EvaluationMonths,
                     ncol = n_Col_EvalDF - 1)
      ),
      row.names = RowNames_EvalDF
    )

  colnames (myDF_Evaluation) <- ColNames_EvalDF

  for (i_Year in 1:n_Year_Evaluation) {
    myDF_Evaluation$Index_EvalYear [(i_Year-1) * 12 + (1:12)] <-
      rep (i_Year, times=12)
  }
  myDF_Evaluation$Index_EvalYear <-
    as.numeric (myDF_Evaluation$Index_EvalYear)

  myDF_Evaluation$Index_EvalMonth <-
    rep (1:12, times = n_Year_Evaluation)


  ###################################################################################X
  ## 1.4 Prepare the station info data frame "myDF_StationInfo" -----

  ## containing station metadata

  StationInfoColNames <-
    c(
      "ID",
      "Index_StationTable",
      "Code_Station",
      "ID_Station",
      "Name_DataSource",
      "Date_Start_DataBase",
      "Date_End_DataBase",
      "Latitude",
      "Longitude",
      "Altitude",
      "Name_Station",
      "Name_Region_Station",
      "ReciprocalDistance",
      "Factor_Weighting",
      "Factor_Consider"
    )

  n_Col_DF_StationInfo <-
    length (StationInfoColNames)

  StationInfoRowNames <- # average values per year for the considered period
    c(
      "Station.1",
      "Station.2",
      "Station.3"
    )

  n_Row_DF_StationInfo <-
    length (StationInfoRowNames)

  myDF_StationInfo <-
    as.data.frame (
      cbind (StationInfoRowNames,
             matrix (NA,
                     nrow = n_Row_DF_StationInfo,
                     ncol = n_Col_DF_StationInfo - 1)
      ),
      row.names = StationInfoRowNames
    )

  colnames (myDF_StationInfo) <-
    StationInfoColNames


  ###################################################################################X
  ## 1.5 Prepare the output data frame "DF_ClimCalc"  -----

  ClimCalcColNames <-
    c(
      "ID",
      "Month", # 2023-12-08: supplemented
      "D",
      "TA",
      "TA_HD",
      "HD",
      "HDD",
      "RHDD",
      "CT",
      "G_Hor",
      "G_E",
      "G_E_Inclined",
      "G_SE",
      "G_SE_Inclined",
      "G_S",
      "G_S_Inclined",
      "G_SW",
      "G_SW_Inclined",
      "G_W",
      "G_W_Inclined",
      "G_NW",
      "G_NW_Inclined",
      "G_N",
      "G_N_Inclined",
      "G_NE",
      "G_NE_Inclined",
      "G_Hor_HD",
      "G_E_HD",
      "G_E_Inclined_HD",
      "G_SE_HD",
      "G_SE_Inclined_HD",
      "G_S_HD",
      "G_S_Inclined_HD",
      "G_SW_HD",
      "G_SW_Inclined_HD",
      "G_W_HD",
      "G_W_Inclined_HD",
      "G_NW_HD",
      "G_NW_Inclined_HD",
      "G_N_HD",
      "G_N_Inclined_HD",
      "G_NE_HD",
      "G_NE_Inclined_HD"
    )

  n_Col_DF_ClimCalc <-
    length (ClimCalcColNames)

  ClimCalcRowNames <- # average values per year for the considered period
    c(
      "M01",
      "M02",
      "M03",
      "M04",
      "M05",
      "M06",
      "M07",
      "M08",
      "M09",
      "M10",
      "M11",
      "M12",
      "Total"
    )

  n_Row_DF_ClimCalc <-
    length (ClimCalcRowNames)

  myDF_ClimCalc <-
    as.data.frame (
    cbind (ClimCalcRowNames,
           matrix (NA,
                   nrow = n_Row_DF_ClimCalc,
                   ncol = n_Col_DF_ClimCalc - 1)
           ),
    row.names = ClimCalcRowNames
    )

  colnames (myDF_ClimCalc) <-
    ClimCalcColNames


  ###################################################################################X
  ## 1.6  Assign values to auxiliary variables  -----

  CalcInfo <- as.data.frame (
    matrix (nrow = 1, ncol = 3),
    )
  colnames (CalcInfo) <- c (
    "Status_ColEvalMonthsTA_Existing",
    "Status_ColEvalMonthsSol_Existing",
    "Status_ColEvalMonthsExisting"
  )

  myClimateData_StationTA$Code_Station <-
    AuxFunctions::Format_Integer_LeadingZeros(
      myClimateData_StationTA$ID_Station,
      6,
      "DE.MET."
    )

  row.names (myClimateData_StationTA) <-
    myClimateData_StationTA$Code_Station

  n_Row_Data_StationTA <-
    nrow (myClimateData_StationTA)

  n_Col_Data_TA_HD <-
    ncol (myClimateData_TA_HD)


  ###################################################################################X
  ## 1.7  Identify the data columns to be evaluated  -----

  ColIndex_Start_Data_TA_HD <-
    which (colnames (myClimateData_TA_HD) ==
             paste0 ("M_",
                     Year_Start, "_",
                     AuxFunctions::Format_Integer_LeadingZeros (
                       as.numeric(
                         Month_Start
                       ),
                       2)
             )
         )

  ColIndex_Start_Data_Sol <-
    which (colnames (myClimateData_Sol) ==
             paste0 ("M_",
                     Year_Start, "_",
                     AuxFunctions::Format_Integer_LeadingZeros (
                       as.numeric (
                         Month_Start
                       )  , 2)
             )
    )

  ## If the evaluation months cannot be found in the dta frame myClimateData_TA_HD
  ## the long term averages are used

  CalcInfo$Status_ColEvalMonthsTA_Existing <-
    ifelse  (identical (ColIndex_Start_Data_TA_HD, integer(0)),
             0,
             ifelse (ncol (myClimateData_TA_HD) <
                       ColIndex_Start_Data_TA_HD + n_EvaluationMonths - 1,
                     0,
                     1
             )
    )

  CalcInfo$Status_ColEvalMonthsSol_Existing <-
    ifelse  (identical (ColIndex_Start_Data_Sol, integer(0)),
             0,
             ifelse (ncol (myClimateData_Sol) <
                       ColIndex_Start_Data_Sol + n_EvaluationMonths - 1,
                     0,
                     1
             )
    )

  CalcInfo$Status_ColEvalMonthsExisting <-
    CalcInfo$Status_ColEvalMonthsTA_Existing *
    CalcInfo$Status_ColEvalMonthsSol_Existing

  ColIndex_Start_Data_TA_HD <-
    ifelse  (CalcInfo$Status_ColEvalMonthsExisting == 0,
      which (colnames (myClimateData_TA_HD) == "M_LTA_01"),
      ColIndex_Start_Data_TA_HD
  )

  ColIndex_Start_Data_Sol <-
    ifelse  (CalcInfo$Status_ColEvalMonthsExisting == 0,
             which (colnames (myClimateData_Sol) == "M_LTA_01"),
             ColIndex_Start_Data_Sol
    )

  n_EvaluationMonths <-
    ifelse  (CalcInfo$Status_ColEvalMonthsExisting == 0,
           12,
           n_EvaluationMonths
  )

  ## Define the list of columns to be evaluated

  ColIndices_Data_TA_HD <-
    ColIndex_Start_Data_TA_HD:(
      ColIndex_Start_Data_TA_HD + n_EvaluationMonths - 1)

  ColNames_Data_TA_HD <-
    colnames (
      myClimateData_TA_HD [ ,
                            ColIndices_Data_TA_HD]
    )

  ColIndices_Data_Sol <-
    ColIndex_Start_Data_Sol :(
      ColIndex_Start_Data_Sol + n_EvaluationMonths -1)

  ColNames_Data_Sol <-
    colnames (
      myClimateData_Sol [ ,
                            ColIndices_Data_Sol]
    )





  ###################################################################################X
  # 2  TEMPERATURE DATA  -----
  ###################################################################################X

  ###################################################################################X
  ## 2.1 Determine the geographical coordinates of the post code   -----

  if (Indicator_Type_LocationBuilding == 2) { # Direct input of station ID

    ID_ClimateData_PostCode <-
      "-"

    ID_Station_Input <-
    AuxFunctions::Format_Integer_LeadingZeros (
      as.numeric (Code_ClimateStation),
      6,
      "DE.MET."
    )

    Latitude_Mapping_Location <-
      AuxFunctions::Replace_NA (
        AuxFunctions::Value_ParTab (
          myClimateData_StationTA,
          ID_Station_Input,
          'Latitude'
        ),
        -999999
      )

    Longitude_Mapping_Location <-
      AuxFunctions::Replace_NA (
        AuxFunctions::Value_ParTab (
          myClimateData_StationTA,
          ID_Station_Input,
          'Longitude'
        ),
        -999999
      )

    Altitude_Mapping_Location <-
      AuxFunctions::Replace_NA (
        AuxFunctions::Value_ParTab (
          myClimateData_StationTA,
          ID_Station_Input,
          'Altitude'
        ),
        -999999
      )


  } else {  # Use of post code

    ID_ClimateData_PostCode <-
      paste0 ("DE.PC.01.",
              AuxFunctions::xl_TEXT (PostCode, "00000") )

    Latitude_Mapping_Location <-
      AuxFunctions::Replace_NA (
        AuxFunctions::Value_ParTab (
          myClimateData_PostCodes,
          ID_ClimateData_PostCode,
          'Latitude'
        ),
        -999999
      )

    Longitude_Mapping_Location <-
      AuxFunctions::Replace_NA (
        AuxFunctions::Value_ParTab (
          myClimateData_PostCodes,
          ID_ClimateData_PostCode,
          'Longitude'
        ),
        -999999
      )

    # The altitude values are not yet included in the post code table
    # If these are inlcuded later a height correction might be implemented
    Altitude_Mapping_Location <-
      AuxFunctions::Replace_NA (
        AuxFunctions::Value_ParTab (
          myClimateData_PostCodes,
          ID_ClimateData_PostCode,
          'Altitude'
        ),
        -999999
      )

  } # End else





  ###################################################################################X
  ## 2.2 Find for the given post code the 3 closest weather stations  -----

  # Principle:
  # As a basis for the procedure serves the dataframe "myClimateData_StationTA"
  # extracted from the table "Data.TA.HD" in "Gradtagzahlen-Deutschland.xlsx".
  #
  # The three closest station are identified by the following scheme
  # (1) Check for all stations (rows of "myClimateData_StationTA")
  #     if the LTA period (the last 20 years) is within the time span
  #     with available data from this station
  # (2) Determine for all stations the proximity to the location of the building
  #     which is the reciprocal distance determined from geo coordinates
  # (3) In the dataframe containing the measured temperature data
  #     ("myClimateData_TA_HD") a completeness indicator can be found for
  #     the 12 LTA columns of all datasets. Determine for all stations the
  #     minimum of the 12 values. If this is below the criterion defined by
  #     the constant MinimumCriterium_LTA_Completeness the dataset will not be
  #     considered.
  # (4) Determine the stations with the three highest proximity values
  #     for which also the period matches and the completeness criterion is fulfilled.
  # (5) Determine the weighting factors for each station by dividing its proximity
  #     by the sum of the three proximity values (after the loop by building).



  # Check which datasets provide values for the 20 years period between
  # Year_PeriodStart_DataTA_LTA and Year_PeriodEnd_DataTA_LTA.
  # Only those datasets will be considered when searching the three closest stations



  ## 2023-01-28 - Concept changed, now only evaluation of periods in M columns
  ##

  # myClimateData_StationTA$Indicator_MatchStation_StartDate <-
  #   paste0 (Year_PeriodStart_DataTA_LTA, "-01-01")  >=
  #   myClimateData_StationTA$Date_Start_DataBase
  #
  # myClimateData_StationTA$Indicator_MatchStation_EndDate <-
  #   paste0 (Year_PeriodEnd_DataTA_LTA, "-12-31")  <=
  #   myClimateData_StationTA$Date_End_DataBase


  ## Supplement several evaluation columns in the climate data table

  ## Assign the average completeness in the period
  myClimateData_StationTA$Completeness_Period <-
    apply (
      myClimateData_TA_HD [
        paste0 (
          myClimateData_StationTA$Code_Station,
          ".CT"),
        ColIndices_Data_TA_HD
      ] ,
      1,
      "mean"
    )

  myClimateData_StationTA$Indicator_MatchStation_Completeness <-
    AuxFunctions::Replace_NA (
      myClimateData_StationTA$Completeness_Period >=
        MinimumCriterion_Completeness,
      FALSE
    )
  # The completeness factor of the 12 LTA values must not below this criterion.
  # Otherwise the dataset is omitted in the proximity calculation

  # myClimateData_StationTA$Completeness_Period [myClimateData_StationTA$ID_Station == 5300]
  # myClimateData_StationTA [myClimateData_StationTA$ID_Station == 5300 , ]


  myClimateData_StationTA$Factor_Proximity <-
    # ifelse (myClimateData_StationTA$Indicator_MatchStation_Completeness &
    #           myClimateData_StationTA$Indicator_MatchStation_StartDate &
    #           myClimateData_StationTA$Indicator_MatchStation_EndDate,
    #         1,
    #         0) *
    round (
      1000 *
        1 / sqrt (
          ((
            Latitude_Mapping_Location  -
              myClimateData_StationTA$Latitude
          ) *
            Coefficient_Latitude_km_per_Degree
          ) ^ 2 +
            ((
              Longitude_Mapping_Location  -
                myClimateData_StationTA$Longitude
            ) *
              Coefficient_Longitude_km_per_Degree
            ) ^ 2
        )
    ,2)

  myDF_StationInfo$Index_StationTable <- NA

  myDF_StationInfo$Index_StationTable [1] <-
    which.max (
      # myClimateData_StationTA$Indicator_MatchStation_StartDate *
      #   myClimateData_StationTA$Indicator_MatchStation_EndDate *
        myClimateData_StationTA$Indicator_MatchStation_Completeness *
        myClimateData_StationTA$Factor_Proximity
    )

  myDF_StationInfo$Factor_Consider [1] <- 1

  if (((Indicator_Type_LocationBuilding == 1) &&  # by postcode AND
      (n_Station_Consider == 3)) ||          # closest 3 stations
      ((Indicator_Type_LocationBuilding == 2) &&  # by station ID AND
       (Indicator_ExcludeSelectedStation == 1)) ) {   # use the 3 closest ()

    myDF_StationInfo$Index_StationTable [2] <-
      which.max (
        # myClimateData_StationTA$Indicator_MatchStation_StartDate *
        #   myClimateData_StationTA$Indicator_MatchStation_EndDate *
          myClimateData_StationTA$Indicator_MatchStation_Completeness *
          myClimateData_StationTA$Factor_Proximity *
          ((1 : nrow (myClimateData_StationTA)
          ) != myDF_StationInfo$Index_StationTable [1])
      )

    myDF_StationInfo$Index_StationTable [3] <-
      which.max (
        # myClimateData_StationTA$Indicator_MatchStation_StartDate *
        #   myClimateData_StationTA$Indicator_MatchStation_EndDate *
          myClimateData_StationTA$Indicator_MatchStation_Completeness *
          myClimateData_StationTA$Factor_Proximity *
          ((1 : nrow (myClimateData_StationTA)) !=
             myDF_StationInfo$Index_StationTable [1]) *
          ((1 : nrow (myClimateData_StationTA)) !=
             myDF_StationInfo$Index_StationTable [2])
      )



    # Special case: The closest is not used but a further one is chosen
    # This is replacing the first station
    if ((Indicator_Type_LocationBuilding == 2) &&  # by station ID AND
         (Indicator_ExcludeSelectedStation == 1))  {   # use the 3 closest ()

      myDF_StationInfo$Index_StationTable [1] <-
        which.max (
          # myClimateData_StationTA$Indicator_MatchStation_StartDate *
          #   myClimateData_StationTA$Indicator_MatchStation_EndDate *
          myClimateData_StationTA$Indicator_MatchStation_Completeness *
            myClimateData_StationTA$Factor_Proximity *
            ((1 : nrow (myClimateData_StationTA)) !=
               myDF_StationInfo$Index_StationTable [1]) *
            ((1 : nrow (myClimateData_StationTA)) !=
               myDF_StationInfo$Index_StationTable [2]) *
            ((1 : nrow (myClimateData_StationTA)) !=
               myDF_StationInfo$Index_StationTable [3])
        )

      } # End if special case


    myDF_StationInfo$Factor_Consider [2] <-
    if (is.na (myDF_StationInfo$Index_StationTable [2])) {
      0
    } else {
      1
    }

    myDF_StationInfo$Factor_Consider [3] <-
      if (is.na (myDF_StationInfo$Index_StationTable [3])) {
        0
      } else {
        1
      }

  } else {            # Settings that use only 1 station

    myDF_StationInfo$Index_StationTable [2:3] <- NA
    myDF_StationInfo$Factor_Consider    [2:3] <- 0

  } # End if else

  myDF_StationInfo$Index_StationTable <-
    as.numeric (myDF_StationInfo$Index_StationTable)

  myDF_StationInfo$Factor_Consider <-
    as.numeric (myDF_StationInfo$Factor_Consider)


  #i_Station <- 1 # For test purposes

  for (i_Station in (1:3) ) {

    if (myDF_StationInfo$Factor_Consider [i_Station] == 1) {

      myDF_StationInfo$Code_Station [i_Station] <-
          myClimateData_StationTA$Code_Station  [
            myDF_StationInfo$Index_StationTable [i_Station]
          ]

      myDF_StationInfo$ID_Station [i_Station] <-
        myClimateData_StationTA$ID_Station  [
          myDF_StationInfo$Index_StationTable [i_Station]
        ]

      myDF_StationInfo$Name_DataSource [i_Station] <-
        myClimateData_StationTA$Name_DataSource  [
          myDF_StationInfo$Index_StationTable [i_Station]
        ]

      myDF_StationInfo$Date_Start_DataBase[i_Station] <-
        myClimateData_StationTA$Date_Start_DataBase  [
          myDF_StationInfo$Index_StationTable [i_Station]
        ]

      myDF_StationInfo$Date_End_DataBase [i_Station] <-
        myClimateData_StationTA$Date_End_DataBase  [
          myDF_StationInfo$Index_StationTable [i_Station]
        ]
      myDF_StationInfo$Latitude [i_Station] <-
        myClimateData_StationTA$Latitude  [
          myDF_StationInfo$Index_StationTable [i_Station]
        ]
      myDF_StationInfo$Longitude [i_Station] <-
        myClimateData_StationTA$Longitude  [
          myDF_StationInfo$Index_StationTable [i_Station]
        ]
      myDF_StationInfo$Altitude [i_Station] <-
        myClimateData_StationTA$Altitude  [
          myDF_StationInfo$Index_StationTable [i_Station]
        ]
      myDF_StationInfo$Name_Station [i_Station] <-
        myClimateData_StationTA$Name_Station  [
          myDF_StationInfo$Index_StationTable [i_Station]
        ]
      myDF_StationInfo$Name_Region_Station [i_Station] <-
        myClimateData_StationTA$Name_Region_Station  [
          myDF_StationInfo$Index_StationTable [i_Station]
        ]
      myDF_StationInfo$ReciprocalDistance [i_Station] <-
          myClimateData_StationTA$Factor_Proximity  [
            myDF_StationInfo$Index_StationTable [i_Station]
          ]


    } # End if

  } # End loop by i_Station

  myDF_StationInfo$ReciprocalDistance <-
    as.numeric (myDF_StationInfo$ReciprocalDistance)

  if (min (myDF_StationInfo$Factor_Consider [2:3]) == 1) {

    Sum_ReciprocalDistance <-
        myDF_StationInfo$ReciprocalDistance [1] +
          myDF_StationInfo$ReciprocalDistance [2] +
          myDF_StationInfo$ReciprocalDistance [3]


    myDF_StationInfo$Factor_Weighting [1] <-
      myDF_StationInfo$ReciprocalDistance [1] /
      Sum_ReciprocalDistance
    # <SO13>
    myDF_StationInfo$Factor_Weighting [2] <-
      myDF_StationInfo$ReciprocalDistance [2] /
      Sum_ReciprocalDistance
    # <SP13>
    myDF_StationInfo$Factor_Weighting [3] <-
      myDF_StationInfo$ReciprocalDistance [3] /
      Sum_ReciprocalDistance
    # <SQ13>

  } else { # only 1 station is considered

    myDF_StationInfo$Factor_Weighting <- c (1, 0, 0)
  }

  myDF_StationInfo$Factor_Weighting <-
    as.numeric (myDF_StationInfo$Factor_Weighting)

  # Check values, sum must be equal to 1
  myDF_StationInfo$Factor_Weighting
  sum (myDF_StationInfo$Factor_Weighting)

  # clipr::write_clip (myDF_StationInfo)

  ###################################################################################X
  ##  2.3  Temperature data of the 3 stations  -----

  myDF_Evaluation$Year <-
    as.numeric (
      AuxFunctions::xl_MID (
        ColNames_Data_TA_HD,
        3,
        4
      )
    )

  myDF_Evaluation$Month <-
    as.numeric (
      AuxFunctions::xl_MID (
        ColNames_Data_TA_HD,
        8,
        2
      )
    )

  myDF_Evaluation$D <-
    as.numeric (
      myClimateData_TA_HD [
        1,
        ColIndices_Data_TA_HD
      ]
    )


  # Initialisation
   myDF_Evaluation$CT.Input.01  <- 0
   myDF_Evaluation$CT.Input.02  <- 0
   myDF_Evaluation$CT.Input.03  <- 0


  ## Assign the climate data of the evaluation period at the three stations
  ## to the respective evaluation columns

  i_Station <- 1
  for (i_Station in (1:3)) {

    if (myDF_StationInfo$Factor_Consider [i_Station] == 1) {

      myDF_Evaluation [ ,
              AuxFunctions::Format_Integer_LeadingZeros (i_Station, 2, "CT.Input.") ] <-
        as.numeric (
          myClimateData_TA_HD [
            paste0 (myDF_StationInfo$Code_Station [i_Station], ".CT"),
            ColIndices_Data_TA_HD
          ]
        )

      myDF_Evaluation [ ,
            AuxFunctions::Format_Integer_LeadingZeros (i_Station, 2, "TA.Input.") ] <-
        as.numeric (
          myClimateData_TA_HD [
            paste0 (myDF_StationInfo$Code_Station [i_Station], ".TA"),
            ColIndices_Data_TA_HD
          ]
        )

      myDF_Evaluation [ ,
          AuxFunctions::Format_Integer_LeadingZeros (i_Station, 2, "HD.Input.") ] <-
        as.numeric (
          myClimateData_TA_HD [
            paste0 (myDF_StationInfo$Code_Station [i_Station],
                    ".HD_", Temperature_HDD_Base),
            ColIndices_Data_TA_HD
          ]
        )

      myDF_Evaluation [ ,
          AuxFunctions::Format_Integer_LeadingZeros (i_Station, 2, "TA_HD.Input.") ] <-
        as.numeric (
          myClimateData_TA_HD [
            paste0 (myDF_StationInfo$Code_Station [i_Station],
                    ".TA_", Temperature_HDD_Base),
            ColIndices_Data_TA_HD
          ]
        )

    } # End if



  } # End loop by i_Station


  ###################################################################################X
  ##  2.4  Merge the temperature data of the three stations to one dataset -----

  ## Combine the climate data from the 3 stations by use of the weighting factors
  ## and the information about completeness

  myDF_Evaluation$CT <-
    myDF_StationInfo$Factor_Weighting [1] * myDF_Evaluation$CT.Input.01 +
    myDF_StationInfo$Factor_Weighting [2] * myDF_Evaluation$CT.Input.02 +
    myDF_StationInfo$Factor_Weighting [3] * myDF_Evaluation$CT.Input.03

  myDF_Evaluation$TA <-
    (myDF_StationInfo$Factor_Weighting [1] *
        myDF_Evaluation$CT.Input.01 *
        AuxFunctions::Replace_NA (myDF_Evaluation$TA.Input.01, 0)  +
    myDF_StationInfo$Factor_Weighting [2] *
        myDF_Evaluation$CT.Input.02 *
        AuxFunctions::Replace_NA (myDF_Evaluation$TA.Input.02, 0)  +
    myDF_StationInfo$Factor_Weighting [3] *
        myDF_Evaluation$CT.Input.03 *
        AuxFunctions::Replace_NA (myDF_Evaluation$TA.Input.03, 0) ) /
    myDF_Evaluation$CT

  # When the data completeness of a month is below 1.0
  # the heating days are supplemented using the ratio heating days to
  # available days of the month.
  myDF_Evaluation$HD <-
    (myDF_StationInfo$Factor_Weighting [1] *
       myDF_Evaluation$CT.Input.01 *
       AuxFunctions::Replace_NA (myDF_Evaluation$HD.Input.01, 0)  +
       myDF_StationInfo$Factor_Weighting [2] *
       myDF_Evaluation$CT.Input.02 *
       AuxFunctions::Replace_NA (myDF_Evaluation$HD.Input.02, 0)  +
       myDF_StationInfo$Factor_Weighting [3] *
       myDF_Evaluation$CT.Input.03 *
       AuxFunctions::Replace_NA (myDF_Evaluation$HD.Input.03, 0) ) /
    myDF_Evaluation$CT

  # The temperatures during heating days are weighted by completeness
  # AND heating days
  myDF_Evaluation$TA_HD <-
    (myDF_StationInfo$Factor_Weighting [1] *
       myDF_Evaluation$CT.Input.01 *
       AuxFunctions::Replace_NA (myDF_Evaluation$HD.Input.01, 0) *
       AuxFunctions::Replace_NA (myDF_Evaluation$TA_HD.Input.01, 0) +
       myDF_StationInfo$Factor_Weighting [2] *
       myDF_Evaluation$CT.Input.02 *
       AuxFunctions::Replace_NA (myDF_Evaluation$HD.Input.02, 0) *
       AuxFunctions::Replace_NA (myDF_Evaluation$TA_HD.Input.02, 0)  +
       myDF_StationInfo$Factor_Weighting [3] *
       myDF_Evaluation$CT.Input.03 *
       AuxFunctions::Replace_NA (myDF_Evaluation$HD.Input.03, 0)  *
       AuxFunctions::Replace_NA (myDF_Evaluation$TA_HD.Input.03, 0) ) /
    (myDF_Evaluation$CT * myDF_Evaluation$HD)

  myDF_Evaluation$CT <-
    round (myDF_Evaluation$CT, n_Decimal_CT)
  myDF_Evaluation$TA <-
    round (myDF_Evaluation$TA, n_Decimal_TA)
  myDF_Evaluation$HD <-
    round (myDF_Evaluation$HD, n_Decimal_HD)
  myDF_Evaluation$TA_HD <-
    round (myDF_Evaluation$TA_HD, n_Decimal_TA)

  myDF_Evaluation$HDD <-
    pmax (
      (Temperature_HDD_Base - myDF_Evaluation$TA_HD),
      0, na.rm = TRUE
      ) *
        myDF_Evaluation$HD


  myDF_Evaluation$RHDD <-
    pmax (
      (Temperature_HDD_Room - myDF_Evaluation$TA_HD),
      0, na.rm = TRUE
    ) *
      myDF_Evaluation$HD


  ###################################################################################X
  #  3  SOLAR RADIATION DATA  -----
  ###################################################################################X

  ## Description
  ## Based on the latitude and longitude a code is created
  ## to identify the row in the solar radiation table.
  ## Based on the columns which have been identified above
  ## the values for horizontal radiation are taken from the table.
  ## By use of estimation functions the radiation is calculated for different
  ## orientations on vertical and on inclined surface
  ## (inclination angle is input parameter of the function)



  ###################################################################################X
  ##  3.1  Preparation: Parameters of estimation functions   -----

  ## Determination of monthly climate data as a basis
  ## for the estimation of the solar radiation on heating days

  # see the following report
  # 122.	Loga, Tobias; Großklos, Marc; Landgraf, Katrin:
  # Klimadaten für die Realbilanzierung.
  # Grundlagen des Tools „Gradtagzahlen-Deutschland.xlsx“.
  # (MOBASY Teilbericht) 73 S.;
  # IWU- Institut Wohnen und Umwelt, Darmstadt 2020; ISBN 978-3-941140-66-0
  # http://dx.doi.org/10.13140/RG.2.2.25695.28324
  # https://www.iwu.de/fileadmin/publikationen/energie/mobasy/2020_IWU_LogaGrossklosLandgraf_MOBASYTeilberichtKlimadatenRealbilanzierung.pdf


  ## Functions to determine correction values for all months
  ## see equation (4) in the above mentioned report

  f_E_90 <-
    myParTab_SolOrientEst ["E_90", "u_0"] +
    myParTab_SolOrientEst ["E_90", "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_SE_90 <-
    myParTab_SolOrientEst ["SE_90", "u_0"] +
    myParTab_SolOrientEst ["SE_90", "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_S_90 <-
    myParTab_SolOrientEst ["S_90", "u_0"] +
    myParTab_SolOrientEst ["S_90", "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_SW_90 <-
    myParTab_SolOrientEst ["SW_90", "u_0"] +
    myParTab_SolOrientEst ["SW_90", "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_W_90 <-
    myParTab_SolOrientEst ["W_90", "u_0"] +
    myParTab_SolOrientEst ["W_90", "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_NW_90 <-
    myParTab_SolOrientEst ["NW_90", "u_0"] +
    myParTab_SolOrientEst ["NW_90", "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_N_90 <-
    myParTab_SolOrientEst ["N_90", "u_0"] +
    myParTab_SolOrientEst ["N_90", "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_NE_90 <-
    myParTab_SolOrientEst ["NE_90", "u_0"] +
    myParTab_SolOrientEst ["NE_90", "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)

  Label_Inclination <-
    c ("30", "45", "60") [
        which.min (
          abs (
            Degree_Inclination_Solar - c (30, 45, 60)
          )
        )
      ]

  Code_E_x  <- paste0 ("E_",  Label_Inclination)
  Code_SE_x <- paste0 ("SE_", Label_Inclination)
  Code_S_x  <- paste0 ("S_",  Label_Inclination)
  Code_SW_x <- paste0 ("SW_", Label_Inclination)
  Code_W_x  <- paste0 ("W_",  Label_Inclination)
  Code_NW_x <- paste0 ("NW_", Label_Inclination)
  Code_N_x  <- paste0 ("N_",  Label_Inclination)
  Code_NE_x <- paste0 ("NE_", Label_Inclination)

  f_E_Inclined <-
    myParTab_SolOrientEst [Code_E_x, "u_0"] +
    myParTab_SolOrientEst [Code_E_x, "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_SE_Inclined <-
    myParTab_SolOrientEst [Code_SE_x, "u_0"] +
    myParTab_SolOrientEst [Code_SE_x, "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_S_Inclined <-
    myParTab_SolOrientEst [Code_S_x, "u_0"] +
    myParTab_SolOrientEst [Code_S_x, "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_SW_Inclined <-
    myParTab_SolOrientEst [Code_SW_x, "u_0"] +
    myParTab_SolOrientEst [Code_SW_x, "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_W_Inclined <-
    myParTab_SolOrientEst [Code_W_x, "u_0"] +
    myParTab_SolOrientEst [Code_W_x, "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_NW_Inclined <-
    myParTab_SolOrientEst [Code_NW_x, "u_0"] +
    myParTab_SolOrientEst [Code_NW_x, "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_N_Inclined <-
    myParTab_SolOrientEst [Code_N_x, "u_0"] +
    myParTab_SolOrientEst [Code_N_x, "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)
  f_NE_Inclined <-
    myParTab_SolOrientEst [Code_NE_x, "u_0"] +
    myParTab_SolOrientEst [Code_NE_x, "u"] *
    sin ( ((myDF_Evaluation$Month) - 0.5) / 12 * pi)


  ###################################################################################X
  ##  3.2  Solar radiation dataset from the data table to be used -----

  ## Use the geo coordinates determined above
  ## (of the postcode or of the temperature station)

  Code_GeoCoordinates_Sol <-
    paste0 (
      "DE.MET",
      ".lat",
      AuxFunctions::xl_TEXT (round (Latitude_Mapping_Location * 5, 0) / 5 * 10, "000"),
      ".lon",
      AuxFunctions::xl_TEXT (round (Longitude_Mapping_Location * 5, 0) / 5 * 10, "000")
      )

  ## Values from the data table: average solar horizontal radiation per month [W/m²]

  myDF_Evaluation$I_Hor.Input <-
    as.numeric (
      myClimateData_Sol [
        paste0 (Code_GeoCoordinates_Sol, ".I_Hor"),
        ColNames_Data_Sol
      ]
    )


  ###################################################################################X
  ##  3.3  Estimation of solar radiation on vertical and inclined surfaces -----

  ## Global solar radiation on horizontal surfaces, sum by month [kWh]

  myDF_Evaluation$G_Hor <-
    round (
      myDF_Evaluation$I_Hor.Input *
        myDF_Evaluation$D * 24 / 1000
      ,
      2
    )


  ## EAST: vertical and inclined surface

  myDF_Evaluation$G_E <-
    round (
      exp (myParTab_SolOrientEst ["E_90", "Beta_0"]) *
        (f_E_90  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst ["E_90", "Beta_1"],
      n_Decimal_G
    )

  myDF_Evaluation$G_E_Inclined <-
    round (
      exp (myParTab_SolOrientEst [Code_E_x, "Beta_0"]) *
        (f_E_Inclined  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst [Code_E_x, "Beta_1"],
      n_Decimal_G
    )


  ## SOUTH-EAST: vertical and inclined surface

  myDF_Evaluation$G_SE <-
    round (
      exp (myParTab_SolOrientEst ["SE_90", "Beta_0"]) *
        (f_SE_90  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst ["SE_90", "Beta_1"],
      n_Decimal_G
    )

  myDF_Evaluation$G_SE_Inclined <-
    round (
      exp (myParTab_SolOrientEst [Code_SE_x, "Beta_0"]) *
        (f_SE_Inclined  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst [Code_SE_x, "Beta_1"],
      n_Decimal_G
    )


  ## SOUTH: vertical and inclined surface

  myDF_Evaluation$G_S <-
    round (
      exp (myParTab_SolOrientEst ["S_90", "Beta_0"]) *
        (f_S_90  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst ["S_90", "Beta_1"],
      n_Decimal_G
    )

  myDF_Evaluation$G_S_Inclined <-
    round (
      exp (myParTab_SolOrientEst [Code_S_x, "Beta_0"]) *
        (f_S_Inclined  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst [Code_S_x, "Beta_1"],
      n_Decimal_G
    )


  ## SOUTH-WEST: vertical and inclined surface

  myDF_Evaluation$G_SW <-
    round (
      exp (myParTab_SolOrientEst ["SW_90", "Beta_0"]) *
        (f_SW_90  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst ["SW_90", "Beta_1"],
      n_Decimal_G
    )

  myDF_Evaluation$G_SW_Inclined <-
    round (
      exp (myParTab_SolOrientEst [Code_SW_x, "Beta_0"]) *
        (f_SW_Inclined  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst [Code_SW_x, "Beta_1"],
      n_Decimal_G
    )


  ## WEST: vertical and inclined surface

  myDF_Evaluation$G_W <-
    round (
      exp (myParTab_SolOrientEst ["W_90", "Beta_0"]) *
        (f_W_90  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst ["W_90", "Beta_1"],
      n_Decimal_G
    )

  myDF_Evaluation$G_W_Inclined <-
    round (
      exp (myParTab_SolOrientEst [Code_W_x, "Beta_0"]) *
        (f_W_Inclined  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst [Code_W_x, "Beta_1"],
      n_Decimal_G
    )

  ## NORTH-WEST: vertical and inclined surface

  myDF_Evaluation$G_NW <-
    round (
      exp (myParTab_SolOrientEst ["NW_90", "Beta_0"]) *
        (f_NW_90  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst ["NW_90", "Beta_1"],
      n_Decimal_G
    )

  myDF_Evaluation$G_NW_Inclined <-
    round (
      exp (myParTab_SolOrientEst [Code_NW_x, "Beta_0"]) *
        (f_NW_Inclined  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst [Code_NW_x, "Beta_1"],
      n_Decimal_G
    )


  ## NORTH: vertical and inclined surface

  myDF_Evaluation$G_N <-
    round (
      exp (myParTab_SolOrientEst ["N_90", "Beta_0"]) *
        (f_N_90  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst ["N_90", "Beta_1"],
      n_Decimal_G
    )

  myDF_Evaluation$G_N_Inclined <-
    round (
      exp (myParTab_SolOrientEst [Code_N_x, "Beta_0"]) *
        (f_N_Inclined  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst [Code_N_x, "Beta_1"],
      n_Decimal_G
    )


  ## NORTH-EAST: vertical and inclined surface

  myDF_Evaluation$G_NE <-
    round (
      exp (myParTab_SolOrientEst ["NE_90", "Beta_0"]) *
        (f_NE_90  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst ["NE_90", "Beta_1"],
      n_Decimal_G
    )

  myDF_Evaluation$G_NE_Inclined <-
    round (
      exp (myParTab_SolOrientEst [Code_NE_x, "Beta_0"]) *
        (f_NE_Inclined  * myDF_Evaluation$G_Hor) ^
        myParTab_SolOrientEst [Code_NE_x, "Beta_1"],
      n_Decimal_G
    )



  ###################################################################################X
  ##  3.4  Estimation of solar radiation on heating days -----

  # Correction factor, considering that the ratio of global radiation
  # during heating days to global radiation of the complete month
  # is a bit smaller than the ratio of heating days to the days of the month
  # (statistically less global radiation for days below base temperature)
  myDF_Evaluation$f_Sol_HD <-
    AuxFunctions::Replace_NA (
          1 - p_Sol_HD * (1 - myDF_Evaluation$HD / myDF_Evaluation$D),
      -999999
    )

  ColIndex_DFEval_Start_Sol <-
    which (
      ColNames_EvalDF == "G_Hor"
    )

  ColIndex_DFEval_Start_SolHD <-
    which (
      ColNames_EvalDF == "G_Hor_HD"
    )

  n_Col_DFEval_SolHD <-
    ColIndex_DFEval_Start_SolHD - ColIndex_DFEval_Start_Sol - 1
  # Between both areas is "f_Sol_HD", therefore: minus 1

  ColIndices_DFEval_Sol <-
    ColIndex_DFEval_Start_Sol :
      (ColIndex_DFEval_Start_Sol + n_Col_DFEval_SolHD - 1)

  ColIndices_DFEval_SolHD <-
    ColIndex_DFEval_Start_SolHD :
    (ColIndex_DFEval_Start_SolHD + n_Col_DFEval_SolHD - 1)


  myDF_Evaluation [ ,ColIndices_DFEval_SolHD] <-
    round (
        myDF_Evaluation$f_Sol_HD *
          myDF_Evaluation$HD / myDF_Evaluation$D *
          myDF_Evaluation [ ,ColIndices_DFEval_Sol],
      n_Decimal_G
    )



  ###################################################################################X
  #  4  OUTPUT  -----
  ###################################################################################X

  ###################################################################################X
  ##  4.1  Compile the output dataframe "myDF_ClimCalc" -----

  ## The output aggregates the evaluation period
  ## to 12 average months and an average year


  # Initialisation

  myDF_ClimCalc [2 : n_Col_DF_ClimCalc] <- 0


  # 2023-12-08 supplemented
  myDF_ClimCalc$Month [1:12] <- myDF_Evaluation$Month [1:12]
  myDF_ClimCalc$Month [13] <- 0


  #i_Year <- 1 # Test of loop

  for (i_Year in (1:n_Year_Evaluation)) {

    myDF_ClimCalc$D [1:12] <-
      myDF_ClimCalc$D [1:12] +
      myDF_Evaluation$D [(1:12) + (i_Year-1) * 12]

    myDF_ClimCalc$CT [1:12] <-
      myDF_ClimCalc$CT [1:12] +
      myDF_Evaluation$CT [(1:12) + (i_Year-1) * 12]

    # When the data completeness of a month is below 1.0
    # it has less weight in averaging the values of the month over several years.
    # The normalisation (devision by myDF_Evaluation$CT) is performed
    # below the loop

    myDF_ClimCalc$TA [1:12] <-
      myDF_ClimCalc$TA [1:12] +
      myDF_Evaluation$CT [(1:12) + (i_Year-1) * 12] *
        myDF_Evaluation$TA [(1:12) + (i_Year-1) * 12]

    myDF_ClimCalc$HD [1:12] <-
      myDF_ClimCalc$HD [1:12] +
      myDF_Evaluation$CT [(1:12) + (i_Year-1) * 12] *
      myDF_Evaluation$HD [(1:12) + (i_Year-1) * 12]

    myDF_ClimCalc$TA_HD [1:12] <-
      myDF_ClimCalc$TA_HD [1:12] +
      myDF_Evaluation$CT [(1:12) + (i_Year-1) * 12] *
      myDF_Evaluation$HD [(1:12) + (i_Year-1) * 12] *
      AuxFunctions::Replace_NA (myDF_Evaluation$TA_HD [(1:12) + (i_Year-1) * 12], 0)

    myDF_ClimCalc$HDD [1:12] <-
      myDF_ClimCalc$HDD [1:12] +
      myDF_Evaluation$CT [(1:12) + (i_Year-1) * 12] *
      myDF_Evaluation$HDD [(1:12) + (i_Year-1) * 12]

    myDF_ClimCalc$RHDD [1:12] <-
      myDF_ClimCalc$RHDD [1:12] +
      myDF_Evaluation$CT [(1:12) + (i_Year-1) * 12] *
      myDF_Evaluation$RHDD [(1:12) + (i_Year-1) * 12]


    ## Loop by solar data (same columns in evaluation and output dataframe)

    ## Initialisation
    i_Col_ClimCalc <-
      which (ClimCalcColNames == "G_Hor")

    # Test
    #i_Col_EvalDF <- ColIndices_DFEval_Sol [1]
    for (i_Col_EvalDF in c (ColIndices_DFEval_Sol, ColIndices_DFEval_SolHD)) {

      myDF_ClimCalc [1:12, i_Col_ClimCalc] <-
        myDF_ClimCalc [1:12, i_Col_ClimCalc] +
        myDF_Evaluation [(1:12) + (i_Year-1) * 12, i_Col_EvalDF]


      i_Col_ClimCalc = i_Col_ClimCalc + 1

    } # End loop by solar radiation columns


  } # End loop by i_Year


  ## Normalise the monthly values to the months of an average year
  ## Determine the annual values (sums or averages)

  myDF_ClimCalc$D [1:12] <-
    myDF_ClimCalc$D [1:12] / n_Year_Evaluation
  myDF_ClimCalc$D [13] <-
    sum (myDF_ClimCalc$D [1:12], na.rm = TRUE)
  myDF_ClimCalc$D <- round (myDF_ClimCalc$D, n_Decimal_HD)

  myDF_ClimCalc$CT [1:12] <-
    myDF_ClimCalc$CT [1:12] / n_Year_Evaluation
  myDF_ClimCalc$CT [13] <-
    sum (myDF_ClimCalc$CT [1:12], na.rm = TRUE) / 12
  myDF_ClimCalc$CT <- round (myDF_ClimCalc$CT, n_Decimal_CT)

  myDF_ClimCalc$TA [1:12] <-
    myDF_ClimCalc$TA [1:12] / n_Year_Evaluation / myDF_ClimCalc$CT [1:12]
  myDF_ClimCalc$TA [13] <-
    sum (myDF_ClimCalc$TA [1:12], na.rm = TRUE) / 12
  myDF_ClimCalc$TA <- round (myDF_ClimCalc$TA, n_Decimal_TA)

  myDF_ClimCalc$HD [1:12] <-
    myDF_ClimCalc$HD [1:12] / n_Year_Evaluation / myDF_ClimCalc$CT [1:12]
  myDF_ClimCalc$HD [13] <-
    sum (myDF_ClimCalc$HD [1:12], na.rm = TRUE)
  myDF_ClimCalc$HD <- round (myDF_ClimCalc$HD, n_Decimal_HD)

  myDF_ClimCalc$TA_HD [1:12] <-
    myDF_ClimCalc$TA_HD [1:12] / n_Year_Evaluation /
    myDF_ClimCalc$CT [1:12] / myDF_ClimCalc$HD [1:12]
  myDF_ClimCalc$TA_HD [13] <-
    sum (myDF_ClimCalc$HD [1:12] * myDF_ClimCalc$TA_HD [1:12], na.rm = TRUE) /
    myDF_ClimCalc$HD [13]
  myDF_ClimCalc$TA_HD <- round (myDF_ClimCalc$TA_HD, n_Decimal_TA)

  myDF_ClimCalc$HDD [1:12] <-
    myDF_ClimCalc$HDD [1:12] / n_Year_Evaluation / myDF_ClimCalc$CT [1:12]
  myDF_ClimCalc$HDD [13] <-
    sum (myDF_ClimCalc$HDD [1:12], na.rm = TRUE)
  myDF_ClimCalc$HDD <- round (myDF_ClimCalc$HDD, n_Decimal_HD)

  myDF_ClimCalc$RHDD [1:12] <-
    myDF_ClimCalc$RHDD [1:12] / n_Year_Evaluation / myDF_ClimCalc$CT [1:12]
  myDF_ClimCalc$RHDD [13] <-
    sum (myDF_ClimCalc$RHDD [1:12], na.rm = TRUE)
  myDF_ClimCalc$RHDD <- round (myDF_ClimCalc$RHDD, n_Decimal_HD)



  ## Loop by solar data (same columns in evaluation and output dataframe)

  LoopSequence <- (which (ClimCalcColNames == "G_Hor") :
                     n_Col_DF_ClimCalc)

  # Test of the loop
  # i_Col_ClimCalc <- which (ClimCalcColNames == "G_Hor")

  for (i_Col_ClimCalc in LoopSequence) {

    myDF_ClimCalc [1:12, i_Col_ClimCalc] <-
      myDF_ClimCalc [1:12, i_Col_ClimCalc] / n_Year_Evaluation

    myDF_ClimCalc [13, i_Col_ClimCalc] <-
      sum (myDF_ClimCalc [1:12, i_Col_ClimCalc], na.rm = TRUE)

    myDF_ClimCalc [ ,i_Col_ClimCalc] <-
      round (myDF_ClimCalc [ ,i_Col_ClimCalc], n_Decimal_G)


  } # End loop by solar radiation columns


  ## Check some results

  # myDF_ClimCalc$D
  # myDF_ClimCalc$CT
  # myDF_ClimCalc$TA
  # myDF_ClimCalc$HD
  # myDF_ClimCalc$TA_HD
  # myDF_ClimCalc$HDD
  # myDF_ClimCalc$RHDD
  #
  # myDF_ClimCalc$G_Hor
  # myDF_ClimCalc$G_Hor_HD
  # myDF_ClimCalc$G_S
  # myDF_ClimCalc$G_S_HD
  # myDF_ClimCalc$G_S_Inclined
  # myDF_ClimCalc$G_S_Inclined_HD
  # myDF_ClimCalc$G_NW
  # myDF_ClimCalc$G_NW_Inclined


  # sum (myDF_Evaluation$HD.Input.01)
  # sum (myDF_Evaluation$HD.Input.02)
  # sum (myDF_Evaluation$HD.Input.03)
  # sum (myDF_Evaluation$HD)

  myDF_StationInfo$Name_Station
  #


  ###################################################################################X
  ##  4.2  Compile the output dataframes "myDF_EvaluationByYear"  -----
  ##  from "myDF_Evaluation"

  ## The output aggregates the evaluation period annual values

  VariableNames_EvaluationByYear <-
    c(
      "D",
      "HD",
      "HDD",
      "RHDD",
      "G_Hor",
      "G_E",
      "G_E_Inclined",
      "G_SE",
      "G_SE_Inclined",
      "G_S",
      "G_S_Inclined",
      "G_SW",
      "G_SW_Inclined",
      "G_W",
      "G_W_Inclined",
      "G_NW",
      "G_NW_Inclined",
      "G_N",
      "G_N_Inclined",
      "G_NE",
      "G_NE_Inclined",
      "G_Hor_HD",
      "G_E_HD",
      "G_E_Inclined_HD",
      "G_SE_HD",
      "G_SE_Inclined_HD",
      "G_S_HD",
      "G_S_Inclined_HD",
      "G_SW_HD",
      "G_SW_Inclined_HD",
      "G_W_HD",
      "G_W_Inclined_HD",
      "G_NW_HD",
      "G_NW_Inclined_HD",
      "G_N_HD",
      "G_N_Inclined_HD",
      "G_NE_HD",
      "G_NE_Inclined_HD"
    )



  #n_Year_Evaluation <- nrow (myDF_Evaluation)/12

  myDF_EvaluationByYear <-
    data.frame (
      ID_EvalYear =
        AuxFunctions::Format_Integer_LeadingZeros (
          myInteger = c (1:n_Year_Evaluation),
          myWidth = 2,
          myPrefix = "EY_"
          ),
      Index_EvalYear = c (1:n_Year_Evaluation)
    )
  rownames (myDF_EvaluationByYear) <- myDF_EvaluationByYear$ID_EvalYear



  #i_Year <- 1

  for (i_Year in (1:n_Year_Evaluation)) {

    CurrentRowsDFEval <- which (myDF_Evaluation$Index_EvalYear == i_Year)

    myDF_EvaluationByYear$Label_Year [i_Year] <-
      paste ( levels (as.factor (myDF_Evaluation$Year [CurrentRowsDFEval] )), collapse = "/"  )

    myDF_EvaluationByYear$Label_Period [i_Year] <-
      paste0 (
        myDF_Evaluation$Month  [CurrentRowsDFEval [ 1] ], "/",
        myDF_Evaluation$Year [CurrentRowsDFEval [ 1] ], "-",
        myDF_Evaluation$Month  [CurrentRowsDFEval [12] ], "/",
        myDF_Evaluation$Year [CurrentRowsDFEval [12] ]
      )

    myDF_EvaluationByYear [i_Year ,"TA"] <-
      sum (
        apply (
          myDF_Evaluation [
            CurrentRowsDFEval,
            c ("TA", "D") ],
          MARGIN = 1,
          FUN = prod,
          na.rm = TRUE
        )
      ) /
      sum (
        myDF_Evaluation [
          CurrentRowsDFEval, "D" ]
      )

    myDF_EvaluationByYear [i_Year ,"TA_HD"] <-
      sum (
        apply (
          myDF_Evaluation [
            CurrentRowsDFEval,
            c ("TA_HD", "HD") ],
          MARGIN = 1,
          FUN = prod,
          na.rm = TRUE
        )
      ) /
      sum (
        myDF_Evaluation [
          CurrentRowsDFEval, "HD" ]
      )

    myDF_EvaluationByYear [i_Year ,VariableNames_EvaluationByYear] <-
      apply (
        myDF_Evaluation [
          CurrentRowsDFEval,
          VariableNames_EvaluationByYear],
        MARGIN = 2,
        FUN = sum,
        na.rm = TRUE
        )


  } # End loop for i_Year




  ###################################################################################X
  ##  4.3  Prepare the dataframes for output -----

  ## The output will be a list of all vectors
  ##
  ## Note: A further function "ResultDataframe_ClimateByMonth ()"
  ## is available to segregate the output to
  ## reform the initial data frames used in this function


  myDF_FunctionArguments <-
    cbind.data.frame (
      Indicator_Type_LocationBuilding,
      Indicator_Type_AssignStationToPostcode,
      PostCode,
      Code_ClimateStation,
      Indicator_ExcludeSelectedStation,
      # Indicator_ApplyHeightCorrection,   #2023-02-10 Not yet implemented
      # Altitude_Building,       #2023-02-10 Not yet implemented
      Month_Start,
      Year_Start,
      n_Year,
      # Index_TypeConditioning,            #2023-02-10 Not yet implemented
      Temperature_HDD_Room,
      Temperature_HDD_Base,
      Degree_Inclination_Solar
    )

  myDF_OutputStructure <-
    as.data.frame (
      cbind (
        c (
          "DF_ClimCalc",
          "DF_Evaluation",
          "DF_EvaluationByYear",
          "DF_StationInfo",
          "DF_FunctionArguments"
        ),
        c (
          ncol (myDF_ClimCalc),
          ncol (myDF_Evaluation),
          ncol (myDF_EvaluationByYear),
          ncol (myDF_StationInfo),
          ncol (myDF_FunctionArguments)
        )
      )
    )


  colnames (myDF_OutputStructure) <-
    c (
      "Name_DataFrame",
      "n_Col_DataFrame"
    )


  return (
    list (
      DF_ClimCalc          = myDF_ClimCalc,
      DF_Evaluation        = myDF_Evaluation,
      DF_EvaluationByYear  = myDF_EvaluationByYear,
      DF_StationInfo       = myDF_StationInfo,
      DF_FunctionArguments = myDF_FunctionArguments,
      DF_OutputStructure   = myDF_OutputStructure
    )
    # c (
    #   myDF_OutputStructure,
    #   myDF_ClimCalc,
    #   myDF_Evaluation,
    #   myDF_StationInfo,
    #   myDF_FunctionArguments
    #   )
  )



} # End of function

## End of the function ClimateByMonth () -----
#####################################################################################X

