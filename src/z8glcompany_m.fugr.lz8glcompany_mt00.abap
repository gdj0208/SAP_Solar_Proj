*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8GLCOMPANY_M...................................*
DATA:  BEGIN OF STATUS_Z8GLCOMPANY_M                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8GLCOMPANY_M                 .
CONTROLS: TCTRL_Z8GLCOMPANY_M
            TYPE TABLEVIEW USING SCREEN '0002'.
*.........table declarations:.................................*
TABLES: *Z8GLCOMPANY_M                 .
TABLES: Z8GLCOMPANY_M                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
