*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8FI_ACCDOC_H...................................*
DATA:  BEGIN OF STATUS_Z8FI_ACCDOC_H                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8FI_ACCDOC_H                 .
CONTROLS: TCTRL_Z8FI_ACCDOC_H
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8FI_ACCDOC_H                 .
TABLES: Z8FI_ACCDOC_H                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
