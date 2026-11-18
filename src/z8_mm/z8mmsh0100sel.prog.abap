*&---------------------------------------------------------------------*
*& Include          Z8MMSH0100SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
SELECT-OPTIONS: s_werks FOR z8matplant_m-werks,
                            s_matnr FOR z8matplant_m-matnr.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t02.
PARAMETERS: p_rate TYPE i DEFAULT 30 ,"OBLIGATORY,
                      p_days TYPE i DEFAULT 7. " OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-t03.
PARAMETERS: p_test RADIOBUTTON GROUP rb1 DEFAULT 'X',
                      p_exec RADIOBUTTON GROUP rb1.
SELECTION-SCREEN END OF BLOCK b3.
