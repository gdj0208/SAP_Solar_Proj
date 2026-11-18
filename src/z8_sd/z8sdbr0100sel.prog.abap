*&---------------------------------------------------------------------*
*& Include          Z8SDBR0100SEL
*&---------------------------------------------------------------------*

*조회 조건
SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t02.
  SELECT-OPTIONS:
                              s_audat  FOR z8sd_quotation_h-audat,
                              s_vbelnq FOR z8sd_quotation_h-vbeln_q MATCHCODE OBJECT Z8SH_QUOTATION_APPR,
                             s_vbelns FOR z8sd_so_h-vbeln_s MATCHCODE OBJECT z8sh_so,    " SO번호
                             s_kunnr  FOR z8sd_quotation_h-kunnr MATCHCODE OBJECT z8sh_customer,
                             s_bupla  FOR z8sd_quotation_h-bupla MATCHCODE OBJECT z8sh_branch.
SELECTION-SCREEN END OF BLOCK b2.

*진행 상태
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
  SELECTION-SCREEN BEGIN OF LINE.
    PARAMETERS: p_r1 RADIOBUTTON GROUP rg1  DEFAULT 'X'.
    SELECTION-SCREEN COMMENT 3(10) TEXT-c01 FOR FIELD p_r1.
    PARAMETERS: p_r2 RADIOBUTTON GROUP rg1.
    SELECTION-SCREEN COMMENT 17(10) TEXT-c02 FOR FIELD p_r2.
    PARAMETERS: p_r3 RADIOBUTTON GROUP rg1.
    SELECTION-SCREEN COMMENT 31(10) TEXT-c03 FOR FIELD p_r3.
    PARAMETERS: p_r4 RADIOBUTTON GROUP rg1.
    SELECTION-SCREEN COMMENT 45(10) TEXT-c04 FOR FIELD p_r4.
  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK b1.
