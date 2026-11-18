*&---------------------------------------------------------------------*
*& Report ZMMGR100
*&---------------------------------------------------------------------*
*& MM-GR100. 자재 입고
*& 담당: MM(구동준) / T-Code: ZMMGR100
*& 참고: 입고 프로그램 기술 사양서 (ZMMGR100)
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자         변경자     요청자 / 사유                 변경 내용
*& 2026-11-06   구동준     최초 개발                  최초 작성
*& 2026-11-06   구동준     팀원 피드백              EA 자재 PO이력 금액 1/100, 케이블 WE전표 100배
*&                                                                   → 금액 계산을 '수량×단가÷가격단위'로 통일
*&                                                                      (자재문서·PO이력·WE전표·재고평가 동일 금액)   BY SESAC-140
*&                                                                      (처리한 PO 확인 어려움)       메시지(I218)로 알림
*&
*& 2026-11-06   구동준    화면 전환 개선                  단위 테스트 : 200번 재진입 시 이전 입력값 잔존, 대기 내역 소실
*&                                                                        → 진입 시 화면 초기화, 대기 내역 유지·품목 단위 교체,
*&                                                                        품목번호(ZEILE) 중복 방지                    BY SESAC-140
*&
*& 2026-11-06   구동준    FUCNTION 개선              단위 테스트 : Enter 키로 화면 이동·처리 재실행
*&                                                                          → OK_CODE 초기화, 선택화면 SSCRFIELDS-UCOMM 사용 BY SESAC-140
*&
*& 2026-11-06   구동준     입고 확정 메시지            팀원 피드백 : 확정 후 처리 PO·자재문서 확인 어려움
*&                                                                          → 확정 시 상태바 메시지(자재문서번호, PO) 표시  BY SESAC-140
*&
*& 2026-11-06   구동준     락 구조 개선                  Lock 미적용·연도 단위 과잉 Lock
*&                                                                        → PO 단위 Lock(EZ8MM_PO) 신설, 재고/평가 Lock 보완,
*&
*& 2026-11-08   구동준     PO_HIST의 ZEKKN 채번 삭제
*&     - 같은  PO여도 PO_HIST-BELNR이 각 PO_HIST의 데이터를 구별해준다.
*&     - 같은 PO끼리의 PO_HIST는 BUZEI로 구별된다 (REF : PO_HIST에서 EBELN = PO00000708)
*&---------------------------------------------------------------------*



INCLUDE z8mmgr100top.                      .    " Global Data
INCLUDE z8mmgr100cls.

INCLUDE z8mmgr10oo01.
INCLUDE z8mmgr100i01.
INCLUDE z8mmgr100f01.

INCLUDE z8mmgr10oo02.
INCLUDE z8mmgr100i02.
INCLUDE z8mmgr100f02.

INCLUDE z8mmgr10oo03.
INCLUDE z8mmgr100i03.
INCLUDE z8mmgr100f03.




*---------------------------------------------------------*
* 초기화
*---------------------------------------------------------*
INITIALIZATION.
  AUTHORITY-CHECK OBJECT 'Z8MM_ADMIN'
  ID 'ACTVT' FIELD '16'. "실행
  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'MM'.
  ENDIF.

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

  IF sy-dynnr = '0200'.
    DATA: lt_exclude TYPE TABLE OF sy-ucomm.
    " 선택 화면 강제 버튼(변형 관련) 완벽 제외
    APPEND 'SPOS' TO lt_exclude. " 변형 저장
    APPEND 'GET'  TO lt_exclude. " 변형 가져오기

    " [핵심] 일반 SET PF-STATUS 대신 선택 화면 전용 함수 사용
    CALL FUNCTION 'RS_SET_SELSCREEN_STATUS'
      EXPORTING
        p_status  = 'S200'  " 활성화해 둔 GUI Status 이름
      TABLES
        p_exclude = lt_exclude.

    SET PF-STATUS 'S200' EXCLUDING lt_exclude.
    SET TITLEBAR 'T0200'.

    " 0. 200번 화면 데이터 비우기
    "PERFORM clear_data.
    "CLEAR gv_new_doc_no.

    " 1. 입력 불가 필드 설정
    LOOP AT SCREEN.
      IF screen-name = 'P_SUP2'
          OR screen-name = 'P_MATNAM'
          OR screen-group1 = 'NCH'.

        screen-input = '0'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

    " 2. 구매오더 정보들 불러오기
    PERFORM get_po_h.
    IF gs_po_h IS INITIAL. MESSAGE s022(z8_msg) DISPLAY LIKE 'E'. RETURN. ENDIF.

    PERFORM get_po_i.
    IF gs_po_i IS INITIAL. MESSAGE s022(z8_msg) DISPLAY LIKE 'E'. RETURN. ENDIF.

    PERFORM get_datas.


    " 3. 화면 변수 값 할당 (reset_meins 대체)
    gv_mein0 = 'EA'.
    gv_mein1 = gv_mein0.
    gv_mein2 = gv_mein0.
    gv_mein3 = gv_mein0.

    " 5. Lock
    "PERFORM lock_matdoc_i.

  ELSE.
    SET PF-STATUS 'S1000'.
    SET TITLEBAR 'T1000'.

  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_werks.
  PERFORM get_plant_name.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sup.
  PERFORM get_sup_name.


