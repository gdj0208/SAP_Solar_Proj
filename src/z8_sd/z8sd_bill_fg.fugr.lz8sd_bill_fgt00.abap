*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8SD_BILLING_H..................................*
DATA:  BEGIN OF STATUS_Z8SD_BILLING_H                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8SD_BILLING_H                .
CONTROLS: TCTRL_Z8SD_BILLING_H
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8SD_BILLING_H                .
TABLES: Z8SD_BILLING_H                 .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
