*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8FI_CUSTOMER...................................*
DATA:  BEGIN OF STATUS_Z8FI_CUSTOMER                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8FI_CUSTOMER                 .
CONTROLS: TCTRL_Z8FI_CUSTOMER
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8FI_CUSTOMER                 .
TABLES: Z8FI_CUSTOMER                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
