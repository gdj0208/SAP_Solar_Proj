*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8V_TRANS_DAYS..................................*
TABLES: Z8V_TRANS_DAYS, *Z8V_TRANS_DAYS. "view work areas
CONTROLS: TCTRL_Z8V_TRANS_DAYS
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_Z8V_TRANS_DAYS. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_Z8V_TRANS_DAYS.
* Table for entries selected to show on screen
DATA: BEGIN OF Z8V_TRANS_DAYS_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE Z8V_TRANS_DAYS.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF Z8V_TRANS_DAYS_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF Z8V_TRANS_DAYS_TOTAL OCCURS 0010.
INCLUDE STRUCTURE Z8V_TRANS_DAYS.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF Z8V_TRANS_DAYS_TOTAL.

*.........table declarations:.................................*
TABLES: Z8ROUTE_M                      .
