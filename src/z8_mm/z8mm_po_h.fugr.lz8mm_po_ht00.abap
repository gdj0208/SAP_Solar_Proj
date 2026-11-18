*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8MM_PO_H.......................................*
DATA:  BEGIN OF STATUS_Z8MM_PO_H                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8MM_PO_H                     .
CONTROLS: TCTRL_Z8MM_PO_H
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8MM_PO_H                     .
TABLES: Z8MM_PO_H                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
