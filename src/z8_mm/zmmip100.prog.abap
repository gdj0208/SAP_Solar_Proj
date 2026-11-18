*======================================================================*
* ZMMIP100
*======================================================================*
*&---------------------------------------------------------------------*
*& Report ZMMIP100
*&---------------------------------------------------------------------*
*& MM-IP100. 입고 송장 검증 - 조회 조건 입력
*& 담당: MM(구동준) / T-Code: ZMMIP100
*& 참고: 입고 송장 검증 프로그램 기술 사양서 (ZMMIP100/110/120)
*&---------------------------------------------------------------------*
*& 기능 : 플랜트 / 조회기간 / 청구서 상태를 입력받아 검증 대상 PO 존재를
*&        확인한 뒤 ZMMIP110 을 호출한다.
*& 흐름 : ZMMIP100 -> ZMMIP110 -> ZMMIP120
*& 권한 : Z8MM_ADMIN (ACTVT 16)
*& 전달 : Parameter ID WERKS, INV_SEL / ABAP Memory Z_DATE_RANGE (조회기간)
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자               변경자     요청자 / 사유           변경 내용
*& 2026-11-06   구동준     최초 개발               최초 작성
*&---------------------------------------------------------------------*


INCLUDE zmmip100top.
INCLUDE zmmip100o01.
INCLUDE zmmip100i01.


INITIALIZATION.
  " 권한 확인
  AUTHORITY-CHECK OBJECT 'Z8MM_ADMIN'
  ID 'ACTVT' FIELD '16'. "실행
  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'MM'.
  ENDIF.

  " SDATE 설정
  CLEAR : s_date.
  s_date-sign   = 'I'.
  s_date-option = 'BT'.

  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = sy-datum
      days      = 0
      months    = 1
      signum    = '-'
      years     = 0
    IMPORTING
      calc_date = s_date-low.

  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = sy-datum
      days      = 0
      months    = 1
      signum    = '+'
      years     = 0
    IMPORTING
      calc_date = s_date-high.
  APPEND s_date.


*---------------------------------------------------------*
* [PBO 역할] 화면 출력 전 제어
*---------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.
  SET PF-STATUS 'S0100'.
  SET TITLEBAR 'T0100'.



*---------------------------------------------------------*
* [PAI 역할] 사용자 입력 후 검증 (Validation)
*---------------------------------------------------------*
AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
      LEAVE TO SCREEN 0.

    WHEN 'SRCH'.
      DATA :
        lv_ebeln TYPE ebeln,
        lr_werks TYPE RANGE OF z8v_unb_inv-werks,
        lr_proc  TYPE RANGE OF z8v_unb_inv-procstat.


      " 플랜트명 보이기
      IF p_werks IS NOT INITIAL.
        SELECT SINGLE name1
          INTO gv_name
          FROM z8plant_m
         WHERE werks = p_werks.

        " 잘못된 플랜트를 직접 타이핑했을 경우의 방어 로직
        IF sy-subrc <> 0.
          gv_name = '알 수 없는 플랜트'.
        ENDIF.

      ELSE.
        " 입력값이 지워지면 라벨도 지워줌
        CLEAR gv_name.
        IF p_werks IS INITIAL. MESSAGE s121(z8_msg) WITH |플랜트는| DISPLAY LIKE 'E'. RETURN. ENDIF.
        RETURN.
      ENDIF.

      IF s_date IS INITIAL. MESSAGE s121(z8_msg) WITH |조회기간| DISPLAY LIKE 'E'. RETURN. ENDIF.

      READ TABLE s_date INTO DATA(ls_date) INDEX 1.
      IF sy-subrc = 0.

        " 3. 시작일은 비어있는데 종료일(High)만 입력된 경우 차단
        IF ls_date-low IS INITIAL AND ls_date-high IS NOT INITIAL.
          MESSAGE '시작일 없이 종료일만 단독으로 입력할 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.

        " 4. 시작일이 종료일보다 늦은 경우 차단
        IF ls_date-low IS NOT INITIAL AND ls_date-high IS NOT INITIAL.
          IF ls_date-low > ls_date-high.
            MESSAGE '시작일이 종료일보다 늦을 수 없습니다.' TYPE 'S' DISPLAY LIKE 'E'.
            RETURN.
          ENDIF.
        ENDIF.

      ENDIF.

      " 2. 라디오 버튼 조건 설정 (procstat)
      IF p_inv_a = 'X'.
        gv_inv_sel = 'A'.
        " '전체'일 경우 20, 25 두 가지 상태만 포함되도록 2개의 행을 추가
        lr_proc = VALUE #( ( sign = 'I' option = 'EQ' low = '20' )
                           ( sign = 'I' option = 'EQ' low = '25' ) ).
      ELSEIF p_inv_y = 'X'.
        gv_inv_sel = 'Y'..
        lr_proc = VALUE #( ( sign = 'I' option = 'EQ' low = '25' ) ).
      ELSEIF p_inv_n = 'X'.
        gv_inv_sel = 'N'.
        lr_proc = VALUE #( ( sign = 'I' option = 'EQ' low = '20' ) ).
      ENDIF.

      " 4. 단일 SELECT 쿼리로 깔끔하게 처리
      SELECT SINGLE ebeln
        INTO @lv_ebeln
        FROM z8v_unb_inv
        WHERE procstat IN @lr_proc
          AND werks    = @p_werks
          AND bedat    IN @s_date.


      IF lv_ebeln IS INITIAL OR sy-subrc <> 0.
          MESSAGE s214(z8_msg) WITH |조회할 구매오더|  DISPLAY LIKE 'E'.
          RETURN.

      ELSE.

        SET PARAMETER ID 'WERKS' FIELD p_werks.
        SET PARAMETER ID 'INV_SEL' FIELD gv_inv_sel.

        EXPORT mem_date = s_date[] TO MEMORY ID 'Z_DATE_RANGE'.
        "SET PARAMETER ID 'SUP' FIELD p_sup.
        CALL TRANSACTION 'ZMMIP110'." and skip FIRST SCREEN.
      ENDIF.
    WHEN OTHERS.
  ENDCASE.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_werks.
  DATA: lt_return TYPE TABLE OF ddshretval.

  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname     = 'Z8PLANT_M'    " 참조 테이블
      fieldname   = 'WERKS'        " 참조 필드
      searchhelp  = 'Z8SH_PLANT'   " MATCHCODE OBJECT에 지정한 서치헬프 명시
      dynpprog    = sy-repid
      dynpnr      = sy-dynnr
      dynprofield = 'P_WERKS'      " 값을 꽂아줄 화면 필드
    TABLES
      return_tab  = lt_return
    EXCEPTIONS
      OTHERS      = 1.

  IF sy-subrc = 0 AND lt_return[] IS NOT INITIAL.
    CALL FUNCTION 'SAPGUI_SET_FUNCTIONCODE'
      EXPORTING
        functioncode = '=ENTR'.
  ENDIF.
