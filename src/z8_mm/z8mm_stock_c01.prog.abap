*&---------------------------------------------------------------------*
*& Include Z8MM_STOCK_C01
*&---------------------------------------------------------------------*
*& 재고·단가·운송일수 조회와 PR 추적 상태 계산(lcl_mm_stock). DB 저장 없음
*& 사용: ZMMPR0100, ZMMPR0110, ZMMPO0110
*& 담당: MM(이규빈)
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-01  이규빈  최초 개발   최초 작성: 재고·단가·운송일수 조회와 PR 추적 상태 계산
*& 2026-10-30  이규빈  수정사항    재고 계산 보완
*& 2026-11-08  이규빈  인수인계    인수인계 정리:  헤더·주석 정리
*&---------------------------------------------------------------------*

" Z8MM_STOCK_C01: COMMIT/ROLLBACK과 공통 잠금 해제는 호출한 F01에서 담당한다.
CLASS lcl_mm_stock DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES: ty_plants TYPE RANGE OF z8mm_pr-werks,
      ty_locs TYPE RANGE OF z8mm_pr-lgort,
      ty_mats TYPE RANGE OF z8mm_pr-matnr.
    TYPES ty_vendors TYPE RANGE OF z8mm_pr-lifnr.
    TYPES BEGIN OF ty_trace.
    INCLUDE TYPE z8mm_pr.
    TYPES: procstat TYPE z8mm_po_h-procstat,
      elikz TYPE z8mm_po_i-elikz,
      status TYPE c LENGTH 9,
      END OF ty_trace,
      ty_traces TYPE STANDARD TABLE OF ty_trace WITH EMPTY KEY.
    CLASS-METHODS requests IMPORTING plants TYPE ty_plants OPTIONAL
      locs TYPE ty_locs OPTIONAL mats TYPE ty_mats OPTIONAL vendors TYPE ty_vendors OPTIONAL
      RETURNING VALUE(result) TYPE ty_traces.
    CLASS-METHODS location IMPORTING key TYPE lcl_mm_common=>ty_key
      RETURNING VALUE(result) TYPE z8material_stk_m RAISING lcx_mm.
    CLASS-METHODS company IMPORTING plant TYPE z8plant_m-werks
      RETURNING VALUE(result) TYPE z8mm_po_h-bukrs RAISING lcx_mm.
    CLASS-METHODS route IMPORTING source TYPE z8plant_m-region_code
      dest TYPE z8plant_m-region_code RETURNING VALUE(days) TYPE i RAISING lcx_mm.
    CLASS-METHODS price IMPORTING material TYPE z8mm_pr-matnr vendor TYPE z8mm_pr-lifnr
      RETURNING VALUE(result) TYPE z8purch_info_m RAISING lcx_mm.
    CLASS-METHODS eta IMPORTING vendor TYPE z8mm_pr-lifnr plant TYPE z8mm_pr-werks
      RETURNING VALUE(result) TYPE sy-datum RAISING lcx_mm.
    CLASS-METHODS valuation IMPORTING key TYPE lcl_mm_common=>ty_key
      RETURNING VALUE(result) TYPE z8material_val_m RAISING lcx_mm.
