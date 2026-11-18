*---------------------------------------------------------------------*
*    program for:   TABLEFRAME_Z8TECH_HIST_FG
*---------------------------------------------------------------------*
FUNCTION TABLEFRAME_Z8TECH_HIST_FG     .

  PERFORM TABLEFRAME TABLES X_HEADER X_NAMTAB DBA_SELLIST DPL_SELLIST
                            EXCL_CUA_FUNCT
                     USING  CORR_NUMBER VIEW_ACTION VIEW_NAME.

ENDFUNCTION.
