*&---------------------------------------------------------------------*
*& Report Z8FICR0100
*&---------------------------------------------------------------------*
*& FI-CR010. 고객 입금처리 통합
*& 담당: FI(박주연) / T-Code: Z8FICR0100
*& 개발: 2026-10-19
*& 참고: 선수금 입금처리(Z8FIDP0100), 잔금 입금처리(Z8FIFC0100) 프로그램과 연계
*&
*& - 10/19
*& - 선수금/잔금 입금 유형에 따라 각 처리 프로그램을 SUBMIT 방식으로
*&   호출하고 조회조건 전달 및 실행 후 복귀 흐름을 적용 BY SESAC-139
*&---------------------------------------------------------------------*

INCLUDE Z8FICR0100TOP                           .    " Global Data
INCLUDE Z8FICR0100SEL.
INCLUDE Z8FICR0100F01                           .  " FORM-Routines


LOAD-OF-PROGRAM.

INITIALIZATION.
 PERFORM authority_check .
  PERFORM set_default_data.

AT SELECTION-SCREEN.

  PERFORM check_obligatory.
  PERFORM comment_clear.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_bran.
  PERFORM f4_bupla.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pa_kunnr.
  PERFORM f4_kunnr.

AT SELECTION-SCREEN OUTPUT. "1000번 화면의 PBO로직

  PERFORM get_comment_text.

START-OF-SELECTION.

  IF rb_adv = 'X'.
    "선수금 프로그램 호출.
    PERFORM call_fidp_program.
  ELSEIF rb_bal = 'X'.
    "잔금 프로그램 호출
    PERFORM call_fifc_program.
  ENDIF.
