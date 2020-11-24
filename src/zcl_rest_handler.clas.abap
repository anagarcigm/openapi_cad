CLASS zcl_rest_handler DEFINITION
  PUBLIC
  INHERITING FROM cl_rest_http_handler
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    METHODS: if_rest_application~get_root_handler REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_REST_HANDLER IMPLEMENTATION.


  METHOD if_rest_application~get_root_handler.

    " Leer
    " https://blogs.sap.com/2018/02/03/abap-and-swaggeropenapi/


    " http://sapabapcentral.blogspot.com/2018/06/writing-sicf-service.html
    " https://medium.com/pacroy/developing-apis-in-abap-just-rest-not-odata-d91cf899f7d3
    " https://blogs.sap.com/2019/09/03/abap-openapi-ui-v1-released/

    DATA(lo_router) = NEW cl_rest_router( ).
    " Escenarios...
    " Obtener JSON de un SERVICIO/API
    " Ejemplo http://labs4bapp02.localdomain.local:8000/zcad_srv_api/info_get?sap-client=210
    lo_router->attach( iv_template = '/info_get' iv_handler_class = 'ZCL_REST_RESOURCE' ).
    " Obtener lista de SERVICIOs/APIs
    "Ejemplo http://labs4bapp02.localdomain.local:8000/zcad_srv_api/info_all?sap-client=210
    lo_router->attach( iv_template = '/info_all' iv_handler_class = 'ZCL_REST_RESOURCE_LIST' ).
    ro_root_handler = lo_router.



  ENDMETHOD.
ENDCLASS.
