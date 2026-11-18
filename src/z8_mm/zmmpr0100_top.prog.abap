*&---------------------------------------------------------------------*
*& Include ZMMPR0100_TOP
*&---------------------------------------------------------------------*
*& 목록 데이터와 화면 객체
*& 담당: MM(이규빈) / 프로그램: ZMMPR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-14  이규빈  최초 개발   최초 작성: PR 목록 조회·취소, PR 생성/변경·PO 생성 화면 연결 (개발 10/14~10/16)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 상태 카드·신호등 화면 통일, 조회조건·버튼 동작 보완
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 조회 결과 없음 오류 표시, 취소 메시지 정리
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

TYPES: BEGIN OF ty_list.
INCLUDE TYPE z8mm_pr.
TYPES:   signal TYPE icon_d,
  maktx TYPE z8material_txt_m-maktx,
  vendor_name TYPE z8vendor_m-name1,
  site_text TYPE c LENGTH 60,
  src_text TYPE dd07t-ddtext,         " 요청구분 글자(도메인 고정값 내역)
  state TYPE c LENGTH 16,
  detail TYPE c LENGTH 100,
  sort_rank TYPE i,                  " 기본정렬용(1 발주대기 / 2 발주완료 / 3 취소)
  rowclr TYPE c LENGTH 4,            " 방금 처리한 PR 파란 줄(다음 조회 때 사라짐)
  is_mark TYPE abap_bool,
  END OF ty_list,
  ty_rows TYPE STANDARD TABLE OF ty_list WITH EMPTY KEY.
" 방금 생성·변경·취소·발주한 PR 키(파란 줄). [조회] 버튼·카드 이동·다음 처리 때 비운다(PO·STO 목록도 같은 규칙).
TYPES: BEGIN OF ty_mark,
         banfn TYPE z8mm_pr-banfn,
         bnfpo TYPE z8mm_pr-bnfpo,
       END OF ty_mark.
DATA gt_mark TYPE SORTED TABLE OF ty_mark WITH UNIQUE KEY banfn bnfpo.
" 방금 처리한 행을 한 번 '선택' 상태로 걸어 둔다(다른 행을 고르기 전까지 강조 유지).
DATA gv_sel_mark TYPE abap_bool.
DATA: gt_list TYPE ty_rows,
  gt_original TYPE lcl_mm_common=>ty_prs,
  go_listc TYPE REF TO cl_gui_custom_container,
  go_list TYPE REF TO cl_gui_alv_grid,
  ok_code TYPE sy-ucomm,
  gv_cmd TYPE sy-ucomm.

TYPES: BEGIN OF ty_query_filter,
  document TYPE z8mm_pr-banfn,
  bupla TYPE z8plant_m-bupla,        " 구매지사(지사코드)
  matnr TYPE z8mm_pr-matnr,
  lifnr TYPE z8mm_pr-lifnr,
  state TYPE c LENGTH 1,
  dfrom TYPE z8mm_pr-lfdat,          " 희망납기 기간
  dto TYPE z8mm_pr-lfdat,
  END OF ty_query_filter.
DATA gs_query_filter TYPE ty_query_filter.

" 0100 오른쪽 조회 현황. 저장·재고처리는 하지 않는 조회 필터용 HTML이다.
DATA: go_summary_box TYPE REF TO cl_gui_custom_container,
      go_summary TYPE REF TO cl_gui_html_viewer,
      gv_summary_stamp TYPE string.

" 현황 집계는 일반 조회조건만 적용한 원본, ALV는 상태조건까지 적용한다.
DATA gt_summary TYPE STANDARD TABLE OF ty_list WITH EMPTY KEY.
DATA gv_summary_action TYPE string.
CLASS lcl_summary_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_click FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action.
ENDCLASS.
DATA go_summary_events TYPE REF TO lcl_summary_events.
