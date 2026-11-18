*&---------------------------------------------------------------------*
*& Include          Z8MMMA0100F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Form create_objects
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects .
  CREATE OBJECT go_cont_100
    EXPORTING
      container_name              = 'M_ALV'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.

  CREATE OBJECT go_alv_100
    EXPORTING
      i_parent          = go_cont_100
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv .
  CALL METHOD go_alv_100->set_table_for_first_display
    EXPORTING
*     i_structure_name              = 'z137_00004'
*     is_variant                    =
*     i_save                        =
*     i_default                     = 'X'
      is_layout                     = gs_layout_100
    CHANGING
      it_outtab                     = gt_mat_list
      it_fieldcatalog               = gt_fcat_100
*     it_sort                       =
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
*   Implement suitable error handling here
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_100 .
  CLEAR: gt_fcat_100, gs_fcat_100.
  gt_fcat_100 = VALUE #(
    ( fieldname = 'MATNR'   coltext = '자재코드'   outputlen = 15  hotspot = 'X' )
    ( fieldname = 'MAKTX'   coltext = '자재명'     outputlen = 25 )
    ( fieldname = 'MTART_TXT'   coltext = '카테고리'   outputlen = 15  )
    ( fieldname = 'ZZMFR'   coltext = '제조사'     outputlen = 17 )
    ( fieldname = 'ZZRTKPZ' coltext = '정격용량'   outputlen = 15 no_zero = 'X')
    ( fieldname = 'ZZRTUNT' coltext = '단위'       outputlen = 6  )
    ( fieldname = 'MSTAE_TXT'   coltext = '상태'       outputlen = 15  )
    ( fieldname = 'LIGHT' coltext = '자재상태' col_pos = 0  outputlen = 10 )
  ).
*  CLEAR gs_fcat_100.
*  gs_fcat_100-fieldname = 'MATNR'.
*  gs_fcat_100-coltext   = '자재코드'.
*  gs_fcat_100-outputlen = 4.
*  APPEND gs_fcat_100 TO gt_fcat_100.
*
*  CLEAR gs_fcat_100.
*  gs_fcat_100-fieldname = 'MATKX'.
*  gs_fcat_100-coltext   = '자재명'.
*  gs_fcat_100-outputlen = 4.
*  APPEND gs_fcat_100 TO gt_fcat_100.
*
*  CLEAR gs_fcat_100.
*  gs_fcat_100-fieldname = 'MATART'.
*  gs_fcat_100-coltext   = '카테고리'.
*  gs_fcat_100-outputlen = 4.
*  APPEND gs_fcat_100 TO gt_fcat_100.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_material_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_material_list .
  DATA lr_mstae TYPE RANGE OF z8material_m-mstae.

  CLEAR gt_mat_list.

  "검색조건- 상태
  IF p_use = 'X'.
    lr_mstae = VALUE #( ( sign = 'I' option = 'EQ' low = '01' ) ).
  ELSEIF p_stop = 'X'.
    lr_mstae = VALUE #( ( sign = 'I' option = 'EQ' low = '99' ) ).
  ENDIF.
  "자재목록조회.
  SELECT a~matnr, b~maktx, a~mtart, a~zzmfr, a~zzrtkpz, a~zzrtunt, a~mstae
    FROM z8material_m AS a
    LEFT OUTER JOIN z8material_txt_m AS b
    ON b~matnr = a~matnr
    AND b~spras ='3'
    WHERE a~matnr IN @s_matnr
    AND ( a~mtart = @p_mtart OR @p_mtart = @space )
    AND a~mstae IN @lr_mstae
    ORDER BY a~mtart, a~matnr
    INTO TABLE @gt_mat_list.

  "검색조건 - 자재명
  IF p_maktx IS NOT INITIAL.
    DELETE gt_mat_list WHERE maktx NS p_maktx.
  ENDIF.

  "자재 사용중(01)/ 자재사용중단(99)
  LOOP AT gt_mat_list INTO gw_mat_list.
    CASE gw_mat_list-mstae.
      WHEN '01'.
        gw_mat_list-light = '3'.
      WHEN '99'.
        gw_mat_list-light = '1'.
    ENDCASE.
    "카테고리, 상태를 글자로
    gv_cd = gw_mat_list-mtart.
    PERFORM mtart_to_text.
    gw_mat_list-mtart_txt = gv_tx.

    gv_cd = gw_mat_list-mstae.
    PERFORM mstae_to_text.
    gw_mat_list-mstae_txt = gv_tx.

    MODIFY gt_mat_list FROM gw_mat_list.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form create_objects_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM create_objects_200 .
  CREATE OBJECT go_cont_200
    EXPORTING
      container_name              = 'V_ALV'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.

  CREATE OBJECT go_alv_200
    EXPORTING
      i_parent          = go_cont_200
    EXCEPTIONS
      error_cntl_create = 1
      error_cntl_init   = 2
      error_cntl_link   = 3
      error_dp_create   = 4
      OTHERS            = 5.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form display_alv_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM display_alv_200 .
  CALL METHOD go_alv_200->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout_200
    CHANGING
      it_outtab                     = gt_vend_list
      it_fieldcatalog               = gt_fcat_200
*     it_sort                       =
*     it_filter                     =
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
*   Implement suitable error handling here
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form get_vendor_list
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM get_vendor_list .
  CLEAR gt_vend_list.
  "업체명 검색조건.
  DATA(lv_name) = COND string( WHEN p_name1 IS NOT INITIAL
                               THEN |%{ p_name1 }%|
                               ELSE '%' ).

  SELECT * FROM z8vendor_m
    WHERE lifnr IN @s_lifnr
    AND name1 LIKE @lv_name
    ORDER BY lifnr
    INTO CORRESPONDING FIELDS OF TABLE @gt_vend_list.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_200 .
  CLEAR: gt_fcat_200, gs_fcat_200.
  gt_fcat_200 = VALUE #(
    ( fieldname = 'LIFNR'   coltext = '업체코드'   outputlen = 10   hotspot = 'X' )
    ( fieldname = 'NAME1'   coltext = '업체명'     outputlen = 20 )
    ( fieldname = 'REGION_CODE'   coltext = '지역코드'   outputlen = 8 )
    ( fieldname = 'LAND1'   coltext = '국가'     outputlen = 4 )
    ( fieldname = 'ORT01' coltext = '도시'   outputlen = 4 )
    ( fieldname = 'TELF1' coltext = '전화'       outputlen = 15  )
  ).


ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_event_handler
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_event_handler .
  SET HANDLER: lc1_handler=>on_doubleclick FOR go_alv_100,
                         lc1_handler=>on_hotspot_click FOR go_alv_100.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout_100
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout_100 .
  gs_layout_100-sel_mode = 'A'.

  gs_layout_100-excp_fname = 'LIGHT'.
  gs_layout_100-excp_led = 'X'.
  gs_layout_100-zebra      = 'X'.
