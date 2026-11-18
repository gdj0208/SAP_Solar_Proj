*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8MM_PR.........................................*
DATA:  BEGIN OF STATUS_Z8MM_PR                       .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8MM_PR                       .
CONTROLS: TCTRL_Z8MM_PR
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8MM_PR                       .
TABLES: Z8MM_PR                        .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
