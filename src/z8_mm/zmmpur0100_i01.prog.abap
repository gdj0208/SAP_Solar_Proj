*&---------------------------------------------------------------------*
*& Include ZMMPUR0100_I01
*&---------------------------------------------------------------------*
*& PAI - 버튼·카드 명령 처리, 담당 지사 F4
*& 담당: MM(이규빈) / 프로그램: ZMMPUR0100
*&---------------------------------------------------------------------*
*& [변경 이력]
*& 일자        변경자  구분        변경 내용
*& 2026-10-25  이규빈  최초 개발   최초 작성: 담당 지사의 PR·PO·STO 업무현황과 각 프로그램 이동 (개발 10/25~10/29)
*& 2026-10-30  이규빈  수정사항    시연·단위테스트 반영: 카드 4개 화면 개편, 이동 후 새 문서 표시
*& 2026-11-05  이규빈  수정사항    조회 기준 보완: 담당 지사 → 그 지사의 입고플랜트 기준 조회, 조회 기간(시작·종료일) 추가
*& 2026-11-08  이규빈  인수인계    인수인계 정리: 헤더·주석 정리
*&---------------------------------------------------------------------*

" BACK/EXIT/CANC는 최초 화면에서도 바로 종료된다.
MODULE exit_0100 INPUT.
  PERFORM free_controls.
  LEAVE TO SCREEN 0.
ENDMODULE.

" command_0100 : PAI. 지사 확인 → 버튼/카드 명령 처리. 지사가 바뀌면 PBO에서 다시 조회한다.
MODULE command_0100 INPUT.
  gv_command = ok_code.
  IF gv_command IS INITIAL.
    gv_command = sy-ucomm.
  ENDIF.
  CLEAR: ok_code, sy-ucomm.
  IF gv_command = 'BACK' OR gv_command = 'EXIT' OR gv_command = 'CANC'.
    PERFORM free_controls.
    LEAVE TO SCREEN 0.
  ENDIF.
  DATA site_valid TYPE abap_bool.
  PERFORM validate_site CHANGING site_valid.
  IF site_valid = abap_false.
    RETURN.
  ENDIF.
  " 조회 기간: 시작일 필수, 종료일이 비면 시작일 하루만 본다.
  IF gv_dfrom IS INITIAL.
    MESSAGE s046(z8_msg) DISPLAY LIKE 'E'.   " 조회 기간을 입력해주세요
    SET CURSOR FIELD 'GV_DFROM'.
    RETURN.
  ENDIF.
  " 지사·기간이 바뀌어도 DB 조회는 [새로고침]·Enter 때만 한다(실제 조회는 PBO status_0100에서 한 번).
  gv_filter_changed = xsdbool( gv_werks <> gv_previous OR gv_dfrom <> gv_prev_dfrom OR gv_dto <> gv_prev_dto ).
  CASE gv_command.
    WHEN 'QUERY' OR 'REFR'.
      CLEAR: gt_pur_new, gv_pur_sel.     " 새로고침 = 파란 줄 정리
      CLEAR gv_row.
      gv_refresh = abap_true.
    WHEN 'ENTR' OR 'ENTER' OR space.
      CLEAR gv_row.
      gv_refresh = abap_true.
    WHEN 'PRLIST'.
      gv_view = 'R'.
      gv_reselect = abap_true.           " 카드 전환은 이미 읽은 데이터로 목록만 바꾼다
    WHEN 'POLIST'.
      gv_view = 'O'.
      gv_reselect = abap_true.
    WHEN 'STLIST'.
      gv_view = 'S'.
      gv_reselect = abap_true.
    WHEN 'PRALL'.
      PERFORM open_pr_list.
    WHEN 'POALL'.
      PERFORM open_po_list.
    WHEN 'PRNEW'.
      PERFORM new_pr.
    WHEN 'PONEW'.
      PERFORM new_po.
    WHEN 'STNEW'.
      PERFORM new_sto.
    WHEN 'STALL'.
      PERFORM open_sto_list.
    WHEN 'INV'.
      " 위쪽 [지사 재고 조회] 버튼 → 지사재고 통합현황(Z8MMDS0100) 0100 화면
      PERFORM open_stock.
    WHEN 'OPEN'.
      IF gv_filter_changed = abap_true.
        MESSAGE s126(z8_msg).   " 조회 범위를 확인해주세요(조건이 바뀌었으니 다시 조회)
      ELSE.
        PERFORM open_document.
      ENDIF.
  ENDCASE.
  IF gv_reselect = abap_true AND gv_filter_changed = abap_true.
    MESSAGE s126(z8_msg).   " 조회 범위를 확인해주세요(조건이 바뀌었으니 다시 조회)
  ENDIF.
ENDMODULE.

" 0100 지사코드의 F4 검색도움말이다.
MODULE help_werks INPUT.
  PERFORM choose_plant.
ENDMODULE.
