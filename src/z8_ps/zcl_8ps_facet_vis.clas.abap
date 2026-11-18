CLASS zcl_8ps_facet_vis DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_8ps_facet_vis IMPLEMENTATION.
  METHOD if_sadl_exit_calc_element_read~get_calculation_info.

    "가상 필드 계산에 필요한 원본 필드 요청
    APPEND 'PROJECTSTATUS' TO et_requested_orig_elements.

  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~calculate.

    DATA lt_projects TYPE STANDARD TABLE OF z8ps_c_project WITH DEFAULT KEY.

    "조회된 프로젝트 데이터 가져오기
    lt_projects = CORRESPONDING #( it_original_data ).

    LOOP AT lt_projects ASSIGNING FIELD-SYMBOL(<ls_project>).

      "상태 20이면 배정 인력 탭 숨김
      <ls_project>-HideAssignedTech =
        xsdbool( <ls_project>-ProjectStatus = '20' ).

      "상태 30, 40, 50, 60: 가용인력 섹션 숨김
    <ls_project>-HideAvailableTech =
      xsdbool(
        <ls_project>-ProjectStatus = '30' OR
        <ls_project>-ProjectStatus = '40' OR
        <ls_project>-ProjectStatus = '50' OR
        <ls_project>-ProjectStatus = '60'
      ).


    ENDLOOP.

    "계산 결과를 RAP/Fiori에 반환
    ct_calculated_data = CORRESPONDING #( lt_projects ).

  ENDMETHOD.
ENDCLASS.
