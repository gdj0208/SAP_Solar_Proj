*&---------------------------------------------------------------------*
*& Include          Z8SDD0100TOP
*&---------------------------------------------------------------------*

DATA: ok_code        TYPE sy-ucomm,
      gv_selected_so TYPE z8sd_so_h-vbeln_s,
      gv_search_so   TYPE z8sd_so_h-vbeln_s,
      gv_sdate       TYPE z8ps_project-sdate,
      gv_edate       TYPE z8ps_project-edate,
      gv_werks       TYPE z8plant_m-werks,
      gv_status_d    TYPE z8sd_deliv_h-status_d,
      gv_status_mat  TYPE z8e_status_mat.

DATA: go_container   TYPE REF TO cl_gui_custom_container,
      go_container_h TYPE REF TO cl_gui_container,
      go_container_i TYPE REF TO cl_gui_container,
      go_alv_h       TYPE REF TO cl_gui_alv_grid,
      go_alv_i       TYPE REF TO cl_gui_alv_grid,
      gt_fcat_h      TYPE lvc_t_fcat,
      gw_fcat_h      TYPE lvc_s_fcat,
      gt_fcat_i      TYPE lvc_t_fcat,
      gw_fcat_i      TYPE lvc_s_fcat,
      gs_layout_h    TYPE lvc_s_layo,
      gs_layout_i    TYPE lvc_s_layo,
      gs_stable_h    TYPE lvc_s_stbl,
      gs_stable_i    TYPE lvc_s_stbl,
      go_split       TYPE REF TO cl_gui_splitter_container.

DATA: BEGIN OF gw_deliv_h.
        INCLUDE TYPE z8sd_deliv_h.
DATA:   kunnr          TYPE z8customer_m-kunnr,
        name1          TYPE z8customer_m-name1,
        pro_id         TYPE z8ps_project-pro_id,
        bupla          TYPE z8branch_m-branch,
        werks          TYPE z8plant_m-werks,
        werks_txt      TYPE z8plant_m-name1, "플랜트명
        status_txt     TYPE char60,
        light(1)       TYPE c, "상태 - 신호등 컬럼
        mat_status_txt TYPE char60, "자재 확보 상태
        ename          TYPE z8employee_m-ename,
        sdate          TYPE z8ps_project-sdate,
        belnr          TYPE z8fi_accdoc_h-belnr, "전표번호
        ct             TYPE lvc_t_styl.

DATA END OF gw_deliv_h.

DATA gt_deliv_h LIKE TABLE OF gw_deliv_h.

DATA: BEGIN OF gw_deliv_i.
        INCLUDE TYPE z8sd_so_i.
DATA:   vbeln_d         TYPE z8sd_deliv_i-vbeln_d,
        status_i        TYPE z8sd_deliv_i-status_i,
        werks           TYPE z8plant_m-werks,
        lgort           TYPE z8material_stk_m-lgort, "Storage Location
        labst           TYPE z8material_stk_m-labst, "현재고
        available_stock TYPE z8material_stk_m-labst, "가용재고
        zzrsvqty        TYPE z8material_stk_m-zzrsvqty, "예약재고
        lfimg           TYPE z8sd_deliv_i-lfimg, "실제 출고 재고
        eisbe           TYPE z8matplant_m-eisbe, "안전재고
        stock_shortage  TYPE char10,
        status_txt      TYPE char60,
        netpr_p         TYPE z8sd_price_m-netpr,
        wrbtr           TYPE z8fi_accdoc_i-wrbtr,
        vgpos           TYPE z8sd_deliv_i-vgpos,
        cell_color      TYPE lvc_t_scol,
        VRKME2          TYPE z8sd_so_i-vrkme.
DATA: END OF gw_deliv_i.

DATA gt_deliv_i LIKE TABLE OF gw_deliv_i.
