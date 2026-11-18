*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: Z8INSTALL_M.....................................*
DATA:  BEGIN OF STATUS_Z8INSTALL_M                   .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_Z8INSTALL_M                   .
CONTROLS: TCTRL_Z8INSTALL_M
            TYPE TABLEVIEW USING SCREEN '0002'.
*.........table declarations:.................................*
TABLES: *Z8INSTALL_M                   .
TABLES: Z8INSTALL_M                    .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