*  gs_layout_100-cwidth_opt = 'X'.
  gs_layout_100-no_toolbar = 'X'.
  gs_layout_100-grid_title = |자재 목록 ({ lines( gt_mat_list ) }건)|.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form deactivate_material
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM deactivate_material .
  DATA: lt_rows TYPE lvc_t_row,
        ls_row  TYPE lvc_s_row.

  "체크된 행 목록 가져오기.
  go_alv_100->get_selected_rows(
    IMPORTING et_index_rows = lt_rows ).

  IF  lt_rows IS INITIAL.
    MESSAGE '대상을 선택하세요' TYPE 'I'.
    RETURN.
  ENDIF.

  "확인 팝업 띄우기.
  DATA: lv_answer TYPE c.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question = '선택한 자재를 사용중단 처리하시겠습니까?'
    IMPORTING
      answer        = lv_answer.
  IF lv_answer <> '1'.
    RETURN.
  ENDIF.

  "체크된 행마다 업데이트하기.
  LOOP AT lt_rows INTO ls_row.
    READ TABLE gt_mat_list INTO DATA(ls_mat) INDEX ls_row-index.
    IF sy-subrc = 0 AND ls_mat-mstae <> '99'. "이미 중단된 건 건너뜀,
      UPDATE z8material_m
        SET mstae = '99'
               laeda = sy-datum
               aenam = sy-uname
        WHERE matnr = ls_mat-matnr.
    ENDIF.
  ENDLOOP.

  COMMIT WORK.
  MESSAGE '사용중단 처리되었습니다' TYPE 'S'.

  "목록 새로고침
  PERFORM get_material_list.
  go_alv_100->refresh_table_display( ) .


ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_material
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM save_material .
  DATA: ls_mat  TYPE z8material_m,
        ls_text TYPE z8material_txt_m,
        lv_cnt  TYPE i,
        lv_ans  TYPE c LENGTH 1,
        ls_old  TYPE z8material_m.

  TRANSLATE z8s_mat_detail-matnr TO UPPER CASE.
    " 용량단위: 비어 있으면 자재유형으로 자동 지정
  IF z8s_mat_detail-zzrtunt IS INITIAL.
    CASE z8s_mat_detail-mtart.
      WHEN 'MOD'. z8s_mat_detail-zzrtunt = 'W'.
      WHEN 'INV'. z8s_mat_detail-zzrtunt = 'KW'.
      WHEN 'ESS'. z8s_mat_detail-zzrtunt = 'KWH'.
       WHEN 'CBL'. z8s_mat_detail-zzrtunt = 'MM2'.
    ENDCASE.
  ENDIF.

    " 중량단위: 화면에 칸이 없으므로 KG로 고정
  IF z8s_mat_detail-gewei IS INITIAL.
    z8s_mat_detail-gewei = 'KG'.
  ENDIF.

  "1. 필수값.
  IF z8s_mat_detail-matnr IS INITIAL.
    MESSAGE '자재코드를 입력하세요' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  IF z8s_mat_detail-maktx IS INITIAL.
    MESSAGE '자재명을 입력하세요' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  IF z8s_mat_detail-mtart IS INITIAL.
    MESSAGE '카테고리를 입력하세요' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  IF z8s_mat_detail-meins IS INITIAL.
    MESSAGE '기본단위를 입력하세요' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  "정격용량 필수.
  IF z8s_mat_detail-mtart = 'MOD' OR z8s_mat_detail-mtart = 'INV'
     OR z8s_mat_detail-mtart = 'ESS'.
    IF z8s_mat_detail-zzrtkpz <= 0.
      MESSAGE '정격용량을 입력하세요' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
    IF z8s_mat_detail-zzrtunt IS INITIAL.
      MESSAGE '용량단위를 입력하세요' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
  ENDIF.


  "2. 신규면 중복체크
  IF gv_mode = 'N'.
    SELECT COUNT(*) FROM z8material_m
      INTO lv_cnt
      WHERE matnr = z8s_mat_detail-matnr.
    IF lv_cnt > 0.
      MESSAGE '이미 등록된 자재코드입니다' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
  ENDIF.

  "플랜트 검증
  PERFORM check_plant_rows.
  IF gv_err = 'X'.
    RETURN.
  ENDIF.

  "3. 확인팝업.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question = COND #( WHEN gv_mode = 'N'
                              THEN '신규 자재를 등록하시겠습니까?'
                              ELSE '수정 내용을 저장하시겠습니까?' )
    IMPORTING
      answer        = lv_ans.
  IF lv_ans <> '1'.
    RETURN.
  ENDIF.
  "4. 저장.
  IF gv_mode <> 'N'.
    " 수정: 기존 행을 먼저 읽어서, 화면에 없는 칸(생성일·생성자 등)을 지킨다
    SELECT SINGLE * FROM z8material_m
      WHERE matnr = @z8s_mat_detail-matnr
      INTO @ls_old.
    IF sy-subrc <> 0.
      MESSAGE '자재를 찾을 수 없습니다' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
    ls_mat = ls_old.
  ENDIF.

  MOVE-CORRESPONDING z8s_mat_detail TO ls_mat.
  IF gv_mode <> 'N'.
    ls_mat-ersda = ls_old-ersda.      " 화면 구조에 같은 이름 칸이 있어도 원래 값 유지
    ls_mat-ernam = ls_old-ernam.
  ENDIF.
  ls_mat-mandt = sy-mandt.
  ls_mat-laeda = sy-datum.
  ls_mat-aenam = sy-uname.

  ls_text-mandt = sy-mandt.
  ls_text-matnr = ls_mat-matnr.
  ls_text-spras = '3'.
  ls_text-maktx = z8s_mat_detail-maktx.

  IF ls_mat-matkl IS INITIAL.
    CASE ls_mat-mtart.
      WHEN 'MOD'. ls_mat-matkl = '모듈'.
      WHEN 'INV'. ls_mat-matkl = '인버터'.
      WHEN 'ESS'. ls_mat-matkl = 'ESS'.
      WHEN 'CBL'. ls_mat-matkl = '케이블'.
      WHEN 'STR'. ls_mat-matkl = '구조물'.
      WHEN 'ELE'. ls_mat-matkl = '접속반'.
    ENDCASE.
  ENDIF.

  IF gv_mode = 'N'.
    ls_mat-ersda = sy-datum.
    ls_mat-ernam = sy-uname.
    INSERT z8material_m FROM ls_mat.
  ELSE.
    UPDATE z8material_m FROM ls_mat.
  ENDIF.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE '저장 중 오류가 발생했습니다' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.

  MODIFY z8material_txt_m FROM ls_text.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE '저장 중 오류가 발생했습니다' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.

  "DB에  플랜트 정보 저장.
  PERFORM save_plant_rows.
  IF gv_err = 'X'.
    ROLLBACK WORK.
    MESSAGE '저장 중 오류가 발생했습니다' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  "DB에 자재평가 정보 저장.
  PERFORM save_val_rows.
  IF gv_err = 'X'.
    ROLLBACK WORK.
    MESSAGE '저장 중 오류가 발생했습니다' TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  COMMIT WORK.
  MESSAGE '저장되었습니다' TYPE 'S'.

  CLEAR gv_screen_init.
  PERFORM free_alv_plant.
  PERFORM unlock_material.
  LEAVE TO SCREEN 0.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_input
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_input .
  DATA: ls_matnr LIKE LINE OF s_matnr,
        ls_lifnr LIKE LINE OF s_lifnr,
        lv_matnr TYPE z8material_m-matnr,
        lv_mtart TYPE z8material_m-mtart,
        lv_lifnr TYPE z8vendor_m-lifnr.

  "1) 자재관리 선택시.
  IF p_mat = 'X'.
    " 자재코드: 단일값(EQ)만 존재 여부 검사
    LOOP AT s_matnr INTO ls_matnr
         WHERE sign = 'I' AND option = 'EQ'.
      SELECT SINGLE matnr FROM z8material_m
        INTO lv_matnr
        WHERE matnr = ls_matnr-low.
      IF sy-subrc <> 0.
        MESSAGE '존재하지 않는 자재코드입니다' TYPE 'E'.
      ENDIF.
    ENDLOOP.

    " 카테고리
    IF p_mtart IS NOT INITIAL.
      SELECT SINGLE mtart FROM z8material_m
        INTO lv_mtart
        WHERE mtart = p_mtart.
      IF sy-subrc <> 0.
        MESSAGE '존재하지 않는 카테고리입니다' TYPE 'E'.
      ENDIF.
    ENDIF.

  ELSE.
    "2) 공급업체 선택시.
    " 업체코드
    LOOP AT s_lifnr INTO ls_lifnr
         WHERE sign = 'I' AND option = 'EQ'.
      SELECT SINGLE lifnr FROM z8vendor_m
        INTO lv_lifnr
        WHERE lifnr = ls_lifnr-low.
      IF sy-subrc <> 0.
        MESSAGE '존재하지 않는 업체코드입니다' TYPE 'E'.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form show_alv_plant
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM show_alv_plant .
  DATA ls_layout TYPE lvc_s_layo.
  DATA lv_input  TYPE i.
  IF gv_mode = 'D'.
    lv_input = 0.
  ELSE.
    lv_input = 1.
  ENDIF.


  IF go_cont_plant IS INITIAL.
    CREATE OBJECT go_cont_plant
      EXPORTING
        container_name = 'P_ALV'.
    CREATE OBJECT go_alv_plant
      EXPORTING
        i_parent = go_cont_plant.

    PERFORM set_field_catalog_plant.
    ls_layout-sel_mode   = 'A'.
    ls_layout-zebra      = 'X'.
    ls_layout-no_toolbar = 'X'.
