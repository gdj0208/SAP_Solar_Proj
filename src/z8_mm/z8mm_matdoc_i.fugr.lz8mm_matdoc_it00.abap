*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8MM_MATDOC_I...................................*
DATA:  BEGIN OF STATUS_Z8MM_MATDOC_I                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8MM_MATDOC_I                 .
CONTROLS: TCTRL_Z8MM_MATDOC_I
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8MM_MATDOC_I                 .
TABLES: Z8MM_MATDOC_I                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
