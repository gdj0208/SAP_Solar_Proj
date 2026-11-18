*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8MATERIAL_STK_M................................*
DATA:  BEGIN OF STATUS_Z8MATERIAL_STK_M              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8MATERIAL_STK_M              .
CONTROLS: TCTRL_Z8MATERIAL_STK_M
            TYPE TABLEVIEW USING SCREEN '0100'.
*.........table declarations:.................................*
TABLES: *Z8MATERIAL_STK_M              .
TABLES: Z8MATERIAL_STK_M               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
