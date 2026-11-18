*&---------------------------------------------------------------------*
*& Include          Z8SDBI0100SEL
*&---------------------------------------------------------------------*
"청구 유형.
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_r1 RADIOBUTTON GROUP rg1 DEFAULT 'X' USER-COMMAND ucf..
    SELECTION-SCREEN COMMENT 3(20) TEXT-c01. "FOR FIELD p_f1.
    PARAMETERS: p_r2 RADIOBUTTON GROUP rg1.
    SELECTION-SCREEN COMMENT 26(20) TEXT-c02. "FOR FIELD p_f1.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.
"조회조건
SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-t03.
  SELECT-OPTIONS:
  "선수금 (견적 기준)]
  s_qdat   FOR z8sd_quotation_h-audat MODIF ID quo,
  s_vbelnq FOR z8sd_quotation_h-vbeln_q
                  MATCHCODE OBJECT Z8SH_QUOTATION_APPR MODIF ID quo,

  "잔금기준 (SO 기준)
  s_sdat FOR z8sd_so_h-audat MODIF ID so,
  s_vbelns FOR z8sd_so_h-vbeln_s
             MATCHCODE OBJECT z8sh_so MODIF ID so,

"공통
 s_kunnr  FOR z8sd_billing_h-kunnr
             MATCHCODE OBJECT z8sh_customer,
 s_bupla  FOR z8sd_billing_h-bupla
             MATCHCODE OBJECT z8sh_branch.


*  s_bupla FOR z8sd_billing_h-bupla MATCHCODE OBJECT z8sh_branch,
*                                  s_kunnr FOR z8sd_billing_h-kunnr,
*                                  s_vgbel FOR z8sd_billing_h-vgbel,
*                                  s_refdat FOR z8sd_quotation_h-audat.
  SELECTION-SCREEN END OF BLOCK b3.

  "청구 상태.
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t02.
  SELECTION-SCREEN BEGIN OF LINE.
     PARAMETERS: p_st3 RADIOBUTTON GROUP rg2 DEFAULT 'X'.
    SELECTION-SCREEN COMMENT (20) TEXT-c05 FOR FIELD p_st3.
    PARAMETERS: p_st1 RADIOBUTTON GROUP rg2.
    SELECTION-SCREEN COMMENT (20) TEXT-c03 FOR FIELD p_st1.
    PARAMETERS: p_st2 RADIOBUTTON GROUP rg2.
    SELECTION-SCREEN COMMENT (20) TEXT-c04 FOR FIELD p_st2.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b2.


  "진행현황 프로그램에서 청구번호 넘길 수 있도록.
PARAMETERS: p_detail TYPE z8sd_billing_h-vbeln NO-DISPLAY.
