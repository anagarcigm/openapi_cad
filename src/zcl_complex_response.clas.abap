CLASS zcl_complex_response DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPES: BEGIN OF ts_response,
             p_serv         TYPE /iwfnd/med_mdl_service_grp_id,
             p_vers         TYPE /iwfnd/med_mdl_version,
             ev_json_string TYPE string,
           END OF ts_response,
           tt_response TYPE STANDARD TABLE OF ts_response.
    DATA: resp TYPE tt_response.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_COMPLEX_RESPONSE IMPLEMENTATION.
ENDCLASS.
