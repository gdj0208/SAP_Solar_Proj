*&---------------------------------------------------------------------*
*& Include          Z8MMSH0100E01
*&---------------------------------------------------------------------*
INITIALIZATION.
  AUTHORITY-CHECK OBJECT 'Z8MM_ADMIN'
  ID 'ACTVT' FIELD '16'. "실행
  IF sy-subrc <> 0.
    MESSAGE e200(z8_msg) WITH 'MM'.
  ENDIF.
AT SELECTION-SCREEN.
  PERFORM check_input.

START-OF-SELECTION.
  PERFORM select_target. "목표수량이 있는 대상 읽기.

  IF gt_alv IS INITIAL.
    MESSAGE '점검 대상이 없습니다.' TYPE 'S' DISPLAY LIKE 'W'.
    RETURN.
  ENDIF.

  PERFORM select_stock.       " 현재고,예약재고 읽기, 가용재고 계산.
  """입고예정 계산""""
  PERFORM calc_inbound_pr. " PO안넘어간 PR.
  PERFORM calc_inbound_po. "PO생성 후 물건이 다 안들어온 PO.
  LOOP AT gt_alv INTO gs_alv.
    gs_alv-inbound = gs_alv-inb_pr + gs_alv-inb_po.
    MODIFY gt_alv FROM gs_alv.
  ENDLOOP.

  PERFORM check_reorder.       "재주문 대상만 남기고, 주문수량  체크.
  IF gt_alv IS INITIAL.
    MESSAGE |재주문이 필요한 자재가 없습니다. (점검 { gv_checked }건)| TYPE 'S'.
    RETURN.
  ENDIF.
  PERFORM select_vendor.        "최저가 업체 선정.
  PERFORM calc_due_date.        "납기일 계산.

  " 실제 실행이면 한 번 더 확인 (백그라운드 실행은 확인 없이 진행)
  IF p_exec = 'X' AND sy-batch IS INITIAL.
    DATA lv_answer TYPE c LENGTH 1.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar      = '재고 보충 배치'
        text_question = 'PR을 실제로 생성합니다. 계속할까요?'
      IMPORTING
        answer        = lv_answer.
    IF lv_answer <> '1'.
      MESSAGE '실행이 취소되었습니다.' TYPE 'S'.
      RETURN.
    ENDIF.
  ENDIF.

  PERFORM create_pr.    "PR 생성
  PERFORM fill_display.   "텍스트 추가.

  IF sy-batch = 'X'.
    PERFORM write_list.            " 백그라운드: 화면이 없으니 목록으로 출력
  ELSE.
    CALL SCREEN 0100.              " 화면에서 실행: ALV
  ENDIF.
