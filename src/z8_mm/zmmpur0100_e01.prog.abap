*&---------------------------------------------------------------------*
*& Include ZMMPUR0100_E01
*&---------------------------------------------------------------------*
*& 실행 시작 - GUI 확인, 지사 마스터 준비 후 화면 0100 호출
*& 담당: MM(이규빈) / 프로그램: ZMMPUR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-25  이규빈  최초 개발   최초 작성: 담당 지사의 PR·PO·STO 업무현황과 각 프로그램 이동 (개발 10/25~10/29)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 카드 4개 화면 개편, 이동 후 새 문서 표시
*& 2026-11-05  이규빈  수정사항    조회 기준 보완: 담당 지사 → 그 지사의 입고플랜트 기준 조회, 조회 기간(시작·종료일) 추가
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

INITIALIZATION.
  " 실행 권한: MM 프로그램 권한(Z8MM_ADMIN)의 실행(16)이 없으면 시작하지 않는다(팀 MM 프로그램 공통).
  AUTHORITY-CHECK OBJECT 'Z8MM_ADMIN'
    ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'MM'.   " MM 관리자 전용 프로그램입니다. 권한을 요청하세요.
  ENDIF.

START-OF-SELECTION.
  IF sy-batch = abap_true.
    MESSAGE s120(z8_msg) DISPLAY LIKE 'E' WITH '업무현황'.   " 업무현황 ALV를 그리는데 실패했습니다(배치에서는 화면을 띄울 수 없음)
    RETURN.
  ENDIF.
  gv_date = sy-datum.
  " 조회 기간 기본값: 오늘 기준 앞뒤 15일(PR 목록과 같은 기본 기간)
  gv_dfrom = sy-datum - 15.
  gv_dto = sy-datum + 15.
  " 시작 화면은 항상 [미발주 PR] 카드 기준이다(카드로 다시 열 때와 같은 목록·열).
  gv_view = 'R'.
  SELECT * FROM z8plant_m INTO TABLE @gt_plants.
  SORT gt_plants BY werks.
  " 구매지사·출발/도착지사 열에 지사명을 보여주기 위한 지사 마스터
  SELECT * FROM z8branch_m INTO TABLE @gt_branches.
  " 호출 파라미터는 플랜트(P100)로 받는다 → 화면 담당 지사(B001)로 바꾼다.
  IF p_werks IS NOT INITIAL AND p_werks <> '*'.
    READ TABLE gt_plants INTO DATA(ls_start_plant) WITH KEY werks = p_werks.
    IF sy-subrc = 0.
      gv_werks = ls_start_plant-bupla.
    ELSE.
      gv_werks = p_werks.               " 아래 검사에서 '등록된 지사' 안내
    ENDIF.
  ENDIF.
  IF gv_werks <> '*' AND gv_werks IS NOT INITIAL.
    READ TABLE gt_branches TRANSPORTING NO FIELDS WITH KEY branch = gv_werks.
    IF sy-subrc <> 0.
      MESSAGE s073(z8_msg) DISPLAY LIKE 'E' WITH '등록된 지사'.   " 등록된 지사를 입력해주세요
      RETURN.
    ENDIF.
  ENDIF.
  IF gv_werks = '*'.
    CLEAR gv_werks.
  ENDIF.
  CALL SCREEN 0100.