ENDCLASS.
CLASS lcl_mm_stock IMPLEMENTATION.

  " ------------------------------------------------------------
  " METHOD requests : PR을 조회하고 연결 PO·취소 여부로 추적용 상태를 붙인다.
  " ------------------------------------------------------------
  METHOD requests.
    SELECT * FROM z8mm_pr WHERE werks IN @plants AND lgort IN @locs
      AND matnr IN @mats AND lifnr IN @vendors INTO TABLE @DATA(prs).
    " 연결 PO의 헤더 상태·품목 입고표시를 한 번에 읽어 두고 PR마다 찾아 붙인다(루프 안 SELECT 없음).
    TYPES: BEGIN OF ty_po_head,
             ebeln TYPE z8mm_po_h-ebeln,
             procstat TYPE z8mm_po_h-procstat,
           END OF ty_po_head,
           BEGIN OF ty_po_item,
             ebeln TYPE z8mm_po_i-ebeln,
             ebelp TYPE z8mm_po_i-ebelp,
             elikz TYPE z8mm_po_i-elikz,
           END OF ty_po_item.
    DATA: po_heads TYPE SORTED TABLE OF ty_po_head WITH NON-UNIQUE KEY ebeln,
          po_items TYPE SORTED TABLE OF ty_po_item WITH NON-UNIQUE KEY ebeln ebelp.
    DATA(linked) = prs.
    DELETE linked WHERE ebeln IS INITIAL.
    IF linked IS NOT INITIAL.
      SELECT ebeln, procstat FROM z8mm_po_h FOR ALL ENTRIES IN @linked
        WHERE ebeln = @linked-ebeln INTO CORRESPONDING FIELDS OF TABLE @po_heads.
      SELECT ebeln, ebelp, elikz FROM z8mm_po_i FOR ALL ENTRIES IN @linked
        WHERE ebeln = @linked-ebeln AND ebelp = @linked-ebelp INTO CORRESPONDING FIELDS OF TABLE @po_items.
    ENDIF.
    LOOP AT prs INTO DATA(pr).
      DATA(row) = CORRESPONDING ty_trace( pr ).
      IF pr-ebeln IS NOT INITIAL.
        READ TABLE po_heads INTO DATA(po_head) WITH TABLE KEY ebeln = pr-ebeln.
        IF sy-subrc = 0.
          row-procstat = po_head-procstat.
        ENDIF.
        READ TABLE po_items INTO DATA(po_item) WITH TABLE KEY ebeln = pr-ebeln ebelp = pr-ebelp.
        IF sy-subrc = 0.
          row-elikz = po_item-elikz.
        ENDIF.
      ENDIF.
      IF pr-loekz IS NOT INITIAL.
        row-status = 'CANCELLED'.
      ELSEIF pr-ebeln IS NOT INITIAL.
        row-status = 'APPROVED'.
      ELSE.
        row-status = 'PENDING'.
      ENDIF.
      APPEND row TO result.
    ENDLOOP.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD location : 자재·플랜트·저장위치와 재고 수량·단위가 유효한지 검사한다.
  " ------------------------------------------------------------
  METHOD location.
    IF key-matnr IS INITIAL OR key-werks IS INITIAL OR key-lgort IS INITIAL.
      lcl_mm_common=>fail( `자재·플랜트·저장위치는 필수입니다.` ).
    ENDIF.
    SELECT SINGLE meins FROM z8material_m WHERE matnr = @key-matnr INTO @DATA(unit).
    IF sy-subrc <> 0 OR unit IS INITIAL.
      lcl_mm_common=>fail( `자재 기본단위 없음` ).
    ENDIF.
    SELECT SINGLE * FROM z8matplant_m WHERE matnr = @key-matnr
      AND werks = @key-werks AND lgort = @key-lgort INTO @DATA(mp).
    IF sy-subrc <> 0 OR mp-meins <> unit OR mp-eisbe < 0.
      lcl_mm_common=>fail( `자재/플랜트/저장위치 기준정보 또는 단위·안전재고 오류` ).
    ENDIF.
    SELECT SINGLE * FROM z8material_stk_m WHERE matnr = @key-matnr
      AND werks = @key-werks AND lgort = @key-lgort INTO @result.
    IF sy-subrc <> 0.
      result = VALUE #( mandt = sy-mandt matnr = key-matnr werks = key-werks
        lgort = key-lgort meins = unit ).
    ENDIF.
    IF result-meins <> unit OR result-labst < 0 OR result-zzrsvqty < 0
      OR result-zzrsvqty > result-labst OR result-insme < 0 OR result-umlme < 0.
      lcl_mm_common=>fail( `재고 수량 또는 기본단위 불일치` ).
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD company : 플랜트의 지사 연결을 통해 회사코드를 찾아 검증한다.
  " ------------------------------------------------------------
  METHOD company.
    SELECT SINGLE bupla FROM z8plant_m WHERE werks = @plant INTO @DATA(branch).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( |플랜트 { plant } 없음| ).
    ENDIF.
    SELECT bukrs FROM z8branch_m WHERE branch = @branch INTO TABLE @DATA(companies).
    IF lines( companies ) <> 1.
      lcl_mm_common=>fail( |플랜트 { plant }의 지사/회사 연결을 하나로 확정하세요.| ).
    ENDIF.
    result = companies[ 1 ]-bukrs.
    SELECT SINGLE bukrs FROM z8company_m WHERE bukrs = @result INTO @DATA(found).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `회사 마스터가 없습니다.` ).
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD route : 출발·도착 지역의 활성 경로 한 건에서 운송일수를 구한다.
  " ------------------------------------------------------------
  METHOD route.
    IF source IS INITIAL OR dest IS INITIAL.
      lcl_mm_common=>fail( `출발/도착 지역코드 없음` ).
    ENDIF.
    IF source = dest.
      days = 0.
      RETURN.
    ENDIF.
    SELECT est_transit_days FROM z8route_m WHERE from_region = @source
      AND to_region = @dest AND ( use_yn = 'X' OR use_yn = 'Y' ) INTO TABLE @DATA(routes).
    IF lines( routes ) <> 1.
      lcl_mm_common=>fail( `방향별 활성 루트를 한 건으로 등록하세요.` ).
    ENDIF.
    days = routes[ 1 ]-est_transit_days.
    IF days < 0.
      lcl_mm_common=>fail( `운송일수는 음수일 수 없습니다.` ).
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD price : 자재+공급업체 구매정보의 가격·가격단위·통화·단위를 검사해 반환한다.
  " ------------------------------------------------------------
  METHOD price.
    SELECT SINGLE * FROM z8purch_info_m WHERE matnr = @material AND lifnr = @vendor INTO @result.
    IF sy-subrc <> 0 OR result-netpr <= 0 OR result-peinh <= 0 OR result-waers IS INITIAL.
      lcl_mm_common=>fail( `유효한 공급업체 구매정보(가격/가격단위/통화)가 필요합니다.` ).
    ENDIF.
    SELECT SINGLE meins FROM z8material_m WHERE matnr = @material INTO @DATA(unit).
    IF sy-subrc <> 0 OR unit <> result-meins.
      lcl_mm_common=>fail( `구매단위와 자재 기본단위가 다릅니다.` ).
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD eta : 오늘에 구매 준비 1일과 업체→플랜트 운송일수를 더해 도착일을 구한다.
  " ------------------------------------------------------------
  METHOD eta.
    SELECT SINGLE region_code FROM z8vendor_m WHERE lifnr = @vendor INTO @DATA(src).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `공급업체 마스터 없음` ).
    ENDIF.
    SELECT SINGLE region_code FROM z8plant_m WHERE werks = @plant INTO @DATA(dst).
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `플랜트 마스터 없음` ).
    ENDIF.
    DATA(days) = lcl_mm_stock=>route( source = src dest = dst ).
    result = sy-datum + 1 + days.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD valuation : 플랜트 평가영역의 자재 평가정보와 가격관리 S/V를 검증해 반환한다.
  " ------------------------------------------------------------
  METHOD valuation.
    SELECT SINGLE bwkey FROM z8plant_m WHERE werks = @key-werks INTO @DATA(bwkey).
    IF sy-subrc <> 0 OR bwkey IS INITIAL.
      lcl_mm_common=>fail( `플랜트 평가영역 없음` ).
    ENDIF.
    SELECT SINGLE * FROM z8material_val_m WHERE matnr = @key-matnr AND bwkey = @bwkey INTO @result.
    IF sy-subrc <> 0 OR result-peinh <= 0 OR result-waers IS INITIAL
      OR ( result-vprsv <> 'S' AND result-vprsv <> 'V' ).
      lcl_mm_common=>fail( `평가정보·가격단위·통화·가격관리 S/V를 확인하세요.` ).
    ENDIF.
    IF result-stprs < 0 OR result-verpr < 0.
      lcl_mm_common=>fail( `음수 평가가격 오류` ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
