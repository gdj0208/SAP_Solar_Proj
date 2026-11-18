*&---------------------------------------------------------------------*
*& Include Z8MMDS0100TOP                            - Report Z8MMDS0100
*&---------------------------------------------------------------------*
REPORT Z8MMDS0100.
TABLES: z8matplant_m, z8material_m.

"임시 ALV
*DATA: gt_stock TYPE STANDARD TABLE OF z8mm_c_matstock,
*          go_alv   TYPE REF TO cl_salv_table.
"탭스트립+서브스크린.
CONTROLS ts_main TYPE TABSTRIP.
DATA: gv_dynnr TYPE sy-dynnr VALUE '0110',
          ok_code TYPE sy-ucomm.

"탭1  1) 목록ALV
TYPES: BEGIN OF ty_list.
         INCLUDE TYPE z8mm_c_matstock.      " CDS 뷰의 필드를 전부 가져온다
TYPES:   light TYPE c LENGTH 1,             " 신호등 칸 (1=빨강 2=노랑 3=초록)
       END OF ty_list.

DATA: gt_list      TYPE STANDARD TABLE OF ty_list,
      gt_fcat_list TYPE lvc_t_fcat,
      gs_layo_list TYPE lvc_s_layo,
*      go_cont_list TYPE REF TO cl_gui_custom_container,
      go_grid_list TYPE REF TO cl_gui_alv_grid,
      go_cont_main TYPE REF TO cl_gui_custom_container,
      go_split_main TYPE REF TO cl_gui_splitter_container,
      go_split_body TYPE REF TO cl_gui_splitter_container,
      go_cont_kpi   TYPE REF TO cl_gui_container,
      go_cont_body  TYPE REF TO cl_gui_container,
      go_cont_tree  TYPE REF TO cl_gui_container,
      go_cont_list  TYPE REF TO cl_gui_container.

"탭1. 2) 트리.- Simple Tree
"노드 클릭시 해당노드가 어느 플랜트,자재유형,자재인지.
TYPES: BEGIN OF ty_nodemap,                " 노드 키 → 어떤 조건인지 기억하는 표
         node_key TYPE tv_nodekey,
         werks    TYPE z8matplant_m-werks,
         mtart    TYPE z8material_m-mtart,
         matnr    TYPE z8matplant_m-matnr,
       END OF ty_nodemap.

DATA: go_tree    TYPE REF TO cl_gui_simple_tree,
          gt_nodes   TYPE STANDARD TABLE OF mtreesnode,
          gt_nodemap TYPE STANDARD TABLE OF ty_nodemap,
          "노드 더블클릭시 목록ALV 변경.
          gt_show LIKE gt_list,            " 화면에 보이는 목록 (원본의 일부)
          gt_mtart_txt TYPE STANDARD TABLE OF dd07t.   " 자재유형 코드 → 한글명

"탭1. 3) 위에 상태 요약- HTML- KPI (부족·주의·정상·전체 건수)
DATA: go_html_kpi TYPE REF TO cl_gui_html_viewer,    " HTML을 띄우는 컨트롤
          gt_html     TYPE soli_tab,                                  " HTML을 담는 표
          gv_node_key TYPE tv_nodekey,      " 현재 선택한 트리 노드
          gv_status   TYPE c LENGTH 1.      " 현재 선택한 상태 (R/Y/G, 비어 있으면 전체)
*********************************************************************************
"탭2. 1)자재 드롭다운.
TYPE-POOLS vrm.                                        "드롭다운용 타입모음
DATA gv_matnr_sel TYPE z8e_matnr.      "드롭다운에서 선택한 자재

"탭2. 2) 입고 예정 문서 (CC_DETAIL 하나를 통째로 사용)
DATA: go_cont_det    TYPE REF TO cl_gui_custom_container,   " CC_DETAIL 상자
      gv_matnr_drawn TYPE z8e_matnr.                        " 지금 표에 그려진 자재

"탭2. 2) 플랜트별 재고 차트.
*DATA: go_cont_det   TYPE REF TO cl_gui_custom_container,   " CC_DETAIL 상자
*          go_split_det  TYPE REF TO cl_gui_splitter_container, " 위/아래로 나누는 도구
*          go_cont_chart TYPE REF TO cl_gui_container,          " 위 칸 (차트)
*          go_cont_fill  TYPE REF TO cl_gui_container,          " 아래 칸 (보충 현황, 다음 단계)
**          go_html_chart TYPE REF TO cl_gui_html_viewer,        " 차트를 그리는 HTML 뷰어
*          gv_matnr_drawn TYPE z8e_matnr.                       " 지금 차트에 그려진 자재

*DATA go_chart TYPE REF TO cl_gui_chart_engine.        " 기존 go_html_chart 대신

