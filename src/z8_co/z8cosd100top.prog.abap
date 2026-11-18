PROGRAM z8cosd100.

TABLES:
  z8sd_quotation_h,
  z8branch_m.
*DATA :
*    gv_curr type waers.


TYPES: BEGIN OF ty_quot,
         rej_code  TYPE z8sd_quotation_h-reject_reason,
         rej_text  TYPE val_text,
         pend_case TYPE i,
         netwr     TYPE z8sd_quotation_h-netwr,
         waerk     TYPE z8sd_quotation_h-waerk,
         pend_rate TYPE p DECIMALS 2.
TYPES : END OF ty_quot.

TYPES : BEGIN OF ty_branch,
          name      TYPE z8branch_m-name,
          bupla     TYPE z8sd_quotation_h-bupla,
          netwr     TYPE z8sd_quotation_h-netwr,
          waerk     TYPE z8sd_quotation_h-waerk,
          ord_rate  TYPE p DECIMALS 2,
          pend_rate TYPE p DECIMALS 2,
          ord_num   TYPE i,
          pend_num  TYPE i,
          prog_num  TYPE i,
          total_num TYPE i.
TYPES : END OF ty_branch.

TYPES : BEGIN OF ty_quot_det.
          INCLUDE STRUCTURE z8sd_quotation_h.
TYPES :
          rej_text TYPE val_text,
          name     TYPE z8branch_m-name,
          name1    TYPE z8customer_m-name1,
        END OF ty_quot_det.

DATA:
  gv_active_tab TYPE c LENGTH 1 VALUE '1', " 1: 사유별 ALV, 2: 지사별 ALV
  gv_total      TYPE i,
  gv_rej        TYPE z8sd_quotation_h-reject_reason,
  gv_bupla      TYPE z8sd_quotation_h-bupla,

  gt_return     TYPE TABLE OF ddshretval,
  gs_return     TYPE ddshretval,
  gt_dynp       TYPE TABLE OF dynpread,
  gs_dynp       TYPE dynpread.

DATA :
  gt_pend     TYPE TABLE OF ty_quot,
  gs_pend     TYPE ty_quot,

  gt_branch   TYPE TABLE OF ty_branch,
  gs_branch   TYPE ty_branch,

  gt_quot_det TYPE TABLE OF ty_quot_det,
  gs_quot_det TYPE TABLE OF ty_quot_det.

DATA: go_dock     TYPE REF TO cl_gui_custom_container,
      go_split    TYPE REF TO cl_gui_splitter_container,
      go_cont_top TYPE REF TO cl_gui_container,
      go_cont_bot TYPE REF TO cl_gui_container.

DATA: go_alv_rej TYPE REF TO cl_gui_alv_grid, " 상단: 사유별 ALV
      go_alv_bup TYPE REF TO cl_gui_alv_grid, " 상단: 지사별 ALV
      go_alv_bot TYPE REF TO cl_gui_alv_grid. " 하단: 상세 목록 ALV

DATA :
  gt_quot_fcat   TYPE lvc_t_fcat,
  gs_quot_fcat   TYPE lvc_s_fcat,
  gt_branch_fcat TYPE lvc_t_fcat,
  gs_branch_fcat TYPE lvc_s_fcat,
  gt_det_fcat    TYPE lvc_t_fcat,
  gs_det_fcat    TYPE lvc_s_fcat,

  gs_quot_layo   TYPE lvc_s_layo,
  gs_branch_layo TYPE lvc_s_layo,
  gs_det_layo    TYPE lvc_s_layo,

  gt_quot_sort   TYPE lvc_t_sort,
  gs_quot_sort   TYPE lvc_s_sort,
  gt_branch_sort TYPE lvc_t_sort,
  gs_branch_sort TYPE lvc_s_sort,
  gt_det_sort    TYPE lvc_t_sort,
  gs_det_sort    TYPE lvc_s_sort.


" 1. SBL (Search Block) - 110번 서브스크린
SELECTION-SCREEN BEGIN OF SCREEN 110 AS SUBSCREEN.
  SELECTION-SCREEN BEGIN OF BLOCK sbl WITH FRAME TITLE TEXT-s01.
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(15) TEXT-f03 FOR FIELD s_guebg.
      SELECTION-SCREEN POSITION 14.
      SELECT-OPTIONS: s_guebg FOR z8sd_quotation_h-guebg.      " 조회 기간

      SELECTION-SCREEN PUSHBUTTON 75(10) btn_srch USER-COMMAND srch.
    SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN END OF BLOCK sbl.

SELECTION-SCREEN END OF SCREEN 110.



" 2. RBL (Result Block) - 120번 서브스크린
SELECTION-SCREEN BEGIN OF SCREEN 120 AS SUBSCREEN.



  " 겉을 감싸는 전체 큰 프레임
  SELECTION-SCREEN BEGIN OF BLOCK main WITH FRAME TITLE TEXT-b00.

    " ============================================================
    " [1행] 타이틀(라벨) 영역
    " ============================================================
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(25) TEXT-b01.  " 총 기회비용
      SELECTION-SCREEN COMMENT 32(20) TEXT-b02. " 총 계약 건수
      SELECTION-SCREEN COMMENT 55(22) TEXT-b03. " 수주 건수
    SELECTION-SCREEN END OF LINE.

    " ============================================================
    " [1행] 데이터(파라미터 및 단위) 영역
    " ============================================================
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN POSITION 1.
      PARAMETERS p_tcost TYPE c LENGTH 20 MODIF ID res.
      SELECTION-SCREEN COMMENT 22(5) gv_curr.   " 'KRW'

      SELECTION-SCREEN POSITION 32.
      PARAMETERS p_ttcnt TYPE c LENGTH 10 MODIF ID res.
      SELECTION-SCREEN COMMENT 43(5) TEXT-cnt.  " '건'

      SELECTION-SCREEN POSITION 55.
      PARAMETERS p_wocnt TYPE c LENGTH 10 MODIF ID res.
      SELECTION-SCREEN COMMENT 66(5) TEXT-cnt.  " '건'
    SELECTION-SCREEN END OF LINE.

    SELECTION-SCREEN SKIP 1. " 상하단 여백 확보

    " ============================================================
    " [2행] 타이틀(라벨) 영역
    " ============================================================
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(25) TEXT-b04.  " 진행 건수
      SELECTION-SCREEN COMMENT 32(20) TEXT-b05. " 미체결 건수
      SELECTION-SCREEN COMMENT 55(22) TEXT-b06. " 미체결 비율(산식 확인)
    SELECTION-SCREEN END OF LINE.

    " ============================================================
    " [2행] 데이터(파라미터 및 단위) 영역
    " ============================================================
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN POSITION 1.
      PARAMETERS p_ipcnt TYPE c LENGTH 10 MODIF ID res.
      SELECTION-SCREEN COMMENT 12(5) TEXT-cnt.  " '건'

      SELECTION-SCREEN POSITION 32.
      PARAMETERS p_locnt TYPE c LENGTH 10 MODIF ID res.
      SELECTION-SCREEN COMMENT 43(5) TEXT-cnt.  " '건

      SELECTION-SCREEN POSITION 55.
      PARAMETERS p_lorat TYPE c LENGTH 10 MODIF ID res.
      SELECTION-SCREEN COMMENT 66(5) TEXT-per.  " '%'
    SELECTION-SCREEN END OF LINE.


  SELECTION-SCREEN END OF BLOCK main.
SELECTION-SCREEN END OF SCREEN 120.
