*&---------------------------------------------------------------------*
*& Include          ZMMGR030I01
*&---------------------------------------------------------------------*


MODULE user_command_0100 INPUT.
  DATA:
    lv_inv_no  TYPE z8mm_inv_h-inv_no,
    lt_rows    TYPE lvc_t_row,
    ls_row     TYPE lvc_s_row,
    lv_ebelp   TYPE z8mm_po_i-ebelp,
    lv_ref_doc TYPE z8mm_inv_h-zzrefdoc,
    lv_ret     TYPE c.

  CASE ok_code.

    WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
      PERFORM unlock_po.
      "CALL FUNCTION 'DEQUEUE_ALL'.
      LEAVE TO SCREEN 0.


    WHEN 'LOAD'.
      PERFORM has_inv USING gv_invno.
      IF gv_invno IS NOT INITIAL.
        MESSAGE s202(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.
      CLEAR gv_invno.

      " 2. XML 파일 업로드 및 구조체(gs_xml_doc) 변환
      PERFORM upload_and_parse_xml.

      " 3. 파싱 데이터를 인터널 테이블(gt_inv_i, gs_inv_h)에 매핑 (DB 저장 X)
      PERFORM map_xml_to_itab.

      " =================================================================
      " [신규] 4. ALV에 띄우기 전 백그라운드에서 3-Way 매칭 사전 검증
      " =================================================================
      " 백그라운드로 3-way 매칭 데이터를 집계 (gv_3cof 등 전역 플래그 세팅됨)
      PERFORM get_data.

      " ★ 발주-입고 불일치는 무시하고, '청구 데이터 자체'가 불일치할 때만 화면에서 튕겨냄
      IF gv_inv_err = 'X'.
        " 1) 메시지 출력
        MESSAGE s222(z8_msg) WITH |{ gv_ebeln }| DISPLAY LIKE 'E'.

        " 2) 메모리에 올렸던 청구서 데이터 날리기 (화면에 안 보이게 함)
        CLEAR: gs_inv_h, gt_inv_i, gs_inv_i, gs_xml_doc.

        " 3) 청구서가 빈 상태로 ALV를 다시 그리도록 집계 함수 재호출
        PERFORM get_data.
        go_amnt_alv->refresh_table_display( ).
        go_qunt_alv->refresh_table_display( ).

        RETURN. " 이후 로직 중단
      ENDIF.

      " 5. 검증을 통과했을 경우 정상적으로 ALV 갱신
      go_amnt_alv->refresh_table_display( ).
      go_qunt_alv->refresh_table_display( ).

      " 매칭 검증 통과한 후 성공 알림
      MESSAGE S219(z8_msg).
      "MESSAGE S219(z8_msg).


    WHEN 'CONF'.
      IF gt_inv_i[] IS INITIAL.
        MESSAGE s223(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      " 1) 최신 DB 기준으로 3-Way 재검증 (PO 락을 보유 중이라 PO/입고는 바뀌지 않음)
      CLEAR: gv_wrbtr_un, gv_menge_un.
      PERFORM get_data.
      IF gv_wrbtr_un = 'X' OR gv_menge_un = 'X'.
        MESSAGE s069(z8_msg) DISPLAY LIKE 'E'.
        RETURN.
      ENDIF.

      " 2) 확인 팝업
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          text_question         = '채무를 확정하고 청구서를 저장하시겠습니까?'
          text_button_1         = '예'
          text_button_2         = '아니오'
          display_cancel_button = ''
        IMPORTING
          answer                = lv_ret.
      IF lv_ret <> '1'.
        RETURN.
      ENDIF.

      " 3) 락 보유 확인 (정상 흐름에서는 화면 진입 시 이미 획득)
      IF gv_po_locked IS INITIAL.
        PERFORM lock_po USING gv_ebeln CHANGING gv_lock_rc gv_lock_user.
        IF gv_lock_rc <> 0.
          MESSAGE s055(z8_msg) WITH gv_lock_user DISPLAY LIKE 'E'.
          RETURN.
        ENDIF.
      ENDIF.

      " 4) 락 이후 상태 재확인
      PERFORM check_po_state USING gv_ebeln CHANGING gv_state_ok.
      IF gv_state_ok IS INITIAL.
        PERFORM unlock_po.
        LEAVE TO SCREEN 0.
      ENDIF.

      " 5) 저장 (한 LUW)
      PERFORM save_invoice_and_posting.
      IF gv_save_err = 'X'.
        ROLLBACK WORK.
        PERFORM unlock_po.
        MESSAGE i054(z8_msg).
        RETURN.
      ENDIF.

      COMMIT WORK AND WAIT.
      PERFORM unlock_po.
      MESSAGE i218(z8_msg) WITH gv_ebeln.
      LEAVE PROGRAM.
*      " 0. 비교할 청구서가 있는지 '인터널 테이블(메모리)' 기준으로 확인
*      IF gt_inv_i[] IS INITIAL.
*        MESSAGE S223(z8_msg) DISPLAY LIKE 'E'. " 비교할 청구서가 없습니다.
*        RETURN.
*      ENDIF.
*
*      CLEAR : gv_wrbtr_un, gv_menge_un.
*
*      " (기존 로직 유지) ALV 리프레시 불필요 시 주석 처리 무방
*      PERFORM get_data.
*
*      " 1. 청구서와의 내역이 같지 않으면 돌아감 (3-Way Matching 체크)
*      IF gv_wrbtr_un = 'X' OR gv_menge_un = 'X'.
*        MESSAGE s069(z8_msg) DISPLAY LIKE 'E'.
*        RETURN.
*      ENDIF.
*
*      CALL FUNCTION 'POPUP_TO_CONFIRM'
*        EXPORTING
*          text_question         = '채무를 확정하고 청구서를 저장하시겠습니까?'
*          text_button_1         = '예'
*          text_button_2         = '아니오'
*          display_cancel_button = ''
*        IMPORTING
*          answer                = lv_ret.
*      IF sy-subrc <> 0. MESSAGE s203(z8_msg) WITH |채무 확정|. RETURN. ENDIF.
*
*      " 2. 채무 확정 및 DB 저장
*      IF lv_ret = '1'.
*
*        " =================================================================
*        " [신규] 확정 순간에 청구서 실제 번호를 채번하여 메모리에 덮어씌움
*        " =================================================================
*        PERFORM get_invno CHANGING lv_inv_no.
*        IF sy-subrc <> 0.
*          MESSAGE s081(z8_msg) WITH |청구서 번호| DISPLAY LIKE 'E'.
*          RETURN.
*        ENDIF.
*        DATA(lv_real_invno) = |IV{ lv_inv_no }|. " 번호 조립 (예: IV0000001)
*
*        " 헤더와 아이템 인터널 테이블의 임시 번호를 실제 번호로 교체
*        gs_inv_h-inv_no = lv_real_invno.
*
*        LOOP AT gt_inv_i ASSIGNING FIELD-SYMBOL(<fs_inv_i>).
*          <fs_inv_i>-inv_no = lv_real_invno.
*        ENDLOOP.
*
*        " =================================================================
*        " 락(Lock) 설정 (기존과 동일)
*        " =================================================================
*        PERFORM get_accdoc_h_no CHANGING gv_belnr.
*
*        PERFORM lock_accdoc_h USING gv_belnr.
*        IF sy-subrc <> 0. MESSAGE i055(z8_msg). RETURN. ENDIF.
*
*        PERFORM lock_accdoc_i USING gv_belnr.
*        IF sy-subrc <> 0. MESSAGE i055(z8_msg). RETURN. ENDIF.
*
*        PERFORM lock_po_h USING gv_ebeln.
*        IF sy-subrc <> 0. MESSAGE i055(z8_msg). CALL FUNCTION 'DEQUEUE_ALL'. RETURN. ENDIF.
*
*        PERFORM lock_fi_vendor USING gv_belnr.
*        IF sy-subrc <> 0. MESSAGE i055(z8_msg). CALL FUNCTION 'DEQUEUE_ALL'. RETURN. ENDIF.
*
*        " =================================================================
*        " [신규] 청구서를 실제 DB(INV_H, INV_I)에 먼저 저장(INSERT)
*        " =================================================================
*        INSERT z8mm_inv_h FROM gs_inv_h.
*        IF sy-subrc <> 0.
*          MESSAGE '청구서 헤더 저장에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
*          CALL FUNCTION 'DEQUEUE_ALL'.
*          RETURN.
*        ENDIF.
*
*        INSERT z8mm_inv_i FROM TABLE gt_inv_i.
*        IF sy-subrc <> 0.
*          MESSAGE '청구서 품목 저장에 실패했습니다.' TYPE 'S' DISPLAY LIKE 'E'.
*          CALL FUNCTION 'DEQUEUE_ALL'.
*          RETURN.
*        ENDIF.
*
*        " =================================================================
*        " 회계전표, 구매오더 등 후속 업데이트 (기존과 동일)
*        " =================================================================
*        PERFORM create_accdoc_h USING gv_belnr.
*        PERFORM create_accdoc_i USING lv_real_invno. " 발급한 실제 청구서 번호 전달
*        PERFORM change_poh_invh.
*        "PERFORM update_po_hist. " 구매이력에 송장 번호 추가
*        PERFORM create_vendor.
*
*        " 실행 및 커밋
*        COMMIT WORK AND WAIT.
*        IF sy-subrc = 0.
*          CALL FUNCTION 'DEQUEUE_ALL'.
*          "MESSAGE i053(z8_msg).
*          MESSAGE I218(z8_msg) with |{ gv_ebeln }|.
*        ELSE.
*          ROLLBACK WORK.
*          CALL FUNCTION 'DEQUEUE_ALL'.
*          MESSAGE i054(z8_msg).
*        ENDIF.
*
*        LEAVE PROGRAM.
*      ENDIF.

      WHEN OTHERS.
  ENDCASE.
ENDMODULE.
