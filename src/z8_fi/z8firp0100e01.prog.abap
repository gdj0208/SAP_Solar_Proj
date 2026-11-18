*&---------------------------------------------------------------------*
*& Include          Z8FIRP0100E01
*&---------------------------------------------------------------------*

INITIALIZATION.

PERFORM authority_check.
PERFORM set_default_data.
*PERFORM get_text.

AT SELECTION-SCREEN.

  PERFORM check_obligatory.

AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.

    IF rb_cust = 'X'.

      IF screen-group1 = 'AR1'.
        screen-active = 1.
        IF screen-name = 'P_CBUKRS'.
          screen-input = 0.
        ENDIF.
      ELSEIF screen-group1 = 'AP1'.
        screen-active = 0.
      ENDIF.

    ELSEIF rb_vend = 'X'.

      IF screen-group1 = 'AR1'.
        screen-active = 0.
      ELSEIF screen-group1 = 'AP1'.
        screen-active = 1.
        IF screen-name = 'P_VBUKRS'.
          screen-input = 0.
        ENDIF.
      ENDIF.

    ENDIF.

    MODIFY SCREEN.

  ENDLOOP.


START-OF-SELECTION.
  IF rb_cust = 'X'.
    PERFORM get_ar_data.
    IF gt_ar_detail IS INITIAL.
      MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    PERFORM make_ar_sum.
    IF gt_ar_100 IS INITIAL.
      MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CALL SCREEN 0100.

  ELSEIF rb_vend = 'X'.
    PERFORM get_ap_data.
    IF gt_ap_detail IS INITIAL.
      MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    PERFORM make_ap_sum.
    IF gt_ap_300 IS INITIAL.
      MESSAGE s061(z8_msg) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    CALL SCREEN 0300.

  ENDIF.