*    ls_layout-cwidth_opt = 'X'.

    CALL METHOD go_alv_plant->set_table_for_first_display
      EXPORTING
        is_layout       = ls_layout
      CHANGING
        it_outtab       = gt_plant_row
        it_fieldcatalog = gt_fcat_plant.
    CALL METHOD go_alv_plant->set_ready_for_input
      EXPORTING
        i_ready_for_input = lv_input.
  ELSE.
    CALL METHOD go_alv_plant->set_ready_for_input
      EXPORTING
        i_ready_for_input = lv_input.
    CALL METHOD go_alv_plant->refresh_table_display.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_plant
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_plant .
  CLEAR gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname = 'ICON'.
  gw_fcat_plant-coltext   = '관리현황'.
  gw_fcat_plant-outputlen = 8.
  gw_fcat_plant-icon      = 'X'.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname = 'WERKS'.
  gw_fcat_plant-coltext   = '플랜트'.
  gw_fcat_plant-outputlen = 8.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname = 'NAME1'.
  gw_fcat_plant-coltext   = '플랜트명'.
  gw_fcat_plant-outputlen = 14.
*  gw_fcat_plant-no_out = 'X'.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname = 'BRNAME'.
  gw_fcat_plant-coltext   = '지사명'.
  gw_fcat_plant-outputlen = 10.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname  = 'EISBE'.
  gw_fcat_plant-coltext    = '안전재고'.
  gw_fcat_plant-outputlen  = 10.
  gw_fcat_plant-ref_table = 'Z8MATPLANT_M'.
  gw_fcat_plant-ref_field = 'EISBE'.
  gw_fcat_plant-qfieldname = 'MEINS'.
  gw_fcat_plant-no_zero    = 'X'.
  gw_fcat_plant-edit       = 'X'.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname  = 'MABST'.
  gw_fcat_plant-coltext    = '목표수량'.
  gw_fcat_plant-outputlen  = 10.
  gw_fcat_plant-ref_table  = 'Z8MATPLANT_M'.
  gw_fcat_plant-ref_field  = 'MABST'.
  gw_fcat_plant-qfieldname = 'MEINS'.
  gw_fcat_plant-no_zero    = 'X'.
  gw_fcat_plant-edit       = 'X'.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname = 'MEINS'.
  gw_fcat_plant-coltext   = '단위'.
  gw_fcat_plant-outputlen = 3.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname = 'EKGRP'.
  gw_fcat_plant-coltext   = '구매그룹'.
  gw_fcat_plant-outputlen = 8.
  gw_fcat_plant-edit       = 'X'.
  gw_fcat_plant-no_out = 'X'.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname = 'MMSTA'.
  gw_fcat_plant-coltext   = '상태코드'.
  gw_fcat_plant-outputlen = 6.
  gw_fcat_plant-edit       = 'X'.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname  = 'VERPR'.
  gw_fcat_plant-coltext    = '이동평균가'.
  gw_fcat_plant-outputlen  = 10.
  gw_fcat_plant-cfieldname = 'WAERS'.
  gw_fcat_plant-ref_table = 'Z8MATERIAL_VAL_M'.
  gw_fcat_plant-ref_field = 'VERPR'.
  gw_fcat_plant-no_zero    = 'X'.
  gw_fcat_plant-edit       = 'X'.
  gw_fcat_plant-decimals_o = 0.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname = 'PEINH'.
  gw_fcat_plant-coltext   = '가격단위'.
  gw_fcat_plant-outputlen = 8.
  gw_fcat_plant-no_zero   = 'X'.
  gw_fcat_plant-edit       = 'X'.
