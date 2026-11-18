*&---------------------------------------------------------------------*
*& Include ZMMPUR0100_TOP
*&---------------------------------------------------------------------*
*& 전역 타입·데이터 (PR·PO·STO 공통 행 구조, 화면 필드, 컨트롤)
*& 담당: MM(이규빈) / 프로그램: ZMMPUR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-25  이규빈  최초 개발   최초 작성: 담당 지사의 PR·PO·STO 업무현황과 각 프로그램 이동 (개발 10/25~10/29)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 카드 4개 화면 개편, 이동 후 새 문서 표시
*& 2026-11-05  이규빈  수정사항    조회 기준 보완: 담당 지사 → 그 지사의 입고플랜트 기준 조회, 조회 기간(시작·종료일) 추가
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

TYPES: BEGIN OF ty_row,
         signal TYPE icon_d,
         rowclr TYPE c LENGTH 4,
         docno TYPE z8mm_po_h-ebeln,
         item TYPE z8mm_po_i-ebelp,
         matnr TYPE z8mm_po_i-matnr,
         maktx TYPE z8material_txt_m-maktx,
         werks TYPE z8mm_po_i-werks,
         site_name TYPE z8plant_m-name1,
         reswk TYPE z8mm_po_i-reswk,
         source_name TYPE z8plant_m-name1,
         menge TYPE z8mm_po_i-menge,
         meins TYPE z8mm_po_i-meins,
         lfdat TYPE z8mm_pr-lfdat,
         bedat TYPE z8mm_po_h-bedat,
         dep_date TYPE z8mm_po_i-sto_dep_date,
         eta TYPE z8mm_po_i-sto_arr_date,
         lifnr TYPE z8mm_po_h-lifnr,
         vendor_name TYPE z8vendor_m-name1,
         status TYPE c LENGTH 20,
         rsv_qty TYPE z8mm_po_i-sto_rsv_qty,   " STO > 0 이면 예약중(출고 전)
       END OF ty_row.
TYPES ty_rows TYPE STANDARD TABLE OF ty_row WITH EMPTY KEY.
TYPES ty_plants TYPE STANDARD TABLE OF z8plant_m WITH EMPTY KEY.
DATA: gt_pr TYPE ty_rows,
      gt_po TYPE ty_rows,
      gt_sto TYPE ty_rows,
      gt_out TYPE ty_rows,
      gt_plants TYPE ty_plants.
" 구매지사·출발/도착지사 열에 지사명(z8branch_m)을 보여주기 위한 목록
DATA gt_branches TYPE STANDARD TABLE OF z8branch_m WITH EMPTY KEY.
" PUR에서 [PR/PO/STO 생성]으로 방금 만든 문서: 파란 줄 + 맨 위 + 한 번 선택
"   (새로고침 버튼이나 다음 생성 때 정리)
DATA: gt_pur_new TYPE SORTED TABLE OF z8mm_po_h-ebeln WITH UNIQUE KEY table_line,
      gv_pur_sel TYPE abap_bool.
" 담당 지사(B001, 화면 칸 GV_WERKS)는 직접 입력하거나 F4로 선택한다. 공백은 전체 지사이다.
"   조회·하위 프로그램 호출은 그 지사에 속한 입고플랜트(P100)로 바꿔서 한다(site_plants / site_plant).
"   화면 칸 이름은 SE51과 맞추기 위해 GV_WERKS 그대로 둔다(길이 4, 지사코드도 4자리).
DATA: gv_werks TYPE z8mm_pr-werks,
      gv_wname TYPE z8plant_m-name1,
      gv_previous TYPE z8mm_pr-werks,
      gv_date TYPE sy-datum,             " 기준일(오늘): 신호등·경과 판단 기준
      gv_dfrom TYPE sy-datum,            " 조회 기간 시작일(화면 입력)
      gv_dto TYPE sy-datum,              " 조회 기간 종료일(화면 입력, 비면 시작일 하루)
      gv_prev_dfrom TYPE sy-datum,       " 마지막으로 조회한 기간(바뀌었는지 비교용)
      gv_prev_dto TYPE sy-datum,
      gv_view TYPE c LENGTH 1 VALUE 'R',
      gv_rendered_view TYPE c LENGTH 1,
      gv_pr_docs TYPE i,
      gv_po_docs TYPE i,
      gv_sto_docs TYPE i,
      gv_pr_late TYPE i,
      gv_po_late TYPE i,
      ok_code TYPE sy-ucomm,
      gv_command TYPE sy-ucomm,
      gv_row TYPE i,
      gv_refresh TYPE abap_bool VALUE abap_true,
      gv_reselect TYPE abap_bool,        " 카드 전환: 이미 읽은 데이터로 목록만 바꿈
      gv_filter_changed TYPE abap_bool.
" ALV 제목(목록 이름 · 문서 건수 / 품목 수)
DATA gv_list_title TYPE c LENGTH 100.
DATA: go_container TYPE REF TO cl_gui_custom_container,
      go_grid TYPE REF TO cl_gui_alv_grid,
      gt_catalog TYPE lvc_t_fcat.
CLASS lcl_events DEFINITION DEFERRED.
DATA go_events TYPE REF TO lcl_events.
" 상단 카드(HTML). 조회 전환과 프로그램 이동만 하며 저장은 하지 않는다.
DATA: go_card_box TYPE REF TO cl_gui_custom_container,
      go_card_html TYPE REF TO cl_gui_html_viewer,
      gv_card_stamp TYPE string.
CLASS lcl_card_events DEFINITION DEFERRED.
DATA go_card_events TYPE REF TO lcl_card_events.
