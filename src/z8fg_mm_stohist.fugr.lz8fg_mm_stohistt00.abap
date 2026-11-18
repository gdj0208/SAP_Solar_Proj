*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8V_MM_STOHIST..................................*
TABLES: Z8V_MM_STOHIST, *Z8V_MM_STOHIST. "view work areas
CONTROLS: TCTRL_Z8V_MM_STOHIST
TYPE TABLEVIEW USING SCREEN '0001'.
DATA: BEGIN OF STATUS_Z8V_MM_STOHIST. "state vector
          INCLUDE STRUCTURE VIMSTATUS.
DATA: END OF STATUS_Z8V_MM_STOHIST.
* Table for entries selected to show on screen
DATA: BEGIN OF Z8V_MM_STOHIST_EXTRACT OCCURS 0010.
INCLUDE STRUCTURE Z8V_MM_STOHIST.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF Z8V_MM_STOHIST_EXTRACT.
* Table for all entries loaded from database
DATA: BEGIN OF Z8V_MM_STOHIST_TOTAL OCCURS 0010.
INCLUDE STRUCTURE Z8V_MM_STOHIST.
          INCLUDE STRUCTURE VIMFLAGTAB.
DATA: END OF Z8V_MM_STOHIST_TOTAL.

*.........table declarations:.................................*
TABLES: Z8MM_STO_HIST                  .
