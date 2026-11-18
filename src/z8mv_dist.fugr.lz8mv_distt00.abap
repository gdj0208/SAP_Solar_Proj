*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8V_DISTANCE....................................*
TABLES: Z8V_DISTANCE, *Z8V_DISTANCE. "view work areas
CONTROLS: TCTRL_Z8V_DISTANCE
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_Z8V_DISTANCE. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_Z8V_DISTANCE.
* Table for entries selected to show on screen
DATA: BEGIN OF Z8V_DISTANCE_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE Z8V_DISTANCE.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF Z8V_DISTANCE_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF Z8V_DISTANCE_TOTAL OCCURS 0010.
INCLUDE STRUCTURE Z8V_DISTANCE.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF Z8V_DISTANCE_TOTAL.

*.........table declarations:.................................*
TABLES: Z8DISTANCE_M                   .
TABLES: Z8PLANT_M                      .
TABLES: Z8REGION_M                     .
