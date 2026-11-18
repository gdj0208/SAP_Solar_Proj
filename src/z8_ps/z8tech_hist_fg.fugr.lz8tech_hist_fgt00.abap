*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8PS_TECH_HIST..................................*
DATA:  BEGIN OF STATUS_Z8PS_TECH_HIST                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8PS_TECH_HIST                .
CONTROLS: TCTRL_Z8PS_TECH_HIST
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8PS_TECH_HIST                .
TABLES: Z8PS_TECH_HIST                 .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
