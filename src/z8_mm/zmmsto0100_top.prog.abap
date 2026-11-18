*&---------------------------------------------------------------------*
*& Include ZMMSTO0100_TOP
*&---------------------------------------------------------------------*
*& 전역 타입·데이터·화면 객체
*& 담당: MM(이규빈) / 프로그램: ZMMSTO0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-17  이규빈  최초 개발   최초 작성: 지사 간 자재이동(STO) 목록·입력·취소 (개발 10/17~10/23)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: STO 1건 품목 N줄 구조, 목록 카드·이력 ALV
*& 2026-11-06  이규빈  수정사항    통합테스트 피드백: STO 예약 추가, 취소 메시지 202·134 구분, 수량 소수점·카드 크기 수정
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" gt_entry : 0200에 입력한 자재행과 검사·저장 결과를 보관한다.
" gt_list : 0100 목록 ALV에 보여줄 행을 보관한다.
" gv_checked : STO 입력 전체가 재고·일정 검사를 통과했는지 기억한다.
" gv_stamp : 검사 당시 입력값. 저장 전 현재 입력과 같아야 한다.
" gv_posted : 이 화면에서 이미 저장 성공한 건이 있는지 기억한다.
" gt_hist : STO 이력과 관련 자재문서에서 읽은 조회용 상세행이다.

TABLES z8mm_po_i.
TYPES: BEGIN OF ty_list,
  signal TYPE icon_d,
  rowclr TYPE c LENGTH 4,
  ebeln TYPE z8mm_po_i-ebeln,
  ebelp TYPE z8mm_po_i-ebelp,
  matnr TYPE z8mm_po_i-matnr,
  maktx TYPE z8material_txt_m-maktx,
  src_name TYPE c LENGTH 40,
  dst_name TYPE c LENGTH 40,
  reswk TYPE z8mm_po_i-reswk,
  reslo TYPE z8mm_po_i-reslo,
  werks TYPE z8mm_po_i-werks,
  lgort TYPE z8mm_po_i-lgort,
  menge TYPE z8mm_po_i-menge,
  meins TYPE z8mm_po_i-meins,
  dep_date TYPE sy-datum,
  eta TYPE sy-datum,
  gr_date TYPE sy-datum,
  state TYPE c LENGTH 12,
  due_text TYPE c LENGTH 24,
  state_key TYPE c LENGTH 1,
  due_key TYPE c LENGTH 1,
  elikz TYPE z8mm_po_i-elikz,
  loekz TYPE z8mm_po_i-loekz,
  rsv_qty TYPE z8mm_po_i-sto_rsv_qty,  " > 0 이면 예약중(출고 전)
  is_new TYPE abap_bool,
  sort_rank TYPE i,                  " 기본정렬용(1 예약중·이동중 / 2 입고완료 / 3 취소)
  END OF ty_list,
  BEGIN OF ty_entry,
  signal TYPE icon_d,
  matnr TYPE z8mm_po_i-matnr,
  maktx TYPE z8material_txt_m-maktx,
  menge TYPE z8mm_po_i-menge,
  meins TYPE z8mm_po_i-meins,
  qty_unit TYPE z8mm_po_i-meins,       " 수량 표시용 단위(숨김): 자재 단위, 자재 없으면 EA → 소수점 없이 표시
  src_qty TYPE z8mm_po_i-menge,
  movable TYPE z8mm_po_i-menge,
  dst_qty TYPE z8mm_po_i-menge,
  transit TYPE z8mm_po_i-menge,
  ebeln TYPE z8mm_po_i-ebeln,
  result TYPE c LENGTH 16,
  detail TYPE c LENGTH 100,
  cellstyle TYPE lvc_t_styl,
  END OF ty_entry.
TYPES: BEGIN OF ty_hist.
INCLUDE TYPE z8mm_sto_hist.
TYPES:   action TYPE c LENGTH 20,
  bwart_txt TYPE c LENGTH 14,          " 이동유형 설명(351 TF→운송중재고 / 101 운송중→입고)
  origin TYPE c LENGTH 24,
  END OF ty_hist.

DATA: gt_list TYPE STANDARD TABLE OF ty_list WITH EMPTY KEY,
  gt_entry TYPE STANDARD TABLE OF ty_entry WITH EMPTY KEY,
  gt_hist TYPE STANDARD TABLE OF ty_hist WITH EMPTY KEY,
  gs_detail TYPE ty_list,
  go_main TYPE REF TO cl_gui_custom_container,
  go_list TYPE REF TO cl_gui_alv_grid,
  go_itemc TYPE REF TO cl_gui_custom_container,
  go_items TYPE REF TO cl_gui_alv_grid,
  go_histc TYPE REF TO cl_gui_container,
  go_hist TYPE REF TO cl_gui_alv_grid,
  ok_code TYPE sy-ucomm,
  gv_saved TYPE sy-ucomm,
  gv_checked TYPE abap_bool,
  gv_posted TYPE abap_bool,
  gv_stamp TYPE string.
" 화면 COMMENT 라벨 변수(gv_l*, gv_n* 등)는 SEL에서 선언된다(이름 8자 이내).

" 0100의 위쪽은 이동목록, 아래쪽은 선택 STO 이력이다.
DATA: go_split TYPE REF TO cl_gui_splitter_container,
      go_listc TYPE REF TO cl_gui_container.

DATA gv_auto_stamp TYPE string.

" 이번 실행에서 생성한 STO 번호. 목록으로 돌아오면 맨 위에 선택·파란 줄로 한 번만 보여준다.
DATA: gt_new_sto TYPE SORTED TABLE OF z8mm_po_i-ebeln WITH UNIQUE KEY table_line,
      gv_mark_new TYPE abap_bool,
      gv_direct TYPE abap_bool.      " PUR에서 [STO 생성]으로 바로 0200에 들어온 경우

" 0100 오른쪽 조회 현황. 저장·재고처리는 하지 않는 조회 필터용 HTML이다.
DATA: go_summary_box TYPE REF TO cl_gui_custom_container,
      go_summary TYPE REF TO cl_gui_html_viewer,
      gv_summary_stamp TYPE string.

" 현황 집계는 일반 조회조건만 적용한 원본, ALV는 상태조건까지 적용한다.
DATA gt_summary TYPE STANDARD TABLE OF ty_list WITH EMPTY KEY.
DATA gv_summary_action TYPE string.
DATA gv_key1 TYPE string.          " 직전 조회조건(조건이 바뀐 Enter에서만 재조회)
CLASS lcl_summary_events DEFINITION.
  PUBLIC SECTION.
    METHODS on_click FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING action.
ENDCLASS.
DATA go_summary_events TYPE REF TO lcl_summary_events.
