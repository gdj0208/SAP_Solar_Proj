*&---------------------------------------------------------------------*
*& Include          Z8MMGR100I02
*&---------------------------------------------------------------------*


MODULE user_command_0200 INPUT.
  CLEAR : ok_code.

  CASE OK_CODE.

    WHEN 'BACK' OR 'CNCL' OR 'EXIT'.
      CALL FUNCTION 'DEQUEUE_ALL'.
      LEAVE PROGRAM.

    WHEN 'CONF'.
      IF p_date < gs_po_h-bedat.
        MESSAGE i056(z8_msg).
        RETURN.
      ENDIF.

      IF p_menge <> p_inv + p_in + p_ret.
        MESSAGE i021(z8_msg).
        RETURN.
      ENDIF.

      PERFORM make_matdoc.
    ENDCASE.
ENDMODULE.
