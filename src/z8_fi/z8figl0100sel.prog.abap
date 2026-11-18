*&---------------------------------------------------------------------*
*& Include          Z8FIGL0100SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE TEXT-bl1.
*  PARAMETERS pa_bukrs TYPE z8fi_accdoc_h-bukrs. "DEFAULT '1000'.
*  SELECTION-SCREEN COMMENT 39(20) gv_butxt. "회사코드 텍스트

  PARAMETERS pa_gjahr TYPE z8fi_accdoc_h-gjahr OBLIGATORY.

*  PARAMETERS pa_budat TYPE z8fi_accdoc_h-budat OBLIGATORY.

  SELECT-OPTIONS so_monat FOR z8fi_accdoc_h-monat.

  SELECT-OPTIONS so_bran FOR z8fi_accdoc_i-bupla.

  SELECT-OPTIONS so_saknr FOR z8glacc_m-saknr MATCHCODE OBJECT z8sh_glacc.

  SELECTION-SCREEN SKIP 1.

  PARAMETERS cb_unuse AS CHECKBOX.

SELECTION-SCREEN END OF BLOCK bl1.
