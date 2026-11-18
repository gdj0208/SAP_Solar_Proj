*&---------------------------------------------------------------------*
*& Include Z8MM_STO_BASE
*&---------------------------------------------------------------------*
*& STO 프로그램용 기본 클래스: 오류·잠금·STO 번호 채번·재고 조회
*& (lcl_mm_common·lcl_mm_stock 중 STO에 필요한 기능만 둔 축소판)
*& 사용: ZMMSTO0100, Z8MMB0100
*& 담당: MM(이규빈)
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-17  이규빈  최초 개발   최초 작성: STO 프로그램용 오류·잠금·채번·재고 조회
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" STO 전용 공통기능. SO/PR/조달계획에 의존하지 않으며 저장 확정은 호출부가 담당한다.
CLASS lcx_mm DEFINITION INHERITING FROM cx_static_check.
  PUBLIC SECTION.
    DATA detail TYPE string READ-ONLY.
    METHODS constructor IMPORTING iv_text TYPE string.
ENDCLASS.
CLASS lcx_mm IMPLEMENTATION.

  " ------------------------------------------------------------
  " METHOD constructor : 오류 객체를 만들면서 전달받은 설명문을 보관한다.
  " ------------------------------------------------------------
  METHOD constructor.
    super->constructor( ).
    detail = iv_text.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_mm_common DEFINITION FINAL.
  PUBLIC SECTION.
    TYPES: ty_items TYPE STANDARD TABLE OF z8mm_po_i WITH EMPTY KEY,
      BEGIN OF ty_key,
      matnr TYPE z8mm_po_i-matnr,
      werks TYPE z8mm_po_i-werks,
      lgort TYPE z8mm_po_i-lgort,
      END OF ty_key.
    CLASS-METHODS fail IMPORTING text TYPE string RAISING lcx_mm.
    CLASS-METHODS lock RAISING lcx_mm.
    CLASS-METHODS unlock.
    CLASS-METHODS require_lock RAISING lcx_mm.
    CLASS-METHODS number IMPORTING object TYPE nriv-object
      RETURNING VALUE(result) TYPE z8mm_po_h-ebeln RAISING lcx_mm.
  PRIVATE SECTION.
    CLASS-DATA locked TYPE abap_bool.
ENDCLASS.
CLASS lcl_mm_common IMPLEMENTATION.

  " ------------------------------------------------------------
  " METHOD fail : 업무 오류를 발생시켜 현재 처리를 멈추고 상위 CATCH로 전달한다.
  " ------------------------------------------------------------
  METHOD fail.
    RAISE EXCEPTION TYPE lcx_mm EXPORTING iv_text = text.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD lock : 다른 실행과 저장이 겹치지 않도록 공통 잠금을 확보한다.
  " ------------------------------------------------------------
  METHOD lock.
    IF locked = abap_true.
      lcl_mm_common=>fail( `중첩 저장 요청입니다.` ).
    ENDIF.
    " 잠금 해제 함수까지 먼저 확인한다. 저장 후 함수 누락으로 실패하는 일을 막는다.
    DATA functions TYPE STANDARD TABLE OF tfdir-funcname WITH EMPTY KEY.
    functions = VALUE #( ( 'ENQUEUE_EZ8MATSTK' ) ( 'DEQUEUE_EZ8MATSTK' ) ).
    LOOP AT functions INTO DATA(function_name).
      SELECT SINGLE funcname FROM tfdir WHERE funcname = @function_name INTO @DATA(found_function).
      IF sy-subrc <> 0.
        lcl_mm_common=>fail( |필수 잠금 함수 { function_name } 없음. SE11 활성화를 확인하세요.| ).
      ENDIF.
    ENDLOOP.
    CALL FUNCTION 'ENQUEUE_EZ8MATSTK'
      EXPORTING mandt = sy-mandt _scope = '1' _wait = space
      EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `다른 사용자가 재고를 처리 중입니다. 잠시 후 다시 실행하세요.` ).
    ENDIF.
    locked = abap_true.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD unlock : 이 클래스가 잡은 잠금을 해제하고 잠금 상태 변수를 비운다.
  " ------------------------------------------------------------
  METHOD unlock.
    IF locked = abap_true.
      CALL FUNCTION 'DEQUEUE_EZ8MATSTK'
        EXPORTING mandt = sy-mandt _scope = '1' _synchron = 'X'.
    ENDIF.
    CLEAR locked.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD require_lock : 공통 잠금을 잡은 상태에서 저장 기능을 호출했는지 검사한다.
  " ------------------------------------------------------------
  METHOD require_lock.
    IF locked <> abap_true.
      lcl_mm_common=>fail( `저장 전 재고 잠금이 필요합니다.` ).
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD number : SNRO 번호범위의 다음 번호를 받아 문서번호로 반환한다.
  " ------------------------------------------------------------
  METHOD number.
    IF object <> 'Z8MMSTON'.
      lcl_mm_common=>fail( `STO 번호범위만 지원합니다.` ).
    ENDIF.
    DATA num TYPE nriv-nrlevel.
    DATA digits TYPE n LENGTH 8.
    " SNRO 내부번호 구간 01에서 다음 번호를 받는다. 여기서 문서가 저장되는 것은 아니다.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING object = object nr_range_nr = '01'
      IMPORTING number = num
      EXCEPTIONS interval_not_found = 1 number_range_not_intern = 2 object_not_found = 3
      quantity_is_0 = 4 quantity_is_not_1 = 5 interval_overflow = 6 buffer_overflow = 7 OTHERS = 8.
    IF sy-subrc <> 0 OR num < 1 OR num > 99999999.
      lcl_mm_common=>fail( `STO 번호범위 Z8MMSTON/01을 확인하세요.` ).
    ENDIF.
    digits = num.
    result = |ST{ digits }|.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_mm_stock DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS location IMPORTING key TYPE lcl_mm_common=>ty_key
      RETURNING VALUE(result) TYPE z8material_stk_m RAISING lcx_mm.
    CLASS-METHODS company IMPORTING plant TYPE z8plant_m-werks
      RETURNING VALUE(result) TYPE z8mm_po_h-bukrs RAISING lcx_mm.
    CLASS-METHODS route IMPORTING source TYPE z8plant_m-region_code
      dest TYPE z8plant_m-region_code RETURNING VALUE(days) TYPE i RAISING lcx_mm.
ENDCLASS.
CLASS lcl_mm_stock IMPLEMENTATION.

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
    SELECT est_transit_days FROM z8route_m
      WHERE from_region = @source AND to_region = @dest AND ( use_yn = 'X' OR use_yn = 'Y' )
      INTO TABLE @DATA(routes).
    IF lines( routes ) <> 1.
      lcl_mm_common=>fail( `방향별 활성 루트를 한 건으로 등록하세요.` ).
    ENDIF.
    days = routes[ 1 ]-est_transit_days.
    IF days < 0.
      lcl_mm_common=>fail( `운송일수는 음수일 수 없습니다.` ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
