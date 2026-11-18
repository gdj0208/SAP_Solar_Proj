CLASS lhc_Project DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Project RESULT result.

    METHODS startWork FOR MODIFY
      IMPORTING keys FOR ACTION Project~startWork RESULT result.

    METHODS completeInstall FOR MODIFY
      IMPORTING keys FOR ACTION Project~completeInstall RESULT result.

    METHODS completeInspect FOR MODIFY
      IMPORTING keys FOR ACTION Project~completeInspect RESULT result.

ENDCLASS.

CLASS lhc_Project IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD completeInspect.
  " 고객 검수 완료 버튼: 상태를 '60'(검수 완료)으로 변경하고 대금 청구 준비
    MODIFY ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Project
      UPDATE FIELDS ( status )
      WITH VALUE #( FOR key IN keys ( pro_id = key-pro_id status = '60' ) ).

    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Project
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(projects).

    result = VALUE #( FOR proj IN projects ( pro_id = proj-pro_id %param = proj ) ).
  ENDMETHOD.

  METHOD completeInstall." 설치 완료 버튼: 상태를 '50'(설치 완료)으로 변경
    MODIFY ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Project
      UPDATE FIELDS ( status )
      WITH VALUE #( FOR key IN keys ( pro_id = key-pro_id status = '50' ) ).

    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Project
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(projects).

    result = VALUE #( FOR proj IN projects ( pro_id = proj-pro_id %param = proj ) ).
  ENDMETHOD.

  METHOD startWork.
  " 1. 선택된 프로젝트들의 현재 상태를 '40'(설치 진행)으로 변경
    MODIFY ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Project
      UPDATE FIELDS ( status )
      WITH VALUE #( FOR key IN keys ( pro_id = key-pro_id status = '40' ) ).

    " 2. 화면에 변경된 결과를 반영하여 반환
    READ ENTITIES OF z8r_projects IN LOCAL MODE
      ENTITY Project
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(projects).

    result = VALUE #( FOR proj IN projects ( pro_id = proj-pro_id %param = proj ) ).
  ENDMETHOD.

ENDCLASS.
