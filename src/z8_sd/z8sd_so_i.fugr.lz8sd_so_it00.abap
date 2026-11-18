*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8SD_SO_I.......................................*
DATA:  BEGIN OF STATUS_Z8SD_SO_I                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8SD_SO_I                     .
CONTROLS: TCTRL_Z8SD_SO_I
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8SD_SO_I                     .
TABLES: Z8SD_SO_I                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
