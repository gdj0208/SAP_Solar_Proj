*&---------------------------------------------------------------------*
*& Report Z8COSD100
*&---------------------------------------------------------------------*
*& CO-SD100 영업이익 분석 (전사/지사/프로젝트별 손익 Tree + 분기 차트)
*& 담당: CO(구동준) / T-Code: <Z8COSD100>
*& 참고: Z8COSD100 기술 사양서
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자               변경자     요청자 / 사유             변경 내용
*& 2026-11-06   구동준     최초 개발                  최초 작성
*&
*& 2026-11-06   구동준     거절사유 수정            - 상세 ALV 거절 사유 '미진행'이 만료 건에 부적합
*&                                                                        → 견적 기한 만료 / 청구 기한 만료 / 사유 미입력으로 구분 표시
*&
*& 2026-11-08   구동준     권한 검사 수정         - 권한 검사 OBJECT 변경 (Z8MM_ADMIN -> Z8CO_AUTH)
*&---------------------------------------------------------------------*


INCLUDE Z8COSD100TOP                            .    " Global Data
INCLUDE Z8COSD100CLS.

INCLUDE Z8COSD100O01                            .  " PBO-Modules
INCLUDE Z8COSD100I01                            .  " PAI-Modules
INCLUDE Z8COSD100F01                            .  " FORM-Routines

INCLUDE Z8COSD100O02                            .  " PBO-Modules
INCLUDE Z8COSD100F02                            .  " FORM-Routines


INITIALIZATION.
  AUTHORITY-CHECK OBJECT 'Z8CO_AUTH'
  ID 'ACTVT' FIELD '16'. "실행
  IF sy-subrc <> 0. MESSAGE e200(z8_msg) WITH 'CO'. ENDIF.

  btn_srch = '조회'.

   DATA: lv_1year_ago TYPE d.
  CALL FUNCTION 'RP_CALC_DATE_IN_INTERVAL'
    EXPORTING
      date      = sy-datum   " 기준일 (금일)
      days      = 0
      months    = 1
      signum    = '-'        " 빼기
      years     = 0
    IMPORTING
      calc_date = lv_1year_ago.

  " 2. 기본 날짜 조건 세팅 (1년 전 ~ 오늘)
  clear : s_guebg.
    s_guebg-sign   = 'I'.
    s_guebg-option = 'BT'.
    s_guebg-low    = lv_1year_ago.
    s_guebg-high   = sy-datum.
    APPEND s_guebg.


START-OF-SELECTION.
  call SCREEN 100.


AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    " MODIF ID res로 지정한 그룹을 찾습니다 (반드시 대문자 'RES'로 비교)
    IF screen-group1 = 'RES'.
      screen-input = 0. " 0: 입력 불가(Read-Only), 1: 입력 가능
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.
