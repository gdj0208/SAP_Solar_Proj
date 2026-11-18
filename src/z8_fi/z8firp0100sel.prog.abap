*&---------------------------------------------------------------------*
*& Include          Z8FIRP0100SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE TEXT-bl1.

  SELECTION-SCREEN BEGIN OF LINE.

    PARAMETERS rb_cust RADIOBUTTON GROUP rg1 DEFAULT 'X' USER-COMMAND ucomm.
    SELECTION-SCREEN COMMENT (20) TEXT-b01.

    PARAMETERS rb_vend RADIOBUTTON GROUP rg1.
    SELECTION-SCREEN COMMENT (20) TEXT-b02.

  SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK bl1.

"고객
SELECTION-SCREEN BEGIN OF BLOCK bl2 WITH FRAME TITLE TEXT-bl2.
*  PARAMETERS: p_cbukrs TYPE z8fi_customer-bukrs DEFAULT '1000' MODIF ID ar1.
*  SELECTION-SCREEN COMMENT 39(20) gv_cbut MODIF ID ar1. "회사코드 텍스트

  SELECT-OPTIONS:
  s_cbudat FOR z8fi_customer-budat MODIF ID ar1,
  s_kunnr FOR z8fi_customer-kunnr MODIF ID ar1,
  s_cbupla FOR z8fi_customer-bupla MODIF ID ar1.
SELECTION-SCREEN END OF BLOCK bl2.
*  SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN BEGIN OF BLOCK bl3 WITH FRAME TITLE TEXT-bl3.
  SELECTION-SCREEN BEGIN OF LINE.

    PARAMETERS rb_arall RADIOBUTTON GROUP rg2 DEFAULT 'X' USER-COMMAND ucomm MODIF ID ar1.
    SELECTION-SCREEN COMMENT (20) TEXT-r01 FOR FIELD rb_arall MODIF ID ar1.
    PARAMETERS rb_arop RADIOBUTTON GROUP rg2 MODIF ID ar1.
    SELECTION-SCREEN COMMENT (20) TEXT-r02 FOR FIELD rb_arop MODIF ID ar1.
    PARAMETERS rb_arcl RADIOBUTTON GROUP rg2 MODIF ID ar1.
    SELECTION-SCREEN COMMENT (20) TEXT-r03 FOR FIELD rb_arcl MODIF ID ar1.

  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK bl3.

"공급업체
SELECTION-SCREEN BEGIN OF BLOCK bl4 WITH FRAME TITLE TEXT-bl4.
*  PARAMETERS: p_vbukrs TYPE z8fi_vendor-bukrs DEFAULT '1000' MODIF ID ap1.
*  SELECTION-SCREEN COMMENT 39(20) gv_vbut MODIF ID ap1. "회사코드 텍스트

  SELECT-OPTIONS:
  s_vbudat FOR z8fi_vendor-budat MODIF ID ap1,
  s_lifnr FOR z8fi_vendor-lifnr MODIF ID ap1,
  s_vbupla FOR z8fi_vendor-bupla MODIF ID ap1.
SELECTION-SCREEN END OF BLOCK bl4.

*  SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN BEGIN OF BLOCK bl5 WITH FRAME TITLE TEXT-bl5.

  SELECTION-SCREEN BEGIN OF LINE.

    PARAMETERS rb_apall RADIOBUTTON GROUP rg3 DEFAULT 'X' MODIF ID ap1.
    SELECTION-SCREEN COMMENT (20) TEXT-p01 FOR FIELD rb_apall MODIF ID ap1.

    PARAMETERS rb_apop RADIOBUTTON GROUP rg3 MODIF ID ap1.
    SELECTION-SCREEN COMMENT (20) TEXT-p02 FOR FIELD rb_apop MODIF ID ap1.

    PARAMETERS rb_apcl RADIOBUTTON GROUP rg3 MODIF ID ap1.
    SELECTION-SCREEN COMMENT (20) TEXT-p03 FOR FIELD rb_apcl MODIF ID ap1.

  SELECTION-SCREEN END OF LINE.


SELECTION-SCREEN END OF BLOCK bl5.



*SELECTION-SCREEN BEGIN OF BLOCK b01
*                 WITH FRAME TITLE text-t01.
*SELECTION-SCREEN BEGIN OF LINE.
*PARAMETERS:
*  rb_cust RADIOBUTTON GROUP rg1 DEFAULT 'X'
*        USER-COMMAND rad,
*  rb_vend RADIOBUTTON GROUP rg1.
*
*SELECTION-SCREEN END OF BLOCK b01.
*
*
**---------------------------------------------------------------------*
** 공통 조회조건
**---------------------------------------------------------------------*
*SELECTION-SCREEN BEGIN OF BLOCK b02
*                 WITH FRAME TITLE text-t02.
*
*PARAMETERS:
*  pa_bukrs TYPE z8fi_customer-bukrs
*           DEFAULT '1000'
*           OBLIGATORY.
*
*SELECT-OPTIONS:
*  so_bupla FOR z8fi_customer-bupla.
*
*SELECTION-SCREEN END OF BLOCK b02.
*
*
**---------------------------------------------------------------------*
** 상세 조회조건
**---------------------------------------------------------------------*
*SELECTION-SCREEN BEGIN OF BLOCK b03
*                 WITH FRAME TITLE text-t03.
*
*"AR 조회조건
*SELECT-OPTIONS:
*  so_kunnr FOR z8fi_customer-kunnr MODIF ID ar1,
*  so_arbud FOR z8fi_customer-budat MODIF ID ar1.
*
*PARAMETERS:
*  pa_arall RADIOBUTTON GROUP rga DEFAULT 'X' MODIF ID ar1,
*  pa_aropn RADIOBUTTON GROUP rga             MODIF ID ar1,
*  pa_arcls RADIOBUTTON GROUP rga             MODIF ID ar1.
*
*
*"AP 조회조건
*SELECT-OPTIONS:
*  so_lifnr FOR z8fi_vendor-lifnr MODIF ID ap1,
*  so_apbud FOR z8fi_vendor-budat MODIF ID ap1.
*
*PARAMETERS:
*  pa_apall RADIOBUTTON GROUP rgp DEFAULT 'X' MODIF ID ap1,
*  pa_apopn RADIOBUTTON GROUP rgp             MODIF ID ap1,
*  pa_apcls RADIOBUTTON GROUP rgp             MODIF ID ap1.
*
*SELECTION-SCREEN END OF BLOCK b03.
