*&---------------------------------------------------------------------*
*& Include          SAPMZ8FIDR0200_SEL
*&---------------------------------------------------------------------*




SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE TEXT-ck1.

  SELECT-OPTIONS so_date FOR z8fi_accdoc_h-budat.

  PARAMETERS: pa_blart TYPE z8fi_accdoc_h-blart.

  SELECTION-SCREEN COMMENT 40(25) gv_blart.

  SELECT-OPTIONS: so_belnr FOR z8fi_accdoc_h-belnr.

  SELECT-OPTIONS: so_gjahr FOR z8fi_accdoc_h-gjahr.

  PARAMETERS: pa_xblnr TYPE z8fi_accdoc_h-xblnr,
              pa_bupla TYPE z8fi_accdoc_i-bupla.



*  PARAMETERS: pa_stat  TYPE z8efi_status.


SELECTION-SCREEN END OF BLOCK bl1.
