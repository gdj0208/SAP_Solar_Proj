*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8DC_M..........................................*
DATA:  BEGIN OF STATUS_Z8DC_M                        .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8DC_M                        .
CONTROLS: TCTRL_Z8DC_M
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8DC_M                        .
TABLES: Z8DC_M                         .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
