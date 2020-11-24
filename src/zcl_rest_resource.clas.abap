CLASS zcl_rest_resource DEFINITION
  PUBLIC
  INHERITING FROM cl_rest_resource
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS if_rest_resource~get
        REDEFINITION .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_REST_RESOURCE IMPLEMENTATION.


  METHOD if_rest_resource~get.

    "* CALL METHOD super->if_rest_resource~get.

    DATA: BEGIN OF ls_request,
            p_serv TYPE /iwfnd/med_mdl_service_grp_id,
            p_vers TYPE /iwfnd/med_mdl_version,
          END OF ls_request.

    DATA: mv_repository       TYPE /iwbep/v4_med_repository_id,
          mv_group_id         TYPE /iwbep/v4_med_group_id,
          mv_external_service TYPE /iwfnd/med_mdl_service_grp_id,
          mv_version          TYPE /iwfnd/med_mdl_version,
          mv_base_url         TYPE string,
          mv_scheme           TYPE string,
          mv_host             TYPE string,
          mv_path             TYPE string,
          mv_description      TYPE string.

    DATA: lv_service   TYPE string,
          lv_path(255) TYPE c.

    DATA(lv_request_body) = mo_request->get_entity( )->get_string_data( ).
    /ui2/cl_json=>deserialize( EXPORTING json = lv_request_body CHANGING data = ls_request ).

    IF ls_request-p_serv IS INITIAL.
      RAISE EXCEPTION TYPE cx_rest_resource_exception
        EXPORTING
          status_code    = cl_rest_status_code=>gc_client_error_bad_request
          request_method = if_rest_request=>gc_method_post.
    ENDIF.

    IF ls_request-p_vers IS INITIAL.
      ls_request-p_vers = '0001'.
    ENDIF.

    " Revisamos los servicios activos...
    SELECT SINGLE h~srv_identifier, h~namespace, h~service_name, h~service_version, t~description
      FROM /iwfnd/i_med_srh AS h
      LEFT OUTER JOIN /iwfnd/i_med_srt AS t ON h~srv_identifier = t~srv_identifier
                                            AND h~is_active      = t~is_active
                                            AND t~language       = @sy-langu
                 INTO @DATA(ls_service)
                      WHERE service_name    = @ls_request-p_serv
                        AND service_version = @ls_request-p_vers.

    IF sy-subrc NE 0.
      RAISE EXCEPTION TYPE cx_rest_resource_exception
        EXPORTING
          status_code    = cl_rest_status_code=>gc_client_error_not_found
          request_method = if_rest_request=>gc_method_get.
    ENDIF.

    DATA(lo_icf_access) = /iwfnd/cl_icf_access=>get_icf_access( ).
    DATA(lt_icfdocu)    = lo_icf_access->get_icf_docu_for_gw_libs_wo_at( ).

    LOOP AT lt_icfdocu INTO DATA(ls_icfdocu).
      " Get main odata node
      DATA(lv_icf_lib_guid) = lo_icf_access->get_node_guid_wo_at(
                                iv_icf_parent_guid = ls_icfdocu-icfparguid
                                iv_icf_node_name   = CONV icfaltnme( ls_icfdocu-icf_name ) ).
    ENDLOOP.


    "   Get OData service URL
    TRY.
        CASE lv_icf_lib_guid.
          WHEN /iwfnd/cl_icf_access=>gcs_icf_node_ids-lib_02.
            DATA(lv_md_url) = /iwfnd/cl_med_utils=>get_meta_data_doc_url_local(
                                  iv_external_service_doc_name = ls_service-service_name
                                  iv_namespace                 = ls_service-namespace
                                  iv_icf_root_node_guid        = lv_icf_lib_guid ).

          WHEN /iwfnd/cl_icf_access=>gcs_icf_node_ids-lib_10.
            lv_md_url = /iwfnd/cl_med_utils=>get_meta_data_doc_url_local(
                            iv_external_service_doc_name = ls_service-service_name
                            iv_namespace                 = ls_service-namespace
                            iv_version                   = ls_service-service_version
                            iv_icf_root_node_guid        = lv_icf_lib_guid ).
        ENDCASE.

      CATCH /iwfnd/cx_med_mdl_access.
    ENDTRY.

    "*   Remove everything but path from URL
    REPLACE '/?$format=xml' IN lv_md_url WITH ''.
    DATA(lv_md_url_full) = lv_md_url.
    IF lv_md_url IS NOT INITIAL.
      DATA(lv_leng) = strlen( lv_md_url ).
      IF lv_leng > 7 AND ( lv_md_url(7) = 'http://' OR lv_md_url(8) = 'https://' ).
        SEARCH lv_md_url FOR '/sap/opu/'.
        IF sy-subrc = 0.
          lv_md_url = lv_md_url+sy-fdpos.
        ENDIF.
      ENDIF.
    ENDIF.

    "*   Set service
    lv_service = ls_service-namespace && ls_service-service_name.

    "*   Get base URL details
    IF mv_base_url IS NOT INITIAL.
      DATA(lv_base_url) = mv_base_url && lv_md_url.
    ELSE.
      lv_base_url = lv_md_url_full.
    ENDIF.

    SPLIT lv_base_url AT '://' INTO DATA(lv_scheme) DATA(lv_url_without_scheme).
    SPLIT lv_url_without_scheme AT '/' INTO DATA(lv_host) lv_path.

    DATA(lv_length) = strlen( lv_path ) - 1.
    IF lv_path+lv_length(1) = '/'.
      lv_path+lv_length(1) = ''.
    ENDIF.

    "*   Store scheme, host and path
    mv_scheme = lv_scheme.
    mv_host = lv_host.
    mv_path = lv_path.


    DATA(lo_transaction_handler) = /iwfnd/cl_transaction_handler=>get_transaction_handler( ).

    "*   Initialize transaction handler (set metadata access with full documentation)
    lo_transaction_handler->initialize(
        iv_request_id            = ''
        iv_external_srv_grp_name = ls_request-p_serv
        iv_version               = ls_request-p_vers
        iv_namespace             = ''
        iv_verbose_metadata      = /iwfnd/if_mgw_core_types=>gcs_verbose_metadata-all ).

    "*   initialize metadata access
    lo_transaction_handler->set_metadata_access_info(
        iv_load_last_modified_only = abap_false
        iv_is_busi_data_request    = abap_false
        iv_do_cache_handshake      = abap_true ).

    "*   Load metadata document
    DATA(li_service_factory) = /iwfnd/cl_sodata_svc_factory=>get_svc_factory( ).
    DATA: lserv TYPE string.
    lserv = ls_request-p_serv.

    DATA(li_service) = li_service_factory->create_service( iv_name = lserv ).
    DATA(li_edm) = li_service->get_entity_data_model( ).
    DATA(li_metadata) = li_edm->get_service_metadata( ).

    DATA iv_metadata_v2 TYPE xstring.
    DATA rv_metadata TYPE xstring.
    DATA rv_metadata_v4 TYPE xstring.
    li_metadata->get_metadata( IMPORTING ev_metadata = rv_metadata ).

    iv_metadata_v2 = rv_metadata.

    "*   Convert OData V2 to V4 metadata document
    CALL TRANSFORMATION zcad_odatav2_to_v4
      SOURCE XML iv_metadata_v2
      RESULT XML rv_metadata_v4.


    DATA: lt_parameters TYPE abap_trans_parmbind_tab.

    "*   Set transformation parameters
    DATA(lv_version) = ls_request-p_vers.
    SHIFT lv_version LEFT DELETING LEADING '0'.
    lv_version = 'V' && lv_version.

    lt_parameters = VALUE #( ( name = 'openapi-version' value = '3.0.0' )
                             ( name = 'odata-version' value = '4.0' )
                             ( name = 'scheme' value = mv_scheme )
                             ( name = 'host' value = mv_host )
                             ( name = 'basePath' value = '/' && mv_path )
                             ( name = 'info-version' value = lv_version )
                             ( name = 'info-title' value = mv_external_service )
                             ( name = 'info-description' value = mv_description )
                             ( name = 'references' value = 'YES' )
                             ( name = 'diagram' value = 'YES' ) ).

    "*   Convert metadata document to openapi

    DATA rv_json TYPE xstring.
    CALL TRANSFORMATION zcad_odatav4_to_openapi
     SOURCE XML rv_metadata_v4
      RESULT XML rv_json
      PARAMETERS (lt_parameters).


    "*   Convert binary data to string
    DATA(lo_conv) = cl_abap_conv_in_ce=>create(
                        encoding    = 'UTF-8'
                        input       = rv_json ).
    DATA: lv_openapi_string TYPE string.

    lo_conv->read( IMPORTING data = lv_openapi_string ).

    "*   Add basic authentication to OpenAPI JSON
    "REPLACE ALL OCCURRENCES OF '"components":{' IN lv_openapi_string
    "WITH '"components":{"securitySchemes":{"BasicAuth":{"type":"http","scheme":"basic"}},'.

    "*   Convert OpenAPI JSON to binary format
    DATA lv_openapi TYPE xstring.
    CLEAR lv_openapi.
    CALL FUNCTION 'SCMS_STRING_TO_XSTRING'
      EXPORTING
        text   = lv_openapi_string
      IMPORTING
        buffer = lv_openapi
      EXCEPTIONS
        failed = 1
        OTHERS = 2.

    DATA: ev_json	        TYPE xstring.
    DATA: ev_json_string  TYPE string.

    "*   Set exporting parameters
    ev_json        = lv_openapi.
    ev_json_string = lv_openapi_string.

    " -------------------------------------------------------------------------------------------------------
    " -------------------------------------------------------------------------------------------------------
    " Respuesta...

    DATA(lo_response) = NEW zcl_complex_response( ).

    INSERT INITIAL LINE INTO TABLE lo_response->resp ASSIGNING FIELD-SYMBOL(<resp>).
    <resp>-p_serv         = ls_request-p_serv.
    <resp>-p_vers         = ls_request-p_vers.
    <resp>-ev_json_string = ev_json_string.


    DATA(lo_entity) = mo_response->create_entity( ).
    lo_entity->set_content_type( if_rest_media_type=>gc_appl_json ).
    " lo_entity->set_string_data( /ui2/cl_json=>serialize( lo_response ) ).
    lo_entity->set_string_data( ev_json_string ).
    mo_response->set_status( cl_rest_status_code=>gc_success_ok ).

  ENDMETHOD.
ENDCLASS.
