*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8MM_PO_HIST....................................*
DATA:  BEGIN OF STATUS_Z8MM_PO_HIST                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8MM_PO_HIST                  .
CONTROLS: TCTRL_Z8MM_PO_HIST
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8MM_PO_HIST                  .
TABLES: Z8MM_PO_HIST                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
