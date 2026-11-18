*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8CUSTOMER_M....................................*
DATA:  BEGIN OF STATUS_Z8CUSTOMER_M                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8CUSTOMER_M                  .
CONTROLS: TCTRL_Z8CUSTOMER_M
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8CUSTOMER_M                  .
TABLES: Z8CUSTOMER_M                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
