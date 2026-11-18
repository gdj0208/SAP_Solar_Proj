*&---------------------------------------------------------------------*
*& Report Z8MMMA0100TOP.
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*

REPORT z8mmma0100top.

TABLES: z8material_m, z8material_txt_m, z8vendor_m, z8s_mat_detail, Z8S_VEND_DETAIL, sscrfields.
DATA ok_code TYPE sy-ucomm.
DATA: gv_locked TYPE c LENGTH 1.
DATA: gv_locked_v TYPE c LENGTH 1.
DATA:   gs_funct TYPE smp_dyntxt.
DATA gt_ex_list TYPE STANDARD TABLE OF sy-ucomm.
"상태와 모듈 텍스트.
DATA: gv_cd        TYPE c LENGTH 4,       " 번역할 코드
      gv_tx        TYPE c LENGTH 16,      " 번역 결과
      gv_mtart_txt TYPE c LENGTH 16,      " 0300 화면용
      gv_mstae_txt TYPE c LENGTH 16.      " 0300 화면용

" 자재- 구조체 정의.
TYPES: BEGIN OF ty_mat_list,
         matnr    TYPE z8material_m-matnr,
         maktx    TYPE z8material_txt_m-maktx,
         mtart    TYPE z8material_m-mtart,
         zzmfr    TYPE z8material_m-zzmfr,
         zzrtkpz  TYPE z8material_m-zzrtkpz,
         zzrtunt  TYPE z8material_m-zzrtunt,
         mstae    TYPE z8material_m-mstae,
         light(1) TYPE c,
           mtart_txt TYPE c LENGTH 16,
         mstae_txt TYPE c LENGTH 16,
       END OF ty_mat_list.

" 공급업체- 구조체 정의.
TYPES: BEGIN OF ty_vend_list,
         lifnr       TYPE z8vendor_m-lifnr,
         name1       TYPE z8vendor_m-name1,
         region_code TYPE z8vendor_m-region_code,
         land1       TYPE z8vendor_m-land1,
         ort01       TYPE z8vendor_m-ort01,
         telf1       TYPE z8vendor_m-telf1,
       END OF ty_vend_list.

DATA: gt_mat_list    TYPE STANDARD TABLE OF ty_mat_list,
      gw_mat_list    LIKE LINE OF gt_mat_list,
      gt_vend_list   TYPE STANDARD TABLE OF ty_vend_list, "목록 내부테이블
      "화면 간 전달용.
      gv_matnr_sel   TYPE z8material_m-matnr,
      gv_lifnr_sel   TYPE z8vendor_m-lifnr, "선택한 업체코드
*      gv_matnr_input TYPE c LENGTH 1,
      gv_screen_init TYPE c LENGTH 1,
      gv_mode        TYPE c LENGTH 1,  " 'N'=신규, 'D'=조회
      gw_vend_list     LIKE LINE OF gt_vend_list, "목록 한 줄
      gv_mode_v        TYPE c LENGTH 1,      " 'N'=신규, 'D'=조회 (공급업체용)
      gv_screen_init_v TYPE c LENGTH 1.

DATA: go_cont_100 TYPE REF TO cl_gui_custom_container,
      go_alv_100  TYPE REF TO cl_gui_alv_grid,
      go_cont_200 TYPE REF TO cl_gui_custom_container,
      go_alv_200  TYPE REF TO cl_gui_alv_grid.

DATA: gt_fcat_100 TYPE lvc_t_fcat,
      gs_fcat_100 TYPE lvc_s_fcat,
      gt_fcat_200 TYPE lvc_t_fcat,
      gs_fcat_200 TYPE lvc_s_fcat.
DATA: gs_layout_100 TYPE lvc_s_layo,
      gs_layout_200 TYPE lvc_s_layo.
"------------------------------------------------------------------------------
"300번화면 - 플랜트 관리정보 & 자재평가 alv
DATA: gt_plant     TYPE STANDARD TABLE OF z8matplant_m,
           gw_plant     LIKE LINE OF gt_plant,
           " 자재 저장
           gw_stock TYPE z8material_stk_m,
            gv_dummy TYPE z8material_stk_m-matnr,
         "진입시 원본-> 화면에서 지운 행 찾기.
           gt_val       TYPE STANDARD TABLE OF z8material_val_m,
           gw_val       LIKE LINE OF gt_val.

DATA: go_cont_plant TYPE REF TO cl_gui_custom_container,
      go_alv_plant TYPE REF TO cl_gui_alv_grid,
      gt_fcat_plant TYPE lvc_t_fcat,
      gw_fcat_plant  TYPE lvc_s_fcat.

