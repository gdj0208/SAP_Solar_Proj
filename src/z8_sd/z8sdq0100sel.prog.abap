*&---------------------------------------------------------------------*
*& Include          Z8SDQ0100SEL
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME.

  PARAMETERS pa_reqid TYPE Z8SD_QUOT_REQ-REQUEST_ID.
  SELECTION-SCREEN COMMENT 60(10) gv_txt1. "견적 요청 상태 텍스트

  SELECTION-SCREEN SKIP 1.

  PARAMETERS: pa_file TYPE rlgrap-filename  MODIF ID FUP.
SELECTION-SCREEN END OF BLOCK bl1.
