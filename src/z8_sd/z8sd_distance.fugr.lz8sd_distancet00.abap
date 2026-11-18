*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8DISTANCE_M....................................*
DATA:  BEGIN OF STATUS_Z8DISTANCE_M                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8DISTANCE_M                  .
CONTROLS: TCTRL_Z8DISTANCE_M
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8DISTANCE_M                  .
TABLES: Z8DISTANCE_M                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
