*&---------------------------------------------------------------------*
*& Include          Z8MMDS0100SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
SELECT-OPTIONS: s_werks FOR z8matplant_m-werks,
                           s_matnr FOR z8matplant_m-matnr,
                           s_mtart FOR z8material_m-mtart.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t02.
  SELECTION-SCREEN BEGIN OF LINE.

PARAMETERS: p_all   RADIOBUTTON GROUP rg DEFAULT 'X'.
SELECTION-SCREEN COMMENT (20) TEXT-all.

 PARAMETERS:  p_warn  RADIOBUTTON GROUP rg.
 SELECTION-SCREEN COMMENT (20) TEXT-war.

 PARAMETERS:  p_short RADIOBUTTON GROUP rg.
 SELECTION-SCREEN COMMENT (20) TEXT-sho.

SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b2.
