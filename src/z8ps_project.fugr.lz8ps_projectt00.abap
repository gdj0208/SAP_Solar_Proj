*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8PS_PROJECT....................................*
DATA:  BEGIN OF STATUS_Z8PS_PROJECT                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8PS_PROJECT                  .
CONTROLS: TCTRL_Z8PS_PROJECT
            TYPE TABLEVIEW USING SCREEN '0002'.
*.........table declarations:.................................*
TABLES: *Z8PS_PROJECT                  .
TABLES: Z8PS_PROJECT                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
