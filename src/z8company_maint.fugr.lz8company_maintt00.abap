*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8V_COMPANY_M...................................*
TABLES: Z8V_COMPANY_M, *Z8V_COMPANY_M. "view work areas
CONTROLS: TCTRL_Z8V_COMPANY_M
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_Z8V_COMPANY_M. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_Z8V_COMPANY_M.
* Table for entries selected to show on screen
DATA: BEGIN OF Z8V_COMPANY_M_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE Z8V_COMPANY_M.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF Z8V_COMPANY_M_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF Z8V_COMPANY_M_TOTAL OCCURS 0010.
INCLUDE STRUCTURE Z8V_COMPANY_M.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF Z8V_COMPANY_M_TOTAL.

*.........table declarations:.................................*
TABLES: Z8COMPANY_M                    .
