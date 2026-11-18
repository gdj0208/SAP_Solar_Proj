*&---------------------------------------------------------------------*
*& Include Z8MM_COMMON_C01
*&---------------------------------------------------------------------*
*& MM 공통 기본 클래스: 오류(lcx_mm), 잠금(lock·lock_doc·unlock), 문서번호 채번(PR·PO·STO)
*& 사용: ZMMPR0100, ZMMPR0110, ZMMPO0110
*& 담당: MM(이규빈)
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-01  이규빈  최초 개발   최초 작성: MM 공통 오류·잠금·문서번호 채번
*& 2026-10-30  이규빈  수정사항    저장·잠금 공통 처리 보완
*& 2026-11-05  이규빈  변경사항    재고를 안 바꾸는 저장은 문서 잠금(lock_doc)만 사용
*& 2026-11-08  이규빈  인수인계    인수인계 정리:  헤더·주석 정리
*&---------------------------------------------------------------------*

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
    TYPES: ty_prs TYPE STANDARD TABLE OF z8mm_pr WITH EMPTY KEY,
      ty_items TYPE STANDARD TABLE OF z8mm_po_i WITH EMPTY KEY,
      BEGIN OF ty_key,
      matnr TYPE z8mm_pr-matnr,
      werks TYPE z8mm_pr-werks,
      lgort TYPE z8mm_pr-lgort,
      END OF ty_key.
    CLASS-METHODS fail IMPORTING text TYPE string RAISING lcx_mm.
    CLASS-METHODS lock RAISING lcx_mm.
    CLASS-METHODS lock_doc RAISING lcx_mm.          " 재고를 안 바꾸는 저장(PR 저장·변경·취소, PO 취소)용
    CLASS-METHODS unlock.
    CLASS-METHODS number IMPORTING object TYPE nriv-object
      RETURNING VALUE(result) TYPE z8mm_po_h-ebeln RAISING lcx_mm.
    CLASS-METHODS require_lock RAISING lcx_mm.
    CLASS-METHODS require_doc_lock RAISING lcx_mm.
  PRIVATE SECTION.
    CLASS-DATA locked TYPE abap_bool.
    CLASS-DATA stock_locked TYPE abap_bool.
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
    DATA functions TYPE STANDARD TABLE OF tfdir-funcname WITH EMPTY KEY.
    functions = VALUE #( ( 'ENQUEUE_E_TABLE' ) ( 'DEQUEUE_E_TABLE' )
      ( 'ENQUEUE_EZ8MATSTK' ) ( 'DEQUEUE_EZ8MATSTK' ) ).
    " 필요한 잠금 함수를 한 번에 읽고, 빠진 함수가 있으면 그 이름으로 알린다.
    DATA found_functions TYPE STANDARD TABLE OF tfdir-funcname WITH EMPTY KEY.
    SELECT funcname FROM tfdir FOR ALL ENTRIES IN @functions
      WHERE funcname = @functions-table_line INTO TABLE @found_functions.
    LOOP AT functions INTO DATA(function_name).
      IF NOT line_exists( found_functions[ table_line = function_name ] ).
        lcl_mm_common=>fail( |필수 잠금 함수 { function_name } 없음. SE11 활성화 확인| ).
      ENDIF.
    ENDLOOP.
    " MM 문서 저장 공용 잠금: Z8MM_PROC_PLAN 테이블 이름을 잠금 키로만 쓴다(테이블 데이터는 읽지 않음).
    CALL FUNCTION 'ENQUEUE_E_TABLE'
      EXPORTING tabname = 'Z8MM_PROC_PLAN' _scope = '1' _wait = space
      EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `다른 사용자가 조달 처리 중입니다.` ).
    ENDIF.
    locked = abap_true.
    CALL FUNCTION 'ENQUEUE_EZ8MATSTK'
      EXPORTING mandt = sy-mandt _scope = '1' _wait = space
      EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3.
    IF sy-subrc <> 0.
      lcl_mm_common=>unlock( ).
      lcl_mm_common=>fail( `재고 처리 중입니다. 다시 실행하세요.` ).
    ENDIF.
    stock_locked = abap_true.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD unlock : 이 클래스가 잡은 잠금을 해제하고 잠금 상태 변수를 비운다.
  " ------------------------------------------------------------
  METHOD unlock.
    IF stock_locked = abap_true.
      CALL FUNCTION 'DEQUEUE_EZ8MATSTK'
        EXPORTING mandt = sy-mandt _scope = '1' _synchron = 'X'.
    ENDIF.
    IF locked = abap_true.
      CALL FUNCTION 'DEQUEUE_E_TABLE'
        EXPORTING tabname = 'Z8MM_PROC_PLAN' _scope = '1' _synchron = 'X'.
    ENDIF.
    CLEAR: stock_locked, locked.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD number : SNRO 번호범위의 다음 번호를 받아 문서번호로 반환한다.
  " ------------------------------------------------------------
  METHOD number.
    DATA num TYPE nriv-nrlevel.
    DATA digits TYPE n LENGTH 8.
    DATA prefix TYPE c LENGTH 2.
    " SNRO 내부번호 구간 01에서 다음 번호를 받는다. 여기서 문서가 저장되는 것은 아니다.
    CALL FUNCTION 'NUMBER_GET_NEXT'
      EXPORTING object = object nr_range_nr = '01'
      IMPORTING number = num
      EXCEPTIONS interval_not_found = 1 number_range_not_intern = 2 object_not_found = 3
      quantity_is_0 = 4 quantity_is_not_1 = 5 interval_overflow = 6 buffer_overflow = 7 OTHERS = 8.
    IF sy-subrc <> 0 OR num < 1 OR num > 99999999.
      lcl_mm_common=>fail( |번호범위 { object } 구간 01 (1~99999999)을 확인하세요.| ).
    ENDIF.
    CASE object.
      WHEN 'Z8MMPRN'.
        prefix = 'PR'.
      WHEN 'Z8MMPON'.
        prefix = 'PO'.
      WHEN 'Z8MMSTON'.
        prefix = 'ST'.
      WHEN OTHERS.
        lcl_mm_common=>fail( `지원하지 않는 번호범위입니다.` ).
    ENDCASE.
    digits = num.
    result = |{ prefix }{ digits }|.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD require_lock : 공통 잠금을 잡은 상태에서 저장 기능을 호출했는지 검사한다.
  " ------------------------------------------------------------
  METHOD require_lock.
    IF locked <> abap_true OR stock_locked <> abap_true.
      lcl_mm_common=>fail( `저장 전 공통 잠금이 필요합니다.` ).
    ENDIF.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD lock_doc : 재고를 바꾸지 않는 저장(PR 저장·변경·취소, PO 취소)용 잠금.
  "   조달계획 테이블 잠금만 잡고 재고 전체 잠금(EZ8MATSTK)은 잡지 않는다.
  "   그래서 다른 사람이 입고·출고·STO로 재고를 처리하는 중에도 PR·PO 문서 저장은 된다.
  "   해제는 lock과 같이 unlock으로 한다.
  " ------------------------------------------------------------
  METHOD lock_doc.
    IF locked = abap_true.
      lcl_mm_common=>fail( `중첩 저장 요청입니다.` ).
    ENDIF.
    CALL FUNCTION 'ENQUEUE_E_TABLE'
      EXPORTING tabname = 'Z8MM_PROC_PLAN' _scope = '1' _wait = space
      EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3.
    IF sy-subrc <> 0.
      lcl_mm_common=>fail( `다른 사용자가 조달 처리 중입니다.` ).
    ENDIF.
    locked = abap_true.
  ENDMETHOD.

  " ------------------------------------------------------------
  " METHOD require_doc_lock : 문서 잠금(lock_doc) 또는 전체 잠금(lock)을 잡은 상태인지 검사한다.
  " ------------------------------------------------------------
  METHOD require_doc_lock.
    IF locked <> abap_true.
      lcl_mm_common=>fail( `저장 전 공통 잠금이 필요합니다.` ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
