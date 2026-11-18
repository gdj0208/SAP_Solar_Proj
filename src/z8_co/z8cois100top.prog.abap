*&---------------------------------------------------------------------*
*& Include Z8COIS100TOP                             - Report Z8COIS100
*&---------------------------------------------------------------------*
REPORT z8cois100.

TABLES :
  z8co_sum_qtr,
  z8vendor_m,
  z8plant_m.

TYPE-POOLS: vrm.

TYPES: BEGIN OF ty_profit_data,
         org_id    TYPE bupla,       "
         org_name  TYPE z8plant_m-name1,   " 조직명
         proj_id   TYPE z8ps_project-pro_id,       " 제품 ID

         light TYPE icon_d,
         gross_status type c LENGTH 5,
         sales_amt TYPE Z8E_NETPR, " 매출액
         cogs_amt  TYPE VERPR, " 매출원가 (이전 프로그램에서 가져옴)
         gross_pr  TYPE Z8E_NETPR,   " 매출총이익 (매출액 - 원가)
         sga_amt   TYPE NETPR,    " 판관비 (임대료 등)
         op_profit TYPE NETPR,     " 영업이익 (매출총이익 - 판관비)
         WAERK TYPE WAERK,          " 가격 단위


         sales_txt TYPE c LENGTH 25,    " 이하 5개 추가 (표시용)
         cogs_txt  TYPE c LENGTH 25,
         gross_txt TYPE c LENGTH 25,
         sga_txt   TYPE c LENGTH 25,
         op_txt    TYPE c LENGTH 25,
       END OF ty_profit_data.

DATA :
  gv_month TYPE spmon,
  ok_code      TYPE sy-ucomm,
  gv_branch TYPE z8ps_project-branch,
  gv_werks     TYPE bupla,
  gv_date      TYPE datum,

  gt_raw_data TYPE STANDARD TABLE OF ty_profit_data, " DB에서 긁어온 원본
  gt_tree_out TYPE STANDARD TABLE OF ty_profit_data, " Tree 화면에 뿌릴 출력용

  gt_sales_rev TYPE TABLE OF z8co_sum_qtr,
  gs_sales_rev TYPE z8co_sum_qtr,

  gt_outtab TYPE STANDARD TABLE OF ty_profit_data,

  lt_year      TYPE vrm_values,
  ls_year      TYPE vrm_value,
  lt_qt        TYPE vrm_values,
  ls_qt        TYPE vrm_value.

DATA :
  go_chart_container TYPE REF TO cl_gui_docking_container,
  go_chart           TYPE REF TO cl_gui_chart_engine,
  go_split TYPE REF TO cl_gui_splitter_container,

  go_ixml            TYPE REF TO if_ixml,
  go_ixml_sf         TYPE REF TO if_ixml_stream_factory,
  go_ixml_data_doc   TYPE REF TO if_ixml_document,
  go_ostream         TYPE REF TO if_ixml_ostream,
  go_encoding        TYPE REF TO if_ixml_encoding,

  root               TYPE REF TO if_ixml_element,
  categories         TYPE REF TO if_ixml_element,
  category           TYPE REF TO if_ixml_element,
  point              TYPE REF TO if_ixml_element,
  value              TYPE REF TO if_ixml_element,
  sales_amt          TYPE REF TO if_ixml_element,
  gross_prof           TYPE REF TO if_ixml_element,
  buis_prof            TYPE REF TO if_ixml_element,

  xdata              TYPE xstring,
  gv_cust_xml type xstring.

RANGES: s_date FOR z8fi_accdoc_h-budat.

DATA:
  go_alv_tree         TYPE REF TO cl_gui_alv_tree,
  gv_root_key         TYPE lvc_nkey, " 최상위 노드(전사 총계) 키
  gv_org_key          TYPE lvc_nkey, " 2레벨 노드(조직/지점) 키
  gv_prod_key         TYPE lvc_nkey, " 3레벨 노드(제품 상세) 키

  go_custom_container TYPE REF TO cl_gui_custom_container,
  gt_fcat             TYPE lvc_t_fcat,
  gs_layout           TYPE lvc_s_layo.

SELECTION-SCREEN BEGIN OF SCREEN 0110 AS SUBSCREEN.
  SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE TEXT-bl1.
    SELECTION-SCREEN BEGIN OF LINE.
      SELECTION-SCREEN COMMENT 1(10) TEXT-t03. " '조회 기간'

      " 시작 연도/분기
      PARAMETERS: p_f_yr TYPE char4 AS LISTBOX VISIBLE LENGTH 10,
                  p_f_qt TYPE char1 AS LISTBOX VISIBLE LENGTH 10.

      SELECTION-SCREEN COMMENT 36(3) TEXT-t04. " ' ~ '

      " 종료 연도/분기
      PARAMETERS: p_t_yr TYPE char4 AS LISTBOX VISIBLE LENGTH 10 ,
                  p_t_qt TYPE char1 AS LISTBOX VISIBLE LENGTH 10 .
    SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN END OF BLOCK blk1.
SELECTION-SCREEN END OF SCREEN 0110.
