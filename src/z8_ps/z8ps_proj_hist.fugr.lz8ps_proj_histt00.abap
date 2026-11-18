*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8PS_PROJ_HIST..................................*
DATA:  BEGIN OF STATUS_Z8PS_PROJ_HIST                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8PS_PROJ_HIST                .
CONTROLS: TCTRL_Z8PS_PROJ_HIST
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8PS_PROJ_HIST                .
TABLES: Z8PS_PROJ_HIST                 .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
