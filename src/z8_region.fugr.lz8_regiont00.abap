*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8REGION_M......................................*
DATA:  BEGIN OF STATUS_Z8REGION_M                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8REGION_M                    .
CONTROLS: TCTRL_Z8REGION_M
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8REGION_M                    .
TABLES: Z8REGION_M                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
