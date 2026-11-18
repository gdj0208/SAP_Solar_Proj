*&---------------------------------------------------------------------*
*& Include          Z8COSD100I02
*&---------------------------------------------------------------------*

MODULE user_command_0200 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
      LEAVE TO SCREEN 100.

    WHEN 'REJ'.
      " 사유별 보기 탭 클릭: 사유 ALV 켜고, 지사 ALV 끄기
      gv_active_tab = 1.
      go_alv_rej->set_visible( abap_true ).
      go_alv_bup->set_visible( abap_false ).

    WHEN 'BRCH'.
      " 지사별 보기 탭 클릭: 지사 ALV 켜고, 사유 ALV 끄기
      gv_active_tab = 2.
      go_alv_rej->set_visible( abap_false ).
      go_alv_bup->set_visible( abap_true ).

    WHEN 'DETL'.
      " 상세 정보 조회
      "PERFORM GET_DETAIL_DATA.

    WHEN OTHERS.
  ENDCASE.
ENDMODULE.
