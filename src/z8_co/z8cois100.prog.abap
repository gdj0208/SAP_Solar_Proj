*&---------------------------------------------------------------------*
*& Report Z8COIS100
*&---------------------------------------------------------------------*
*& CO-IS100 영업이익 분석 (전사/지사/프로젝트별 손익 Tree + 분기 차트)
*& 담당: CO(구동준) / T-Code: <Z8COIS100>
*& 참고: Z8COIS100 기술 사양서 (<파일명 또는 링크>)
*&---------------------------------------------------------------------*
*& [기능]
*&  - 조회 기간(연도·분기) 기준 Tree ALV: 전사 총계 > 지사 > 프로젝트
*&  - 분기별 막대 차트: 매출 총액 / 매출 총이익 / 영업 이익
*&  - 금액 클릭 시 근거 회계전표 팝업 (매출액 / 매출원가 / 판관비)
*& [권한] Z8MM_ADMIN (ACTVT 16)
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자               변경자     요청자 / 사유             변경 내용
*& 2026-11-06   구동준     최초 개발                  최초 작성
*&
*& 2026-11-06   구동준     Tree alv 수정            - 사용자 피드백으로 Tree ALV 최초 표시를 전사 총계만이 아니라 지사까지
*&                                                                      펼치도록 변경 (FORM expand_default_nodes 추가) BY <ID>100배
*&                                                                   - 음수 부호를 숫자 앞에 표시하도록 변경
*&
*& 2026-11-08   구동준     권한 검사 수정         - 권한 검사 OBJECT 변경 (Z8MM_ADMIN -> Z8CO_AUTH)
*&---------------------------------------------------------------------*

INCLUDE Z8COIS100TOP                            .    " Global Data
INCLUDE Z8COIS100CLS.
INCLUDE Z8COIS100O01                            .  " PBO-Modules
INCLUDE Z8COIS100I01                            .  " PAI-Modules
INCLUDE Z8COIS100F01                            .  " FORM-Routines


INITIALIZATION.
  " 0. 권한 검수
  AUTHORITY-CHECK OBJECT 'Z8CO_AUTH'
  ID 'ACTVT' FIELD '16'. "실행
  IF sy-subrc <> 0. MESSAGE e200(z8_msg) WITH 'CO'. ENDIF.


  " 금일 기준 현재 분기 및 1년 전 분기 계산
  DATA(lv_curr_month) = sy-datum+4(2).
  p_t_yr = sy-datum(4).

  CASE lv_curr_month.
    WHEN '01' OR '02' OR '03'. p_t_qt = '1'.
    WHEN '04' OR '05' OR '06'. p_t_qt = '2'.
    WHEN '07' OR '08' OR '09'. p_t_qt = '3'.
    WHEN '10' OR '11' OR '12'. p_t_qt = '4'.
  ENDCASE.

  p_f_yr = p_t_yr - 1.
  p_f_qt = p_t_qt.


" ==========================================================
" 2. 화면이 그려질 때마다 실행: 드롭다운 목록 구성 (Subscreen 필수)
" ==========================================================
AT SELECTION-SCREEN OUTPUT.
  DATA: lt_year TYPE vrm_values,
        ls_year TYPE vrm_value,
        lt_qt   TYPE vrm_values,
        ls_qt   TYPE vrm_value.

  CLEAR: lt_year, lt_qt.

  " 연도 리스트 (작년 ~ 3년 뒤 등 비즈니스에 맞게 범위 설정)
  DO 5 TIMES.
    DATA(lv_y) = sy-datum(4) - sy-index + 1.
    ls_year-key  = |{ lv_y }|.
    ls_year-text = |{ lv_y }년|.
    APPEND ls_year TO lt_year.
  ENDDO.

  " 분기 리스트
  ls_qt-key = '1'. ls_qt-text = '1 분기'. APPEND ls_qt TO lt_qt.
  ls_qt-key = '2'. ls_qt-text = '2 분기'. APPEND ls_qt TO lt_qt.
  ls_qt-key = '3'. ls_qt-text = '3 분기'. APPEND ls_qt TO lt_qt.
  ls_qt-key = '4'. ls_qt-text = '4 분기'. APPEND ls_qt TO lt_qt.

  " 서브스크린 필드에 리스트 바인딩
  CALL FUNCTION 'VRM_SET_VALUES' EXPORTING id = 'P_F_YR' values = lt_year.
  CALL FUNCTION 'VRM_SET_VALUES' EXPORTING id = 'P_T_YR' values = lt_year.
  CALL FUNCTION 'VRM_SET_VALUES' EXPORTING id = 'P_F_QT' values = lt_qt.
  CALL FUNCTION 'VRM_SET_VALUES' EXPORTING id = 'P_T_QT' values = lt_qt.

START-OF-SELECTION.
  CALL SCREEN 0100.
