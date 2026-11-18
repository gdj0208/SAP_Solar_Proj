*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8EMPLOYEE_M....................................*
DATA:  BEGIN OF STATUS_Z8EMPLOYEE_M                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8EMPLOYEE_M                  .
CONTROLS: TCTRL_Z8EMPLOYEE_M
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8EMPLOYEE_M                  .
TABLES: Z8EMPLOYEE_M                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