DATA: BEGIN OF gw_plant_row,
        icon    TYPE icon-id,                      " 상태 신호등
        werks   TYPE z8plant_m-werks,              " 플랜트
        name1   TYPE z8plant_m-name1,              " 플랜트명
        brname  TYPE z8branch_m-name,              " 지사명
        eisbe   TYPE z8matplant_m-eisbe,           " 안전재고
        meins   TYPE z8matplant_m-meins,           " 단위
        ekgrp   TYPE z8matplant_m-ekgrp,           " 구매그룹
        mmsta   TYPE z8matplant_m-mmsta,           " 상태코드
        verpr   TYPE z8material_val_m-verpr,       " 이동평균가
        peinh   TYPE z8material_val_m-peinh,       " 가격단위
        waers   TYPE z8material_val_m-waers,       " 통화
        lbkum   TYPE z8material_val_m-lbkum,       " 평가재고수량
        labst   TYPE z8material_stk_m-labst,       " 현재고
        mabst TYPE z8matplant_m-mabst,
        zzrsvqty TYPE z8material_stk_m-zzrsvqty,
        avail    TYPE z8material_stk_m-labst,    " 가용재고 (현재고 - 예약재고 - 안전재고)
        exist_p TYPE c LENGTH 1,                   " 플랜트정보가 DB에 있는지
        exist_v TYPE c LENGTH 1,                   " 평가정보가 DB에 있는지
        new_p  TYPE c LENGTH 1,                    "새롭게 관리하는 줄인지.
      END OF gw_plant_row.

DATA: gt_plant_row LIKE TABLE OF gw_plant_row.
DATA: gt_stk TYPE STANDARD TABLE OF z8material_stk_m,
      gw_stk LIKE LINE OF gt_stk.

DATA: gt_plantm TYPE STANDARD TABLE OF z8plant_m,
      gw_plantm LIKE LINE OF gt_plantm,
      gt_branch TYPE STANDARD TABLE OF z8branch_m,
      gw_branch LIKE LINE OF gt_branch.

"자재/플랜트/평가 정보 DB 저장 전 검증.
DATA: gv_filled TYPE c LENGTH 1,
            gv_err    TYPE c LENGTH 1,
            gv_count  TYPE i,
            gv_msg    TYPE string.
"자재 평가
"회계계정코드.
DATA: gv_drcls TYPE z8material_val_m-zzdrcls VALUE '14100000'.
"400번화면 공급업체 취급자재 alv
DATA: BEGIN OF gw_vmat_row,
        icon        TYPE icon-id,                    " 상태 신호등
        matnr       TYPE z8material_m-matnr,         " 자재코드
        maktx       TYPE z8material_txt_m-maktx,     " 자재명
        meins       TYPE z8purch_info_m-meins,        " 구매단위
        netpr       TYPE z8purch_info_m-netpr,        " 순단가
        peinh       TYPE z8purch_info_m-peinh,        " 가격단위
        waers       TYPE z8purch_info_m-waers,        " 통화
        minbm       TYPE z8purch_info_m-minbm,        " 최소구매수량
*        other_lifnr TYPE z8vendor_m-lifnr,           " 다른 업체 코드
*        other_name  TYPE z8vendor_m-name1,           " 다른 업체명
          vcnt        TYPE   i,                                   "취급자재수.
        exist_i     TYPE c LENGTH 1,                 " 이 업체의 구매정보가 DB에 있는지
*        locked      TYPE c LENGTH 1,                 " 다른 업체가 취급 중인지
        new_i       TYPE c LENGTH 1,                  "새로 취급 시작하는 줄
        del_i         TYPE c LENGTH 1,
      END OF gw_vmat_row.

DATA: gt_vmat_row LIKE TABLE OF gw_vmat_row.
DATA: gw_vm_cnt TYPE z8purch_info_m.
*DATA: gv_chk_lifnr TYPE z8purch_info_m-lifnr.

DATA: gt_vm_mat  TYPE STANDARD TABLE OF z8material_m,
      gw_vm_mat  LIKE LINE OF gt_vm_mat,
      gt_vm_txt  TYPE STANDARD TABLE OF z8material_txt_m,
      gw_vm_txt  LIKE LINE OF gt_vm_txt,
      gt_vm_info TYPE STANDARD TABLE OF z8purch_info_m,
      gw_vm_info LIKE LINE OF gt_vm_info.
*      gt_vm_vend TYPE STANDARD TABLE OF z8vendor_m,
*      gw_vm_vend LIKE LINE OF gt_vm_vend.

DATA: go_cont_vmat   TYPE REF TO cl_gui_custom_container,
      go_alv_vmat    TYPE REF TO cl_gui_alv_grid,
      gt_fcat_vmat   TYPE lvc_t_fcat,
      gw_fcat_vmat   TYPE lvc_s_fcat,
      gs_layout_vmat TYPE lvc_s_layo.
"버튼 숨기기,
DATA: gt_excl TYPE STANDARD TABLE OF sy-ucomm,
      gv_excl TYPE sy-ucomm.
DATA: gv_ans2 TYPE c LENGTH 1.