*    gw_fcat_plant-no_out = 'X'.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname = 'WAERS'.
  gw_fcat_plant-coltext   = '통화'.
  gw_fcat_plant-outputlen = 3.
  gw_fcat_plant-no_out = 'X'.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname  = 'LABST'.
  gw_fcat_plant-coltext    = '현재고'.
  gw_fcat_plant-outputlen  = 10.
  gw_fcat_plant-qfieldname = 'MEINS'.
  gw_fcat_plant-ref_table  = 'Z8MATERIAL_STK_M'.
  gw_fcat_plant-ref_field  = 'LABST'.
  gw_fcat_plant-no_zero    = 'X'.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname  = 'ZZRSVQTY'.
  gw_fcat_plant-coltext    = '예약재고'.
  gw_fcat_plant-outputlen = 10.
  gw_fcat_plant-qfieldname = 'MEINS'.
  gw_fcat_plant-ref_table  = 'Z8MATERIAL_STK_M'.
  gw_fcat_plant-ref_field  = 'ZZRSVQTY'.
  gw_fcat_plant-no_zero    = 'X'.
  APPEND gw_fcat_plant TO gt_fcat_plant.

  CLEAR gw_fcat_plant.
  gw_fcat_plant-fieldname  = 'AVAIL'.
  gw_fcat_plant-coltext    = '가용재고'.
  gw_fcat_plant-outputlen  = 10.
  gw_fcat_plant-qfieldname = 'MEINS'.
  APPEND gw_fcat_plant TO gt_fcat_plant.


ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_alv_plant
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_alv_plant .
  "화면떠날 때 정리.
  IF go_alv_plant IS NOT INITIAL.
    CALL METHOD go_alv_plant->free.
  ENDIF.
  IF go_cont_plant IS NOT INITIAL.
    CALL METHOD go_cont_plant->free.
  ENDIF.
  FREE: go_alv_plant, go_cont_plant.
  CLEAR: gt_plant_row, gt_plant, gt_val.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form build_plant_rows
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM build_plant_rows .
  CLEAR gt_plant_row.
  SELECT * FROM z8plant_m INTO TABLE gt_plantm.
  SORT gt_plantm BY werks.
  SELECT * FROM z8branch_m INTO TABLE gt_branch.

  LOOP AT gt_plantm INTO gw_plantm.
    CLEAR gw_plant_row.
    gw_plant_row-werks = gw_plantm-werks.
    gw_plant_row-name1 = gw_plantm-name1.
    gw_plant_row-icon  = icon_led_inactive. "관리정보가 있는지 모르는 상태,

    READ TABLE gt_branch INTO gw_branch
         WITH KEY branch = gw_plantm-bupla.
    IF sy-subrc = 0.
      gw_plant_row-brname = gw_branch-name.
    ENDIF.

    "플랜트별 관리정보 찾기
    READ TABLE gt_plant INTO gw_plant
         WITH KEY werks = gw_plantm-werks.
    IF sy-subrc = 0.
      gw_plant_row-exist_p = 'X'. "찾으면 표시 ->  DB에 있으니 업데이트.
      gw_plant_row-eisbe   = gw_plant-eisbe.
      gw_plant_row-mabst   = gw_plant-mabst.
      gw_plant_row-meins   = gw_plant-meins.
      gw_plant_row-ekgrp   = gw_plant-ekgrp.
      gw_plant_row-mmsta   = gw_plant-mmsta.

      "플랜트 정보 유무와 상태코드(01/99)에 따라 신호등
