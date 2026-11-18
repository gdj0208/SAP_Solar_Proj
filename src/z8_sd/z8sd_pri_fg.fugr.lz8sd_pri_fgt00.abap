*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8SD_PRICE_M....................................*
DATA:  BEGIN OF STATUS_Z8SD_PRICE_M                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8SD_PRICE_M                  .
CONTROLS: TCTRL_Z8SD_PRICE_M
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8SD_PRICE_M                  .
TABLES: Z8SD_PRICE_M                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
