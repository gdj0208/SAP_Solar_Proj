*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8FI_ACCDOC_I...................................*
DATA:  BEGIN OF STATUS_Z8FI_ACCDOC_I                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8FI_ACCDOC_I                 .
CONTROLS: TCTRL_Z8FI_ACCDOC_I
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8FI_ACCDOC_I                 .
TABLES: Z8FI_ACCDOC_I                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
