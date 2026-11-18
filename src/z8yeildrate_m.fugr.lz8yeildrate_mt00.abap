*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8YEILDRATE_M...................................*
DATA:  BEGIN OF STATUS_Z8YEILDRATE_M                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8YEILDRATE_M                 .
CONTROLS: TCTRL_Z8YEILDRATE_M
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8YEILDRATE_M                 .
TABLES: Z8YEILDRATE_M                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
