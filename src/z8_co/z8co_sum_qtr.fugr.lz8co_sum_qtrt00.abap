*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8CO_SUM_QTR....................................*
DATA:  BEGIN OF STATUS_Z8CO_SUM_QTR                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8CO_SUM_QTR                  .
CONTROLS: TCTRL_Z8CO_SUM_QTR
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8CO_SUM_QTR                  .
TABLES: Z8CO_SUM_QTR                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
