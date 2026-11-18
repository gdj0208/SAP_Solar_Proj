*&---------------------------------------------------------------------*
*& Include          ZMMGR030I01
*&---------------------------------------------------------------------*


MODULE user_command_0100 INPUT.
  DATA: lt_rows  TYPE lvc_t_row,
        ls_row   TYPE lvc_s_row,
        lv_ebelp TYPE z8mm_po_i-ebelp,
        lv_ebeln TYPE z8mm_po_i-ebeln.

  CASE ok_code.

    WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
      LEAVE PROGRAM.


    WHEN 'SELE'.
      " 0. 선택한 데이터 가져오기
      CALL METHOD go_alv->get_selected_rows
        IMPORTING
          et_index_rows = lt_rows.

      IF lt_rows IS INITIAL.
        MESSAGE s051(z8_msg) DISPLAY LIKE 'E'. RETURN.
      ELSE.

        READ TABLE lt_rows INTO ls_row INDEX 1.
        IF sy-subrc <> 0. MESSAGE s022(z8_msg) DISPLAY LIKE 'E'. RETURN. ENDIF.


        " 1. 해당 po의 번호와 아이템 번호 가져오기
        READ TABLE gt_unb_inv INTO gs_unb_inv  INDEX ls_row-index.
        SELECT SINGLE ebelp ebeln
          INTO (lv_ebelp, lv_ebeln) " 또는 공백 구분: INTO (lv_ebelp lv_ebeln)
          FROM z8mm_po_i
         WHERE ebeln = gs_unb_inv-ebeln.

        " 2. 청구서 요부 확인
        PERFORM has_inv CHANGING gv_invno lv_ebeln .
        IF gv_invno IS NOT INITIAL.
          MESSAGE s207(z8_msg) DISPLAY LIKE 'E' WITH |{ lv_ebeln }|. "|데이터가 이미 불러와져있습니다| TYPE 'S' DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.
        CLEAR gv_invno.


        " 2. 청구서 정보 가져오기
        SET PARAMETER ID 'WERKS' FIELD gv_werks.
        SET PARAMETER ID 'EBELP' FIELD lv_ebelp.
        SET PARAMETER ID 'EBELN' FIELD lv_ebeln.
        CALL TRANSACTION 'ZMMIP120'." and skip FIRST SCREEN.

        CLEAR gv_invno.
        PERFORM has_inv CHANGING gv_invno lv_ebeln.
        IF gv_invno IS NOT INITIAL.
          gv_done_ebeln = lv_ebeln.
        ENDIF.
        CLEAR gv_invno.

        PERFORM get_data.
        go_alv->refresh_table_display( ).
      ENDIF.

    WHEN 'RFSH'.
      " 1. 기존 데이터 초기화 (현재 ALV에 바인딩된 인터널 테이블)
      CLEAR gt_unb_inv[].

      " 2. 최신 데이터 다시 불러오기
      PERFORM get_data.

      " 3. ALV 그리드에 갱신된 데이터 반영
      IF go_alv IS NOT INITIAL.
        go_alv->refresh_table_display( ).
      ENDIF.

      MESSAGE '데이터가 새로고침 되었습니다.' TYPE 'S'.
  ENDCASE.
ENDMODULE.