*      CASE gw_plant-mmsta.
*        WHEN '01'.  "플랜트 정보O, 상태코드: 01-> 관리중
*          gw_plant_row-icon = icon_led_green.
*        WHEN '99'. "플랜트 정보O, 상태코드: 99 -> 중단
*          gw_plant_row-icon = icon_led_red.
*        WHEN OTHERS. "플랜트 정보O, 다른 값 -> 확인필요.
*          gw_plant_row-icon = icon_led_yellow.
*      ENDCASE.
    ENDIF.
    "평가정보 찾기.
    READ TABLE gt_val INTO gw_val
       WITH KEY bwkey = gw_plantm-werks.
    IF sy-subrc = 0.
      gw_plant_row-exist_v = 'X'.
      gw_plant_row-verpr   = gw_val-verpr.
      gw_plant_row-peinh   = gw_val-peinh.
      gw_plant_row-waers   = gw_val-waers.
      gw_plant_row-lbkum   = gw_val-lbkum.
    ENDIF.
    "플랜트별 현재 재고.
    LOOP AT gt_stk INTO gw_stk WHERE werks = gw_plantm-werks.
      gw_plant_row-labst    = gw_plant_row-labst    + gw_stk-labst.
      gw_plant_row-zzrsvqty = gw_plant_row-zzrsvqty + gw_stk-zzrsvqty.
    ENDLOOP.
    " 가용재고 = 현재고 - 예약재고 - 안전재고           ← 여기
    gw_plant_row-avail = gw_plant_row-labst - gw_plant_row-zzrsvqty - gw_plant_row-eisbe.
    "자재 자체가 사용중단일시 모든 플랜트 빨간불.
    IF z8s_mat_detail-mstae = '99'.
      gw_plant_row-icon = icon_led_red.
    ENDIF.

    "단위가 비어 있는 줄 (회색불) 자재 기본단위로 채움
    IF gw_plant_row-meins IS INITIAL.
      gw_plant_row-meins = z8s_mat_detail-meins.
    ENDIF.

    IF gw_plant_row-waers IS INITIAL.
      gw_plant_row-waers = 'KRW'.
    ENDIF.

    " 신호등: 빨강 = 사용중단, 초록 = 정상, 노랑 = 입력 필요
    IF z8s_mat_detail-mstae = '99'
       OR ( gw_plant_row-exist_p = 'X' AND gw_plant_row-mmsta = '99' ).
      gw_plant_row-icon = icon_led_red.
    ELSEIF gw_plant_row-exist_p = 'X'
       AND gw_plant_row-exist_v = 'X'
       AND gw_plant_row-mmsta = '01'.
      gw_plant_row-icon = icon_led_green.
    ELSE.
      gw_plant_row-icon = icon_led_yellow.
    ENDIF.

    APPEND gw_plant_row TO gt_plant_row.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_plant_rows
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_plant_rows .
  gv_err = space.
  gv_count = 0.

  LOOP AT  gt_plant_row INTO gw_plant_row.
    gw_plant_row-new_p = space.

    "1. 새로 관리하려고 입력한 줄인지 판단
    gv_filled = space.
    IF gw_plant_row-exist_p = space.
      IF gv_mode = 'N'.
        " 신규 자재: 모든 자재는 4개 플랜트에 다 있어야 하므로 전부 새 줄
        gv_filled = 'X'.
      ELSEIF gw_plant_row-eisbe IS NOT INITIAL
          OR gw_plant_row-ekgrp IS NOT INITIAL
          OR gw_plant_row-mmsta IS NOT INITIAL.
        gv_filled = 'X'.
      ENDIF.
    ENDIF.

    "1-2. 새로 입력한 줄: 빠진 값은 기본값으로 채우고, 이동평균가 확인.
    IF  gv_filled = 'X'.
      gw_plant_row-new_p = 'X'.
      IF gw_plant_row-ekgrp IS INITIAL.
        gw_plant_row-ekgrp = '001'.
      ENDIF.
      IF gw_plant_row-mmsta IS INITIAL.
        gw_plant_row-mmsta = '01'.
      ENDIF.
      IF gw_plant_row-peinh IS INITIAL.
        gw_plant_row-peinh = 1.
      ENDIF.
      IF gw_plant_row-waers IS INITIAL.
        gw_plant_row-waers = 'KRW'.
      ENDIF.
      gw_plant_row-meins = z8s_mat_detail-meins.

      IF  gw_plant_row-exist_v = space AND gw_plant_row-verpr <= 0.
        CONCATENATE gw_plant_row-werks '플랜트:' '이동평균가를  입력하세요'
        INTO gv_msg SEPARATED BY space.
        MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'E'.
        gv_err = 'X'.
        RETURN.
      ENDIF.

      " 재고 자재는 목표수량 필수 (서비스 자재 제외)
      IF z8s_mat_detail-mtart <> 'SVC' AND gw_plant_row-mabst <= 0.
        CONCATENATE gw_plant_row-werks '플랜트:' '목표수량을 입력하세요'
          INTO gv_msg SEPARATED BY space.
        MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'E'.
        gv_err = 'X'.
        RETURN.
      ENDIF.
    ENDIF.

    " 안전재고는 목표수량보다 작아야 함
    IF ( gw_plant_row-exist_p = 'X' OR gv_filled = 'X' )
       AND gw_plant_row-mabst > 0
       AND gw_plant_row-eisbe >= gw_plant_row-mabst.
      CONCATENATE gw_plant_row-werks '플랜트:' '안전재고는 목표수량보다 작아야 합니다'
        INTO gv_msg SEPARATED BY space.
      MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'E'.
      gv_err = 'X'.
      RETURN.
    ENDIF.

    "2.; 재고가 있는 줄은 이동평균가/ 가격단위 못바꿈.
    IF  gw_plant_row-exist_v = 'X' AND gw_plant_row-lbkum > 0.
      READ TABLE gt_val INTO gw_val
        WITH KEY bwkey = gw_plant_row-werks.
      IF sy-subrc = 0.
        IF gw_plant_row-verpr <> gw_val-verpr
          OR gw_plant_row-peinh <> gw_val-peinh.
          CONCATENATE gw_plant_row-werks '플랜트:'
                    '재고가 있어 이동평균가를 수정할 수 없습니다'
               INTO gv_msg SEPARATED BY space.
          MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'E'.
          gv_err = 'X'.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.
    "3. 관리하는 줄 카운트
    IF gw_plant_row-exist_p = 'X' OR gv_filled = 'X'.
      gv_count = gv_count + 1.
    ENDIF.
    MODIFY gt_plant_row FROM gw_plant_row.
  ENDLOOP.
  "4. 최소 1줄은 있어야함.
  IF gv_count = 0.
    MESSAGE '플랜트별 관리정보를 1건 이상 입력하세요' TYPE 'S' DISPLAY LIKE 'E'.
    gv_err = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_plant_rows
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM save_plant_rows .
  DATA gs_stk_new TYPE z8material_stk_m.
  gv_err = space.
  "화면의 4개 줄을 하나씩.
  LOOP AT gt_plant_row INTO gw_plant_row.
    "새로 관리하는  시작하는 줄
    IF gw_plant_row-new_p = 'X'.
      CLEAR gw_plant.
      gw_plant-mandt = sy-mandt. "mandt,matnr,werks,lgort 값 채우기.
      gw_plant-matnr = z8s_mat_detail-matnr.
      gw_plant-werks = gw_plant_row-werks.
      gw_plant-lgort = '0001'.
      gw_plant-ekgrp = gw_plant_row-ekgrp. "화면에서 입력한 값
      gw_plant-eisbe = gw_plant_row-eisbe.
      gw_plant-beskz = 'F'.
      gw_plant-mmsta = gw_plant_row-mmsta.
      gw_plant-meins = z8s_mat_detail-meins.
      gw_plant-mabst = gw_plant_row-mabst.
      INSERT z8matplant_m FROM gw_plant.
      IF sy-subrc <> 0.
        gv_err = 'X'.
        RETURN.
      ENDIF.

      " ▼ 재고 0인 줄도 같이 만든다 (여기부터 추가)
      CLEAR gs_stk_new.
      gs_stk_new-mandt = sy-mandt.
      gs_stk_new-matnr = z8s_mat_detail-matnr.
      gs_stk_new-werks = gw_plant_row-werks.
      gs_stk_new-lgort = '0001'.
      gs_stk_new-meins = z8s_mat_detail-meins.
      INSERT z8material_stk_m FROM gs_stk_new.
      IF sy-subrc <> 0.
        gv_err = 'X'.
        RETURN.
      ENDIF.
      "원래 있던 줄'
    ELSEIF gw_plant_row-exist_p = 'X'.
      READ TABLE gt_plant INTO gw_plant
          WITH KEY werks = gw_plant_row-werks.
      IF sy-subrc = 0.
        gw_plant-eisbe = gw_plant_row-eisbe.
        gw_plant-ekgrp = gw_plant_row-ekgrp.
        gw_plant-mmsta = gw_plant_row-mmsta.
        gw_plant-mabst = gw_plant_row-mabst.
        UPDATE z8matplant_m FROM gw_plant.
        IF  sy-subrc <> 0.
          gv_err = 'X'.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_val_rows
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM save_val_rows .
  gv_err = space.

  LOOP AT gt_plant_row INTO gw_plant_row.
    "자재 평가 행이 이미 있는 줄.
    IF  gw_plant_row-exist_v = 'X'.
      READ TABLE gt_val INTO gw_val
           WITH KEY bwkey = gw_plant_row-werks.
      IF sy-subrc = 0.
        "화면값과 원래 값 비교.
        IF gw_plant_row-verpr <> gw_val-verpr
           OR gw_plant_row-peinh <> gw_val-peinh.    "  바뀐 경우만
          UPDATE z8material_val_m                         " verpr, peinh 두 칸만 지정해서 Update
             SET verpr = gw_plant_row-verpr
                 peinh = gw_plant_row-peinh
           WHERE matnr = z8s_mat_detail-matnr
             AND bwkey = gw_plant_row-werks.
          IF sy-subrc <> 0.
            gv_err = 'X'.
            RETURN.
          ENDIF.
        ENDIF.
      ENDIF.
      "평가 행이 없는데 이동평균가를 입력-> 새 평가 행.
    ELSEIF gw_plant_row-new_p = 'X' OR gw_plant_row-exist_p = 'X'.      " verpr > 0 조건 삭제
      IF gw_plant_row-new_p = 'X' OR gw_plant_row-exist_p = 'X'.
        CLEAR gw_val.
        gw_val-mandt   = sy-mandt.
        gw_val-matnr   = z8s_mat_detail-matnr.
        gw_val-bwkey   = gw_plant_row-werks.
        gw_val-vprsv   = 'V'.
        gw_val-verpr   = gw_plant_row-verpr.
        IF gw_plant_row-peinh IS INITIAL.
          gw_val-peinh = 1.
        ELSE.
          gw_val-peinh = gw_plant_row-peinh.
        ENDIF.
        gw_val-waers   = 'KRW'.
        gw_val-meins   = z8s_mat_detail-meins.
        gw_val-zzdrcls = gv_drcls.
        INSERT z8material_val_m FROM gw_val.
        IF sy-subrc <> 0.
          gv_err = 'X'.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_event_handler_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_event_handler_200 .
  SET HANDLER:  lc1_handler=>on_doubleclick_200 FOR go_alv_200,
                          lc1_handler=>on_hotspot_click_200 FOR go_alv_200.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_vendor
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM save_vendor .
  DATA: gw_vend   TYPE z8vendor_m,
        lv_cnt    TYPE i,
        lv_len    TYPE i,
        lv_biz    TYPE z8vendor_m-stcd2,
        lv_region TYPE z8vendor_m-region_code,
        lv_text   TYPE c LENGTH 60,
        lv_ans    TYPE c LENGTH 1.

  TRANSLATE z8s_vend_detail-lifnr TO UPPER CASE.

  " 1,. 필수값
  IF z8s_vend_detail-lifnr IS INITIAL.
    MESSAGE '업체코드를 입력하세요' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  IF z8s_vend_detail-name1 IS INITIAL.
    MESSAGE '업체명을 입력하세요' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  IF z8s_vend_detail-stcd2 IS INITIAL.
    MESSAGE '사업자등록번호를 입력하세요' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  IF z8s_vend_detail-land1 IS INITIAL.
    MESSAGE '국가를 입력하세요' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.
  IF z8s_vend_detail-region_code IS INITIAL.
    MESSAGE '권역을 입력하세요' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.

  " 2. 신규면 업체코드 중복 확인
  IF gv_mode_v = 'N'.
    SELECT COUNT(*) FROM z8vendor_m
      INTO lv_cnt
      WHERE lifnr = z8s_vend_detail-lifnr.
    IF lv_cnt > 0.
      MESSAGE '이미 등록된 업체코드입니다' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
  ENDIF.

  " 3. 사업자번호: 하이픈 없이 숫자 10자리만 허용
  lv_len = strlen( z8s_vend_detail-stcd2 ).
  IF lv_len <> 10 OR z8s_vend_detail-stcd2(10) CN '0123456789'.
    MESSAGE '사업자등록번호는 숫자 10자리로만  입력하세요'  TYPE 'S' DISPLAY LIKE 'E'.
    RETURN.
  ENDIF.

  " 4.  권역이 실제로 있는지
  SELECT SINGLE region_code FROM z8region_m
    INTO lv_region
    WHERE region_code = z8s_vend_detail-region_code.
  IF sy-subrc <> 0.
    MESSAGE '존재하지 않는 권역입니다' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.

  PERFORM check_vmat_rows.             "검증
  IF gv_err = 'X'.
    RETURN.
  ENDIF.

  " 5. 확인 팝업
  IF gv_mode_v = 'N'.
    lv_text = '신규 공급업체를 등록하시겠습니까?'.
  ELSE.
    lv_text = '수정 내용을 저장하시겠습니까?'.
  ENDIF.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question = lv_text
    IMPORTING
      answer        = lv_ans.
  IF lv_ans <> '1'.
    RETURN.
  ENDIF.

  " 6. 저장
  CLEAR gw_vend.
  IF gv_mode_v <> 'N'.
    " 수정: 기존 행을 먼저 읽어서, 화면에 없는 칸이 지워지지 않게 한다
    SELECT SINGLE * FROM z8vendor_m
      WHERE lifnr = @z8s_vend_detail-lifnr
      INTO @gw_vend.
    IF sy-subrc <> 0.
      MESSAGE '공급업체를 찾을 수 없습니다' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
    ENDIF.
  ENDIF.
  MOVE-CORRESPONDING z8s_vend_detail TO gw_vend.
  gw_vend-mandt = sy-mandt.

  IF gv_mode_v = 'N'.
    INSERT z8vendor_m FROM gw_vend.
  ELSE.
    UPDATE z8vendor_m FROM gw_vend.
  ENDIF.
  IF sy-subrc <> 0.
    ROLLBACK WORK.
    MESSAGE '저장 중 오류가 발생했습니다' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.

  PERFORM save_vmat_rows.              " 신규업체  저장
  IF gv_err = 'X'.
    ROLLBACK WORK.
    MESSAGE '저장 중 오류가 발생했습니다' TYPE 'S' DISPLAY LIKE 'E'. RETURN.
  ENDIF.

  COMMIT WORK.
  MESSAGE '저장되었습니다' TYPE 'S'.

  CLEAR gv_screen_init_v.
  PERFORM unlock_vendor.
  PERFORM free_alv_vmat.
  LEAVE TO SCREEN 0.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form build_vmat_rows
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM build_vmat_rows .
  CLEAR gt_vmat_row.

  " 1. 자재 읽기
  SELECT * FROM z8material_m INTO TABLE gt_vm_mat WHERE mstae <> '99'.
  SORT gt_vm_mat BY matnr.

  IF gt_vm_mat IS NOT INITIAL.
    SELECT * FROM z8material_txt_m INTO TABLE gt_vm_txt
      FOR ALL ENTRIES IN gt_vm_mat
      WHERE matnr = gt_vm_mat-matnr
        AND spras = '3'.
    SELECT * FROM z8purch_info_m INTO TABLE gt_vm_info
      FOR ALL ENTRIES IN gt_vm_mat
      WHERE matnr = gt_vm_mat-matnr.
  ENDIF.
