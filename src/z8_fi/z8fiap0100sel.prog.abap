*&---------------------------------------------------------------------*
*& Include          Z8FIAP0100SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK bl1 WITH FRAME TITLE TEXT-bl1.
*  PARAMETERS pa_bukrs TYPE z8company_m-bukrs DEFAULT '1000' NO-DISPLAY.
*  SELECTION-SCREEN COMMENT 39(20) gv_butxt. "회사코드 텍스트

  SELECT-OPTIONS so_budat FOR z8fi_vendor-budat.

*  PARAMETERS pa_invno TYPE z8fi_vendor-xblnr MATCHCODE OBJECT z8sh_inv.
  PARAMETERS pa_invno TYPE z8mm_inv_h-inv_no.

  PARAMETERS pa_lifnr TYPE z8fi_vendor-lifnr.
  SELECTION-SCREEN COMMENT 45(40) gv_vent.

  PARAMETERS pa_bran TYPE z8fi_vendor-bupla.
  SELECTION-SCREEN COMMENT 39(20) gv_brant.

  PARAMETERS pa_belnr TYPE z8fi_vendor-belnr.
SELECTION-SCREEN END OF BLOCK bl1.

"입금상태는 라디오 버튼
SELECTION-SCREEN BEGIN OF BLOCK bl2 WITH FRAME TITLE TEXT-bl2.

  SELECTION-SCREEN BEGIN OF LINE.

    PARAMETERS: pa_r3 RADIOBUTTON GROUP r1 DEFAULT 'X'.
    SELECTION-SCREEN COMMENT (20) TEXT-r03.

    PARAMETERS: pa_r1 RADIOBUTTON GROUP r1.
    SELECTION-SCREEN COMMENT (20) TEXT-r01.

    PARAMETERS: pa_r2 RADIOBUTTON GROUP r1.
    SELECTION-SCREEN COMMENT (20) TEXT-r02.

  SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK bl2.
