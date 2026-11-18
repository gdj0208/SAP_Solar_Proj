*&---------------------------------------------------------------------*
*& Include ZMMGR000TOP                              - Report ZMMGR000
*&---------------------------------------------------------------------*
REPORT zmmgr000.

TABLES :
  z8vendor_m,
  z8plant_m.

DATA :
  ok_code  TYPE sy-ucomm,
  gv_inv_sel type c value 'A',

  gv_werks TYPE z8plant_m-werks,
  gv_date  TYPE datum.


SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME
  TITLE TEXT-bl1.
  " 지사 입력란
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(13) TEXT-s03 FOR FIELD p_werks.
    PARAMETER p_werks TYPE z8plant_m-werks. "MATCHCODE OBJECT z8sh_plant.
    SELECTION-SCREEN COMMENT (25) gv_name. " 수량 단위
  SELECTION-SCREEN END OF LINE.

  " 입고 예정 일자 입력란
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(13) TEXT-s01 FOR FIELD s_date.
    SELECTION-SCREEN POSITION 12.
    SELECT-OPTIONS : s_date FOR gv_date.
  SELECTION-SCREEN END OF LINE.

" 청구서 수신 여부 (라디오 버튼)
  SELECTION-SCREEN BEGIN OF LINE.
    SELECTION-SCREEN COMMENT 1(13) TEXT-s04. " 텍스트 예: '청구서 상태'

    " 전체
    PARAMETER p_inv_a RADIOBUTTON GROUP rg1.
    SELECTION-SCREEN COMMENT 17(10) TEXT-r01 FOR FIELD p_inv_a.

    " 수신 (청구서 들어옴)
    PARAMETER p_inv_y RADIOBUTTON GROUP rg1.
    SELECTION-SCREEN COMMENT 30(10) TEXT-r02 FOR FIELD p_inv_y.

    " 미수신 (청구서 안 들어옴)
    PARAMETER p_inv_n RADIOBUTTON GROUP rg1  DEFAULT 'X'.
    SELECTION-SCREEN COMMENT 43(10) TEXT-r03 FOR FIELD p_inv_n.
  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK blk1.
