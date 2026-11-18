*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8MATPLANT_M....................................*
DATA:  BEGIN OF STATUS_Z8MATPLANT_M                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8MATPLANT_M                  .
CONTROLS: TCTRL_Z8MATPLANT_M
            TYPE TABLEVIEW USING SCREEN '0002'.
*.........table declarations:.................................*
TABLES: *Z8MATPLANT_M                  .
TABLES: Z8MATPLANT_M                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
