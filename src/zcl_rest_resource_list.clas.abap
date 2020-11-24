class ZCL_REST_RESOURCE_LIST definition
  public
  inheriting from CL_REST_RESOURCE
  final
  create public .

public section.

  methods IF_REST_RESOURCE~GET
    redefinition .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_REST_RESOURCE_LIST IMPLEMENTATION.


  METHOD if_rest_resource~get.

    "* CALL METHOD super->if_rest_resource~get.


    DATA(lv_request_body) = mo_request->get_entity( )->get_string_data( ).

    IF lv_request_body IS NOT INITIAL.
      RAISE EXCEPTION TYPE cx_rest_resource_exception
        EXPORTING
          status_code    = cl_rest_status_code=>gc_client_error_bad_request
          request_method = if_rest_request=>gc_method_post.
    ENDIF.

    DATA iv_activo TYPE xfeld.
    DATA et_apis   TYPE zttapis.

    CALL FUNCTION 'ZF_GET_APISCAD'
      IMPORTING
        et_apis = et_apis.

    DATA(lo_entity) = mo_response->create_entity( ).
    lo_entity->set_content_type( if_rest_media_type=>gc_appl_json ).
    lo_entity->set_string_data( /ui2/cl_json=>serialize( et_apis ) ).
    mo_response->set_status( cl_rest_status_code=>gc_success_ok ).

  ENDMETHOD.
ENDCLASS.