*  SELECT * FROM z8vendor_m INTO TABLE gt_vm_vend.

  " 2. 자재마다 한 줄씩 만들기
  LOOP AT gt_vm_mat INTO gw_vm_mat.
    CLEAR gw_vmat_row.
    gw_vmat_row-matnr = gw_vm_mat-matnr.
    gw_vmat_row-meins = gw_vm_mat-meins.
    gw_vmat_row-icon  = icon_led_inactive.

    READ TABLE gt_vm_txt INTO gw_vm_txt
         WITH KEY matnr = gw_vm_mat-matnr.
    IF sy-subrc = 0.
      gw_vmat_row-maktx = gw_vm_txt-maktx.
    ENDIF.

    " 3. 이 업체의 구매정보가 있으면 값을 채움 (자재+업체)
    READ TABLE gt_vm_info INTO gw_vm_info
         WITH KEY matnr = gw_vm_mat-matnr
                  lifnr = gv_lifnr_sel.
    IF sy-subrc = 0.
      gw_vmat_row-exist_i = 'X'.
      gw_vmat_row-meins   = gw_vm_info-meins.
      gw_vmat_row-netpr   = gw_vm_info-netpr.
      gw_vmat_row-peinh   = gw_vm_info-peinh.
      gw_vmat_row-waers   = gw_vm_info-waers.
      gw_vmat_row-minbm   = gw_vm_info-minbm.
      gw_vmat_row-icon    = icon_led_green.
    ELSE.
      " 4. 없으면 다른 업체가 취급하는지 확인
