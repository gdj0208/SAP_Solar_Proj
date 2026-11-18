*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8SD_QUOT_REQ...................................*
DATA:  BEGIN OF STATUS_Z8SD_QUOT_REQ                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8SD_QUOT_REQ                 .
CONTROLS: TCTRL_Z8SD_QUOT_REQ
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8SD_QUOT_REQ                 .
TABLES: Z8SD_QUOT_REQ                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
