CLASS zcl_8ps_test_assign_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_8ps_test_assign_eml IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    MODIFY ENTITIES OF z8ps_r_project

      ENTITY Project

      EXECUTE confirmationAssignment

      FROM VALUE #(
        (
          ProjectId = 'P000000013'

          %param = VALUE #(
            _Members = VALUE #(
              ( PersonalNumber = '10000001' ) "전기기사
              ( PersonalNumber = '10000005' ) "설치기사
              ( PersonalNumber = '10000008' ) "설치기사
              ( PersonalNumber = '10000010' ) "설치기사

            )
          )
        )
      )

      FAILED DATA(lt_failed)
      REPORTED DATA(lt_reported).

    "EML 실행 결과 확인
    out->write( '=== EML 실행 완료 ===' ).

    out->write(
      |FAILED 건수: { lines( lt_failed-project ) }|
    ).

    out->write(
      |REPORTED 건수: { lines( lt_reported-project ) }|
    ).

    LOOP AT lt_reported-project INTO DATA(ls_report).

      IF ls_report-%msg IS BOUND.
        out->write(
          ls_report-%msg->if_message~get_text( )
        ).
      ENDIF.

    ENDLOOP.

    "Action 처리에서 오류가 발생하면 저장하지 않음
    IF lt_failed IS NOT INITIAL.
      out->write( 'Action 실패 - 저장하지 않음' ).
      ROLLBACK ENTITIES.
      RETURN.
    ENDIF.

    "RAP 저장 실행
    COMMIT ENTITIES RESPONSE OF z8ps_r_project
      FAILED DATA(lt_commit_failed)
      REPORTED DATA(lt_commit_reported).

    DATA(lv_commit_subrc) = sy-subrc.

    out->write( |COMMIT SY-SUBRC: { lv_commit_subrc }| ).
    out->write( |COMMIT FAILED: { lines( lt_commit_failed-project ) }| ).

  ENDMETHOD.
ENDCLASS.
