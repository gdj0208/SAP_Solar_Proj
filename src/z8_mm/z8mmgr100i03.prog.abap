*&---------------------------------------------------------------------*
*& Include          Z8MMGR100I03
*&---------------------------------------------------------------------*

MODULE user_command_0300 INPUT.

  save_ok = ok_code.
  CLEAR ok_code.
  CASE save_ok.

    WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
      "CALL FUNCTION 'DEQUEUE_ALL'.
      LEAVE TO SCREEN 0.

    WHEN 'INVO'.
      DATA :
        accdoc_h_no  TYPE z8fi_accdoc_h-belnr,
        lv_lock_fail TYPE c LENGTH 1,
        lt_done_po   TYPE SORTED TABLE OF z8mm_po_h-ebeln
                     WITH UNIQUE KEY table_line,
        lv_done_po   TYPE z8mm_po_h-ebeln,
        lv_first_po  TYPE z8mm_po_h-ebeln,
        lv_etc_cnt   TYPE i.

      " 0. 초기화
      PERFORM init_invo.

      " 1. LOCK 걸기
      PERFORM lock_stk_val CHANGING lv_lock_fail.
      IF lv_lock_fail = 'X'. RETURN. ENDIF.

      " 2~6. 단계별 실행 : 하나라도 실패하면 EXIT
      DO 1 TIMES.
        " 2. 회계전표 번호
        PERFORM get_accdoc_h_no CHANGING accdoc_h_no.
        IF gv_err = 'X'. EXIT. ENDIF.
        gv_belnr = accdoc_h_no.

        " 3. 자재이동문서
        PERFORM create_matdoc_h.
        IF gv_err = 'X'. EXIT. ENDIF.
        PERFORM alloc_matdoc_i.
        IF gv_err = 'X'. EXIT. ENDIF.

        " 4. 구매오더 상태 / 이력
        PERFORM update_procstat.
        IF gv_err = 'X'. EXIT. ENDIF.
        PERFORM update_po_hist.
        IF gv_err = 'X'. EXIT. ENDIF.

        " 5. 회계전표
        PERFORM create_accdoc_h.
        PERFORM create_accdoc_i.
        IF gv_err = 'X'. EXIT. ENDIF.

        " 6. 재고 수량 / 평가
        PERFORM update_mat_stk_val.
        IF gv_err = 'X'. EXIT. ENDIF.
      ENDDO.

      " 실패 → 전체 취소 후 300번에 머무름
      IF gv_err = 'X'.
        PERFORM rollback_invo.
        RETURN.
      ENDIF.

      " 7. 처리된 PO 목록 확보 (gt_matdoc_i를 비우기 전에)
      CLEAR lt_done_po.
      LOOP AT gt_matdoc_i INTO gs_matdoc_i.
        lv_done_po = gs_matdoc_i-zzrefdoc.
        INSERT lv_done_po INTO TABLE lt_done_po.   " 중복 PO는 자동 제외
      ENDLOOP.


      " 8. 커밋
      COMMIT WORK AND WAIT.
*      IF sy-subrc = 0. MESSAGE I224(z8_msg) WITH |{ gv_ebeln }|.
*      ELSE. ROLLBACK WORK. MESSAGE S054(z8_msg). RETURN.
*      ENDIF.

      " 결과 메시지
      CLEAR lv_first_po.
      READ TABLE lt_done_po INTO lv_first_po INDEX 1.
      lv_etc_cnt = lines( lt_done_po ) - 1.

      IF lv_etc_cnt <= 0.
        MESSAGE s236(z8_msg) WITH gv_new_doc_mblnr lv_first_po.
      ELSE.
        MESSAGE s237(z8_msg) WITH gv_new_doc_mblnr lv_first_po lv_etc_cnt.
      ENDIF.

      " 9. 종료
      PERFORM unlock_all.
      PERFORM clear_data.
      CLEAR :gt_po_i, gt_matdoc_i, gt_matdoc_h.
      "PERFORM get_mat_data.
      LEAVE TO SCREEN 0.

    WHEN OTHERS.

  ENDCASE.
ENDMODULE.