"탭2. 3) 자재 보충 진행 현황 ALV
TYPES: BEGIN OF ty_fill,                          " 보충 진행 현황 한 줄
         light     TYPE c LENGTH 1,              " 신호등
         stage     TYPE c LENGTH 14,             " 상태 (신호등 바로 옆)
         matnr     TYPE z8e_matnr,               " 자재 코드 ('전체' 보기에서 필요)
         maktx     TYPE c LENGTH 40,             " 자재명
         werks     TYPE z8mm_pr-werks,           " 정렬용 (화면에는 안 보임)
         plant_txt TYPE c LENGTH 24,             " "P100 경기남부공장"
         kind      TYPE c LENGTH 2,              " PR / PO
         docno     TYPE c LENGTH 10,             " 문서 번호
         item      TYPE c LENGTH 5,              " 품목 번호 (나중에 문서 상세 팝업용, 화면엔 안 보임)
         menge     TYPE z8mm_pr-menge,           " 수량
         meins     TYPE z8mm_pr-meins,
         lfdat     TYPE z8mm_pr-lfdat,           " 도착 예정일
        delay       TYPE i,                                   " 지연 일수 (예정일이 지난 만큼)
       END OF ty_fill.

CONSTANTS gc_all TYPE z8e_matnr VALUE 'ALL'.     " 드롭다운의 '전체' 항목 키

DATA: gt_fill      TYPE STANDARD TABLE OF ty_fill,
      gt_fcat_fill TYPE lvc_t_fcat,
      gs_layo_fill TYPE lvc_s_layo,
      go_grid_fill TYPE REF TO cl_gui_alv_grid.
******************************************************************************
"탭3. 조건+이동 내역  ALV
TYPES: BEGIN OF ty_move,
         budat TYPE budat,
         kind  TYPE c LENGTH 12,                       " 유형 (입고, 출고·설치, ...)
         matnr TYPE z8e_matnr,
         maktx TYPE z8e_maktx,
         qty   TYPE z8e_menge,                         " 부호 있는 수량
          qty_txt TYPE c LENGTH 12,                     " +51, -76 처럼 보여줄 문자
         meins TYPE meins,
         werks TYPE z8e_werks,
         reftx TYPE c LENGTH 24,                       " 참조 (PO, 납품 번호)
         mblnr TYPE z8e_mblnr,
       END OF ty_move.

DATA: gv_budat_fr TYPE budat,
      gv_budat_to TYPE budat,
      gv_werks_mv TYPE z8e_werks,
      gv_matnr_mv TYPE z8e_matnr,
      gv_mv_reload TYPE c LENGTH 1,                    " 조회 버튼을 눌렀을 때만 다시 읽기
      gt_move      TYPE STANDARD TABLE OF ty_move,
      gs_move      TYPE ty_move,
      gt_fcat_move TYPE lvc_t_fcat,
      gs_fcat_move TYPE lvc_s_fcat,
      gs_layo_move TYPE lvc_s_layo,
      go_cont_move TYPE REF TO cl_gui_custom_container,
      go_grid_move TYPE REF TO cl_gui_alv_grid,
      gv_day_err    TYPE abap_bool.
"드롭다운.
DATA: gt_move_all TYPE STANDARD TABLE OF ty_move,      " DB에서 읽은 전체
      gv_kind_sel TYPE c LENGTH 12,                    " 유형 필터 선택값
      gv_mv_filter TYPE c LENGTH 1.                    " 필터만 다시 적용할 때

"탭3. 이동내역
*DATA: go_cont_mvf TYPE REF TO cl_gui_custom_container,
DATA: go_split_move TYPE REF TO cl_gui_splitter_container,   " 위/아래로 나누는 도구
      go_cont_mvf   TYPE REF TO cl_gui_container,            " 위 칸 (칩)  ← 타입 변경
      go_html_mvf TYPE REF TO cl_gui_html_viewer,
      go_cont_mvb   TYPE REF TO cl_gui_container.            " 아래 칸 (표)\

"탭3. 소진예상 ALV
TYPES: BEGIN OF ty_dep,                       " 소진 예상 한 줄 (자재×플랜트)
         light    TYPE icon_d," TYPE c LENGTH 1,           " 7일 이내 1, 14일 이내 2, 그 외 3
         matnr     TYPE z8e_matnr,
         maktx     TYPE c LENGTH 40,
         werks     TYPE z8mm_pr-werks,
         plant_txt TYPE c LENGTH 24,
         avail     TYPE p LENGTH 13 DECIMALS 3,   " 가용 재고
         out30     TYPE p LENGTH 13 DECIMALS 3,   " 최근 30일 출고
         meins     TYPE z8mm_pr-meins,
         days      TYPE i,                        " 정렬용 (화면에는 안 보임)
         days_txt  TYPE c LENGTH 10,              " "약 38일" / "-"
       END OF ty_dep.

DATA: gt_dep      TYPE STANDARD TABLE OF ty_dep,
      gt_fcat_dep TYPE lvc_t_fcat,
      gs_layo_dep TYPE lvc_s_layo,
      go_grid_dep TYPE REF TO cl_gui_alv_grid,
      go_split_det TYPE REF TO cl_gui_splitter_container,   " 위/아래로 나누는 도구
      go_cont_fill TYPE REF TO cl_gui_container,            " 위 칸 (입고 예정)
      go_cont_dep  TYPE REF TO cl_gui_container.            " 아래 칸 (소진 예상)
