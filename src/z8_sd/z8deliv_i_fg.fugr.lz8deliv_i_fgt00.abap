*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8SD_DELIV_I....................................*
DATA:  BEGIN OF STATUS_Z8SD_DELIV_I                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8SD_DELIV_I                  .
CONTROLS: TCTRL_Z8SD_DELIV_I
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8SD_DELIV_I                  .
TABLES: Z8SD_DELIV_I                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
