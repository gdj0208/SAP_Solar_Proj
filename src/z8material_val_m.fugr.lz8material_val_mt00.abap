*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8MATERIAL_VAL_M................................*
DATA:  BEGIN OF STATUS_Z8MATERIAL_VAL_M              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8MATERIAL_VAL_M              .
CONTROLS: TCTRL_Z8MATERIAL_VAL_M
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *Z8MATERIAL_VAL_M              .
TABLES: Z8MATERIAL_VAL_M               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