*      LOOP AT gt_vm_info INTO gw_vm_info
*           WHERE matnr = gw_vm_mat-matnr
*             AND lifnr <> gv_lifnr_sel.
*        gw_vmat_row-locked      = 'X'.
*        gw_vmat_row-other_lifnr = gw_vm_info-lifnr.
*        gw_vmat_row-icon        = icon_locked.
*        READ TABLE gt_vm_vend INTO gw_vm_vend
*             WITH KEY lifnr = gw_vm_info-lifnr.
*        IF sy-subrc = 0.
*          gw_vmat_row-other_name = gw_vm_vend-name1.
*        ENDIF.
*        EXIT.
*      ENDLOOP.
    ENDIF.

    gw_vmat_row-vcnt = 0.
    LOOP AT gt_vm_info INTO gw_vm_cnt WHERE matnr = gw_vm_mat-matnr.
      gw_vmat_row-vcnt = gw_vmat_row-vcnt + 1.
    ENDLOOP.
    "모든 통화칸에 krw.
    IF gw_vmat_row-waers IS INITIAL.
      gw_vmat_row-waers = 'KRW'.
    ENDIF.

    APPEND gw_vmat_row TO gt_vmat_row.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_field_catalog_vmat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_field_catalog_vmat .
  CLEAR gt_fcat_vmat.

  CLEAR gw_fcat_vmat.
  gw_fcat_vmat-fieldname = 'ICON'.
  gw_fcat_vmat-coltext   = '상태'.
  gw_fcat_vmat-outputlen = 4.
  gw_fcat_vmat-icon      = 'X'.
  APPEND gw_fcat_vmat TO gt_fcat_vmat.

  CLEAR gw_fcat_vmat.
  gw_fcat_vmat-fieldname = 'MATNR'.
  gw_fcat_vmat-coltext   = '자재코드'.
  gw_fcat_vmat-outputlen = 14.
  APPEND gw_fcat_vmat TO gt_fcat_vmat.

  CLEAR gw_fcat_vmat.
  gw_fcat_vmat-fieldname = 'MAKTX'.
  gw_fcat_vmat-coltext   = '자재명'.
  gw_fcat_vmat-outputlen = 24.
  APPEND gw_fcat_vmat TO gt_fcat_vmat.

  CLEAR gw_fcat_vmat.
  gw_fcat_vmat-fieldname  = 'NETPR'.
  gw_fcat_vmat-coltext    = '순단가'.
  gw_fcat_vmat-outputlen  = 14.
  gw_fcat_vmat-cfieldname = 'WAERS'.
  gw_fcat_vmat-ref_table  = 'Z8PURCH_INFO_M'.
  gw_fcat_vmat-ref_field  = 'NETPR'.
  gw_fcat_vmat-no_zero    = 'X'.
  gw_fcat_vmat-edit       = 'X'.
  APPEND gw_fcat_vmat TO gt_fcat_vmat.

  CLEAR gw_fcat_vmat.
  gw_fcat_vmat-fieldname = 'PEINH'.
  gw_fcat_vmat-coltext   = '가격단위'.
  gw_fcat_vmat-outputlen = 8.
  gw_fcat_vmat-no_zero   = 'X'.
  gw_fcat_vmat-edit       = 'X'.
  APPEND gw_fcat_vmat TO gt_fcat_vmat.

  CLEAR gw_fcat_vmat.
  gw_fcat_vmat-fieldname  = 'MINBM'.
  gw_fcat_vmat-coltext    = '최소구매수량'.
  gw_fcat_vmat-outputlen  = 12.
  gw_fcat_vmat-qfieldname = 'MEINS'.
  gw_fcat_vmat-ref_table  = 'Z8PURCH_INFO_M'.
  gw_fcat_vmat-ref_field  = 'MINBM'.
  gw_fcat_vmat-no_zero    = 'X'.
  gw_fcat_vmat-edit       = 'X'.
  APPEND gw_fcat_vmat TO gt_fcat_vmat.

  CLEAR gw_fcat_vmat.
  gw_fcat_vmat-fieldname = 'MEINS'.
  gw_fcat_vmat-coltext   = '단위'.
  gw_fcat_vmat-outputlen = 6.
  APPEND gw_fcat_vmat TO gt_fcat_vmat.

  CLEAR gw_fcat_vmat.
  gw_fcat_vmat-fieldname = 'WAERS'.
  gw_fcat_vmat-coltext   = '통화'.
  gw_fcat_vmat-outputlen = 6.
  APPEND gw_fcat_vmat TO gt_fcat_vmat.

  CLEAR gw_fcat_vmat.
  gw_fcat_vmat-fieldname = 'VCNT'.
  gw_fcat_vmat-coltext   = '취급 업체 수'..
  gw_fcat_vmat-outputlen = 10.
  APPEND gw_fcat_vmat TO gt_fcat_vmat.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form free_alv_vmat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM free_alv_vmat .
  IF go_alv_vmat IS NOT INITIAL.
    CALL METHOD go_alv_vmat->free.
  ENDIF.
  IF go_cont_vmat IS NOT INITIAL.
    CALL METHOD go_cont_vmat->free.
  ENDIF.
  FREE: go_alv_vmat, go_cont_vmat.
  CLEAR gt_vmat_row.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form check_vmat_rows
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM check_vmat_rows .
  gv_err   = space.
  gv_count = 0.

  LOOP AT gt_vmat_row INTO gw_vmat_row.

    gw_vmat_row-new_i = space.                 " 이전 시도의 표식을 먼저 지움
    gw_vmat_row-del_i = space.

        IF gw_vmat_row-exist_i = 'X'.
      " 1. 이 업체가 이미 취급하던 줄
      IF gw_vmat_row-netpr <= 0.
        gw_vmat_row-del_i = 'X'.               " 단가를 비움 = 취급 해제

        " 1-1. 마지막 공급업체는 해제 불가 (배치가 업체를 못 골라 PR을 못 만듦)
        IF gw_vmat_row-vcnt <= 1.
          CONCATENATE gw_vmat_row-matnr '마지막 공급업체라 취급 해제할 수 없습니다'
                 INTO gv_msg SEPARATED BY space.
          MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'E'.
          gv_err = 'X'.
          RETURN.
        ENDIF.

        " 1-2. 이 업체로 발주 대기 중인 PR이 있으면 해제 불가 (PO 생성 실패)
        SELECT SINGLE banfn FROM z8mm_pr
          WHERE matnr = @gw_vmat_row-matnr
            AND lifnr = @z8s_vend_detail-lifnr
            AND ebeln = @space
            AND loekz = @space
          INTO @DATA(lv_open_pr).
        IF sy-subrc = 0.
          CONCATENATE gw_vmat_row-matnr '발주 대기 PR' lv_open_pr '이(가) 있어 취급 해제할 수 없습니다'
                 INTO gv_msg SEPARATED BY space.
          MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'E'.
          gv_err = 'X'.
          RETURN.
        ENDIF.

      ELSE.
        IF gw_vmat_row-peinh IS INITIAL.
          gw_vmat_row-peinh = 1.
        ENDIF.
        IF gw_vmat_row-minbm <= 0.
          CONCATENATE gw_vmat_row-matnr '최소구매수량을 입력하세요'
                 INTO gv_msg SEPARATED BY space.
          MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'E'.
          gv_err = 'X'.
          RETURN.
        ENDIF.
        gv_count = gv_count + 1.
      ENDIF.