*---------------------------------------------------------*
* [PAI 역할] 사용자 입력 후 검증 (Validation)
*---------------------------------------------------------*
AT SELECTION-SCREEN.
  CASE sy-dynnr.
    WHEN '0200'.
      CASE sy-ucomm.

        WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
          CLEAR : gt_po_i,  gt_po_i, gt_matdoc_i, gv_new_doc_no.
          "CALL FUNCTION 'DEQUEUE_ALL'.
          LEAVE TO SCREEN 0.

        WHEN 'CRET'.
          "CLEAR gt_matdoc_i.
          DATA : lv_error  TYPE c LENGTH 1 VALUE ''.

          " 1-1. 일자 검수
          IF p_date < gs_po_h-bedat. MESSAGE e056(z8_msg). lv_error = 'X'. ENDIF.
          IF p_date > sy-datum. MESSAGE e225(z8_msg). lv_error = 'X'. ENDIF.

          " 1-2. 수량 검수
          IF p_menge <> p_inv + p_in + p_ret AND lv_error = ''. MESSAGE e021(z8_msg). lv_error = 'X'. ENDIF.

          " 2. 에러가 없다면 자재이동문서 생성
          IF lv_error = ''.  PERFORM make_matdoc. ENDIF.
          CALL FUNCTION 'DEQUEUE_ALL'.

      ENDCASE.

    WHEN OTHERS.
      CASE sy-ucomm.

        WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
          LEAVE TO SCREEN 0.

        WHEN 'SRCH'.
          " 1. 필수 입력 : 공급처
          IF p_werks IS INITIAL. MESSAGE s121(z8_msg) WITH |플랜트는| DISPLAY LIKE 'E'. RETURN. ENDIF.

          " 1. 시작일, 종료일 모두 입력되지 않은 경우 차단 (s_date 테이블 자체가 비어있음)
          IF s_date[] IS INITIAL.
            MESSAGE '조회 날짜를 반드시 입력해 주세요.' TYPE 'E'.
          ENDIF.

          READ TABLE s_date INTO DATA(ls_date) INDEX 1.
          IF sy-subrc = 0.

            " 3. 시작일은 비어있는데 종료일(High)만 입력된 경우 차단
            IF
              ls_date-low IS INITIAL AND ls_date-high IS NOT INITIAL.
              MESSAGE '시작일 없이 종료일만 단독으로 입력할 수 없습니다.' TYPE 'E'.
            ENDIF.

            " 4. 시작일이 종료일보다 늦은 경우 차단
            IF ls_date-low IS NOT INITIAL AND ls_date-high IS NOT INITIAL.
              IF ls_date-low > ls_date-high.
                MESSAGE '시작일이 종료일보다 늦을 수 없습니다.' TYPE 'E'.
              ENDIF.
            ENDIF.

          ENDIF.

          " 공급사와 입고 일자
          gv_werks = p_werks.
          gv_sup = p_sup.

          " 2-1. 입력 정보에 해당되는 데이터 존재여부 확인
          SELECT *
          FROM z8mm_po_h AS h
            INNER JOIN z8mm_po_i AS i ON h~ebeln = i~ebeln
          WHERE ( lifnr = @gv_sup OR @gv_sup = '')
              AND ( i~werks = @gv_werks OR @gv_werks = '' )
              AND i~loekz = ''
              AND i~lfdat IN @s_date
              AND h~bsart = 'NB'
            INTO CORRESPONDING FIELDS OF TABLE @gt_po_h.

          " 2-2. 입력 정보에 해당되는 db 부재 -> 경고 후 종료
          IF gt_po_h IS INITIAL.
            MESSAGE s050(z8_msg) DISPLAY LIKE 'E'.
          ELSE.
            CALL SCREEN 100.
          ENDIF.

        WHEN OTHERS.

      ENDCASE.
  ENDCASE.
