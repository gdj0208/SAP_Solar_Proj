*&---------------------------------------------------------------------*
*& Include ZMMPO0110_TOP
*&---------------------------------------------------------------------*
*& 전역 타입·데이터 (PO 목록, 발주 후보, 방금 처리한 PO)
*& 담당: MM(이규빈) / 프로그램: ZMMPO0110
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-07  이규빈  최초 개발   최초 작성: PR 묶음 발주(PR N건 → PO 1건), PO 목록·취소 (개발 10/07~10/13)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 상태 카드·신호등, 후보 ALV에서 골라 바로 PO 생성
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: 생성 확인 메시지 축약, '납기 충족 / N일 지연', 취소 메시지 202·134 구분
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" gt_po_all : 화면 0100에서 상태 조건을 적용하기 전 PO 품목이다. 상태카드 건수의 기준이다.
" gt_po     : 화면 0100 ALV에 보이는 PO 품목이다(상태카드로 거른 결과).
" gt_cand   : 화면 0200의 발주 후보 PR 목록이다(화면에 보이는 행 그대로).
" gt_pr     : 후보 PR의 DB 원본 사본이다. PO 생성 때 변경 여부를 비교한다.
" gt_quote  : 후보 PR별 구매가격·예상입고일이다. PO 생성 때 다시 비교한다.
" gt_presel : PR 목록(ZMMPR0100)에서 넘어온 선택 PR이다.

TABLES z8mm_po_h.

DATA: ok_code TYPE sy-ucomm,
      gv_cmd  TYPE sy-ucomm.

TYPES: BEGIN OF ty_po,
  signal TYPE icon_d,
  rowclr TYPE c LENGTH 4,
  ebeln TYPE z8mm_po_i-ebeln,
  ebelp TYPE z8mm_po_i-ebelp,
  banfn TYPE z8mm_po_i-banfn,
  matnr TYPE z8mm_po_i-matnr,
  maktx TYPE z8material_txt_m-maktx,
  menge TYPE z8mm_po_i-menge,
  meins TYPE z8mm_po_i-meins,
  vendor_name TYPE z8vendor_m-name1,
  site_text TYPE c LENGTH 60,
  werks TYPE z8mm_po_i-werks,
  netpr TYPE z8mm_po_i-netpr,
  waers TYPE z8mm_po_i-waers,
  bedat TYPE z8mm_po_h-bedat,
  lfdat TYPE z8mm_po_i-lfdat,
  state TYPE c LENGTH 12,
  detail TYPE c LENGTH 100,
  is_new TYPE abap_bool,
  sort_rank TYPE i,                  " 기본정렬용(1 입고대기 / 2 입고완료 / 3 취소)
  END OF ty_po,
  ty_pos TYPE STANDARD TABLE OF ty_po WITH EMPTY KEY.

TYPES: BEGIN OF ty_cand,
  signal TYPE icon_d,
  rowclr TYPE c LENGTH 4,
  banfn TYPE z8mm_pr-banfn,
  bnfpo TYPE z8mm_pr-bnfpo,
  src_type TYPE c LENGTH 10,          " 요청구분 코드(Z8MM_PR-SOURCE_TYPE: MANUAL·SAFETY·PO·STO_REPL·INSPECT) — 후보조건 c_src 거르기용
  src_text TYPE dd07t-ddtext,         " 요청구분 글자(도메인 고정값 내역)
  matnr TYPE z8mm_pr-matnr,
  maktx TYPE z8material_txt_m-maktx,
  menge TYPE z8mm_pr-menge,
  meins TYPE z8mm_pr-meins,
  lifnr TYPE z8mm_pr-lifnr,
  vendor_name TYPE z8vendor_m-name1,
  werks TYPE z8mm_pr-werks,
  lgort TYPE z8mm_pr-lgort,
  site_text TYPE c LENGTH 60,
  netpr TYPE z8purch_info_m-netpr,
  waers TYPE z8purch_info_m-waers,
  lfdat TYPE z8mm_pr-lfdat,
  eta TYPE sy-datum,
  schedule TYPE c LENGTH 20,
  bundle TYPE c LENGTH 10,
  bundle_qty TYPE z8mm_pr-menge,
  ok_cnt TYPE i,
  ok TYPE abap_bool,
  late TYPE abap_bool,
  ebeln TYPE z8mm_po_h-ebeln,
  state TYPE c LENGTH 12,
  detail TYPE c LENGTH 100,
  END OF ty_cand,
  ty_cands TYPE STANDARD TABLE OF ty_cand WITH EMPTY KEY.

TYPES: BEGIN OF ty_quote,
  banfn TYPE z8mm_pr-banfn,
  bnfpo TYPE z8mm_pr-bnfpo,
  price TYPE z8purch_info_m,
  arrival TYPE sy-datum,
  END OF ty_quote,
  BEGIN OF ty_sel,
  gno TYPE i,
  banfn TYPE z8mm_pr-banfn,
  bnfpo TYPE z8mm_pr-bnfpo,
  lifnr TYPE z8mm_pr-lifnr,
  matnr TYPE z8mm_pr-matnr,
  werks TYPE z8mm_pr-werks,
  lgort TYPE z8mm_pr-lgort,
  meins TYPE z8mm_pr-meins,
  menge TYPE z8mm_pr-menge,
  late TYPE abap_bool,
  END OF ty_sel,
  BEGIN OF ty_grp,
  gno TYPE i,
  banfn TYPE z8mm_pr-banfn,
  bnfpo TYPE z8mm_pr-bnfpo,
  lifnr TYPE z8mm_pr-lifnr,
  matnr TYPE z8mm_pr-matnr,
  total TYPE z8mm_pr-menge,
  count TYPE i,
  END OF ty_grp.

DATA: gt_po_all TYPE ty_pos,
      gt_po TYPE ty_pos,
      gt_cand TYPE ty_cands,
      gt_pr TYPE lcl_mm_common=>ty_prs,
      gt_quote TYPE STANDARD TABLE OF ty_quote WITH EMPTY KEY,
      gt_presel TYPE lcl_mm_common=>ty_prs.
" 이번 실행에서 0200으로 생성한 PO 번호. 0100 복귀 직후 한 번만 파란 줄·맨 위로 표시한다.
DATA gt_new_po TYPE SORTED TABLE OF z8mm_po_h-ebeln WITH UNIQUE KEY table_line.
" 방금 생성·취소한 PO 행을 한 번 '선택' 상태로 걸어 둔다(다른 행을 고르기 전까지 강조 유지).
DATA gv_sel_new TYPE abap_bool.

" 화면 0100 / 0200 각각의 ALV 객체이다.
DATA: go_cont1 TYPE REF TO cl_gui_custom_container,
      go_grid1 TYPE REF TO cl_gui_alv_grid,
      go_cont2 TYPE REF TO cl_gui_custom_container,
      go_grid2 TYPE REF TO cl_gui_alv_grid.

" 직전 조회조건: 조건이 바뀐 Enter에서만 다시 조회한다.
DATA: gv_key1 TYPE string,
      gv_key2 TYPE string,
      gv_from_pr TYPE abap_bool.

" 화면 0100 오른쪽 상태카드(HTML). 조회 필터 전용이며 저장은 하지 않는다.
DATA: go_card_box TYPE REF TO cl_gui_custom_container,
      go_card_html TYPE REF TO cl_gui_html_viewer,
      gv_card_stamp TYPE string,
      gv_card_action TYPE string.

CLASS lcl_card_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_click FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action.
ENDCLASS.
DATA go_card_events TYPE REF TO lcl_card_events.
