*&---------------------------------------------------------------------*
*& Include          Z8COSD100CS2
*&---------------------------------------------------------------------*

*CLASS lcl_event_receiver DEFINITION.
*  PUBLIC SECTION.
*    METHODS handle_hotspot_click
*      FOR EVENT hotspot_click OF cl_gui_alv_grid
*      IMPORTING e_row_id e_column_id sender. " sender는 클릭된 ALV 객체를 의미함
*ENDCLASS.
*
*CLASS lcl_event_receiver IMPLEMENTATION.
*  METHOD handle_hotspot_click.
*
*    " 1. 어느 ALV(탭)에서 클릭이 발생했는지 확인
*    IF sender = go_alv_rej.
*      " [사유별 ALV]에서 클릭된 경우
*
*      " 해당 사유 코드로 하단 데이터를 새롭게 SELECT
*
*
*    ELSEIF sender = go_alv_bup.
*      " [지사별 ALV]에서 클릭된 경우
*
*      " 해당 지사 코드로 하단 데이터를 새롭게 SELECT
*
*    ENDIF.
*
*    " 2. 새롭게 채워진 하단 데이터(gt_bot)로 하단 ALV 새로고침
*
*  ENDMETHOD.
*ENDCLASS.
