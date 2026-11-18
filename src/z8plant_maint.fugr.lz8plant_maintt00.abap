*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8V_PLANTM......................................*
TABLES: Z8V_PLANTM, *Z8V_PLANTM. "view work areas
CONTROLS: TCTRL_Z8V_PLANTM
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_Z8V_PLANTM. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_Z8V_PLANTM.
* Table for entries selected to show on screen
DATA: BEGIN OF Z8V_PLANTM_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE Z8V_PLANTM.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF Z8V_PLANTM_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF Z8V_PLANTM_TOTAL OCCURS 0010.
INCLUDE STRUCTURE Z8V_PLANTM.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF Z8V_PLANTM_TOTAL.

*.........table declarations:.................................*
TABLES: Z8PLANT_M                      .
