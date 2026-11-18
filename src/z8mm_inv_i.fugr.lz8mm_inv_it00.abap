*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8MM_INV_I......................................*
DATA:  BEGIN OF STATUS_Z8MM_INV_I                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8MM_INV_I                    .
CONTROLS: TCTRL_Z8MM_INV_I
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8MM_INV_I                    .
TABLES: Z8MM_INV_I                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
