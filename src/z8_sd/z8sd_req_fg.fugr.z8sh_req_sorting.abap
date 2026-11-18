
FUNCTION z8sh_req_sorting.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      SHLP_TAB TYPE SHLP_DESCT
*"      RECORD_TAB STRUCTURE SEAHLPRES
*"  CHANGING
*"     VALUE(SHLP) TYPE SHLP_DESCR
*"     VALUE(CALLCONTROL) LIKE DDSHF4CTRL STRUCTURE DDSHF4CTRL
*"----------------------------------------------------------------------

  DATA: lt_req   TYPE STANDARD TABLE OF z8sd_quot_req,
        lv_cut   TYPE i,
        lv_count TYPE i.

  "----------------------------------------------------
  " STEP SELECT
  " 견적 요청 접수일 기준 최신순 조회
  "----------------------------------------------------
  IF callcontrol-step = 'SELECT'.

    CLEAR lt_req.

    "1. 접수일 최신순 DB 조회
    SELECT *
      FROM z8sd_quot_req
      INTO TABLE @lt_req
      ORDER BY request_date DESCENDING.

    "2. F4 검색조건 적용 및 결과 변환
    REFRESH record_tab.

    CALL FUNCTION 'F4UT_RESULTS_MAP'
      EXPORTING
        source_structure   = 'Z8SD_QUOT_REQ'
        apply_restrictions = 'X'
      TABLES
        shlp_tab           = shlp_tab
        record_tab         = record_tab
        source_tab         = lt_req
      CHANGING
        shlp               = shlp
        callcontrol        = callcontrol
      EXCEPTIONS
        illegal_structure  = 1
        OTHERS             = 2.

    IF sy-subrc <> 0.
      callcontrol-step = 'EXIT'.
      EXIT.
    ENDIF.

    "3. 접수일 내림차순 정렬
    CALL FUNCTION 'F4UT_PARAMETER_SORT'
      EXPORTING
        parameter_sort  = 'REQUEST_DATE'
        descending      = 'X'
        leading_columns = 0
      TABLES
        shlp_tab        = shlp_tab
        record_tab      = record_tab
      CHANGING
        shlp            = shlp
        callcontrol     = callcontrol.

    "4. SAP 표준 자동 정렬 비활성화
    "   기존 요청번호 오름차순 정렬 방지
    callcontrol-sortoff = 'X'.

    "5. 최대 조회 건수 제한
    DESCRIBE TABLE record_tab LINES lv_count.

    IF callcontrol-maxrecords > 0
       AND lv_count > callcontrol-maxrecords.

      callcontrol-maxexceed = 'X'.
      lv_cut = callcontrol-maxrecords + 1.

      DELETE record_tab FROM lv_cut.

    ELSE.
      CLEAR callcontrol-maxexceed.
    ENDIF.

    "6. F4 결과 화면으로 이동
    callcontrol-step = 'DISP'.

    EXIT.

  ENDIF.

  "----------------------------------------------------
  " STEP DISP
  " SAP 기본 자동 정렬 방지
  "----------------------------------------------------
  IF callcontrol-step = 'DISP'.

    callcontrol-sortoff = 'X'.

    EXIT.

  ENDIF.

ENDFUNCTION.