*    ELSEIF gw_vmat_row-locked = 'X'.
*      " 2. 다른 업체가 취급 중인 줄: 입력하면 오류
*      IF gw_vmat_row-netpr IS NOT INITIAL
*         OR gw_vmat_row-peinh IS NOT INITIAL
*         OR gw_vmat_row-minbm IS NOT INITIAL.
*        CONCATENATE gw_vmat_row-matnr '은(는)' gw_vmat_row-other_name
*                    '이(가) 이미 취급 중입니다'
*               INTO gv_msg SEPARATED BY space.
*        MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'E'.
*        gv_err = 'X'.
*        RETURN.
*      ENDIF.

    ELSEIF gw_vmat_row-netpr > 0.

      IF gw_vmat_row-peinh IS INITIAL.
        gw_vmat_row-peinh = 1.
      ENDIF.
      IF gw_vmat_row-minbm <= 0.
        gw_vmat_row-minbm = 1.
      ENDIF.
      gw_vmat_row-new_i = 'X'.
      gv_count = gv_count + 1.

    ELSEIF gw_vmat_row-peinh IS NOT INITIAL
        OR gw_vmat_row-minbm IS NOT INITIAL.
      " 4. 순단가 없이 다른 칸만 입력
      CONCATENATE gw_vmat_row-matnr '순단가를 입력하세요'
             INTO gv_msg SEPARATED BY space.
      MESSAGE gv_msg TYPE 'S' DISPLAY LIKE 'E'.
      gv_err = 'X'.
      RETURN.
    ENDIF.

    MODIFY gt_vmat_row FROM gw_vmat_row.
  ENDLOOP.

  " 5. 저장 후 최소 1건은 남아야 함
  IF gv_count = 0.
    MESSAGE '취급자재를 1건 이상 등록하세요' TYPE 'S' DISPLAY LIKE 'E'.
    gv_err = 'X'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form save_vmat_rows
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM save_vmat_rows .
  gv_err = space.

  LOOP AT gt_vmat_row INTO gw_vmat_row.

    IF gw_vmat_row-new_i = 'X'.
      " 새로 취급 시작: INSERT
      CLEAR gw_vm_info.
      gw_vm_info-mandt = sy-mandt.
      gw_vm_info-matnr = gw_vmat_row-matnr.
      gw_vm_info-lifnr = z8s_vend_detail-lifnr.
      gw_vm_info-meins = gw_vmat_row-meins.
      gw_vm_info-netpr = gw_vmat_row-netpr.
      gw_vm_info-peinh = gw_vmat_row-peinh.
      gw_vm_info-waers = 'KRW'.
      gw_vm_info-minbm = gw_vmat_row-minbm.
      INSERT z8purch_info_m FROM gw_vm_info.
      IF sy-subrc <> 0.
        gv_err = 'X'.
        RETURN.
      ENDIF.

    ELSEIF gw_vmat_row-del_i = 'X'.

      " 취급 해제: DELETE
      DELETE FROM z8purch_info_m
        WHERE matnr = gw_vmat_row-matnr
          AND lifnr = z8s_vend_detail-lifnr.
      IF sy-subrc <> 0.
        gv_err = 'X'.
        RETURN.
      ENDIF.

    ELSEIF gw_vmat_row-exist_i = 'X'.
      " 원래 있던 줄: 바뀐 경우만 UPDATE
      READ TABLE gt_vm_info INTO gw_vm_info
           WITH KEY matnr = gw_vmat_row-matnr
                    lifnr = z8s_vend_detail-lifnr.
      IF sy-subrc = 0.
        IF gw_vmat_row-netpr <> gw_vm_info-netpr
           OR gw_vmat_row-peinh <> gw_vm_info-peinh
           OR gw_vmat_row-minbm <> gw_vm_info-minbm.
          UPDATE z8purch_info_m
             SET netpr = gw_vmat_row-netpr
                 peinh = gw_vmat_row-peinh
                 minbm = gw_vmat_row-minbm
           WHERE matnr = gw_vmat_row-matnr
             AND lifnr = z8s_vend_detail-lifnr.
          IF sy-subrc <> 0.
            gv_err = 'X'.
            RETURN.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form set_alv_layout_200
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM set_alv_layout_200 .
  gs_layout_200-grid_title = |공급업체 목록 ({ lines( gt_vend_list ) }건)|.
  gs_layout_200-no_toolbar = 'X'.
  gs_layout_200-zebra      = 'X'.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form unlock_material
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM unlock_material .
  IF gv_locked = 'X'.
    CALL FUNCTION 'DEQUEUE_EZ8MATERIAL'
      EXPORTING
        matnr = z8s_mat_detail-matnr.
    CLEAR gv_locked.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form unlock_vendor
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM unlock_vendor .
  IF gv_locked_v = 'X'.
    CALL FUNCTION 'DEQUEUE_EZ8VENDOR'
      EXPORTING
        lifnr = z8s_vend_detail-lifnr.
    CLEAR gv_locked_v.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form mstae_to_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM mstae_to_text .
  CASE gv_cd.
    WHEN '01'.
      gv_tx = '사용중'.
    WHEN '99'.
      gv_tx = '사용중단'.
    WHEN OTHERS.
      gv_tx = gv_cd.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form mtart_to_text
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM mtart_to_text .
  CASE gv_cd.
    WHEN 'MOD'.
      gv_tx = '모듈'.
    WHEN 'INV'.
      gv_tx = '인버터'.
    WHEN 'ESS'.
      gv_tx = '배터리'.
    WHEN 'CBL'.
      gv_tx = '케이블'.
    WHEN 'STR'.
      gv_tx = '구조물'.
    WHEN 'ELE'.
      gv_tx = '접속반'.
    WHEN OTHERS.
      gv_tx = gv_cd.
  ENDCASE.

ENDFORM.
