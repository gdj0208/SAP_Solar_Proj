*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8GLACC_M.......................................*
DATA:  BEGIN OF STATUS_Z8GLACC_M                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8GLACC_M                     .
CONTROLS: TCTRL_Z8GLACC_M
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8GLACC_M                     .
TABLES: Z8GLACC_M                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
