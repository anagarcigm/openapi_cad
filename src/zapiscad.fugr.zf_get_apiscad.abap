FUNCTION zf_get_apiscad.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_ACTIVO) TYPE  XFELD OPTIONAL
*"  EXPORTING
*"     VALUE(ET_APIS) TYPE  ZTTAPIS
*"----------------------------------------------------------------------
  DATA: lt_openapi TYPE TABLE OF ztopen_api,
        ls_openapi TYPE ztopen_api,
        lr_range   TYPE RANGE OF ztopen_api-patron,
        ls_range   LIKE LINE OF lr_range.
  SELECT * INTO TABLE lt_openapi
    FROM ztopen_api.

  LOOP AT lt_openapi INTO ls_openapi.
    ls_range-option = 'CP'.
    ls_range-sign = 'I'.
    ls_range-low =  ls_openapi-patron.
    APPEND ls_range TO lr_range.
  ENDLOOP.

* /IWBEP/I_SBD_SV ->
  IF iv_activo = abap_true.
    SELECT  a~icfaltnme, c~service_version, d~description
           FROM icfservice AS a INNER JOIN icfservloc AS b ON a~icf_name = b~icf_name
            INNER JOIN /iwfnd/i_med_srh AS c ON a~icfaltnme = c~service_name
                         INNER JOIN /iwfnd/i_med_srt AS d ON c~srv_identifier = d~srv_identifier
      INTO TABLE @et_apis
      WHERE b~icfactive = @abap_true
*      AND ( a~icfaltnme LIKE @gc_api OR a~icfaltnme LIKE @gc_zapi OR a~icfaltnme LIKE @gc_wildcard )
       AND  a~icfaltnme IN @lr_range
         AND d~language = @sy-langu
       ORDER BY icfaltnme.
  ELSE.
    SELECT a~icfaltnme, b~service_version, c~description
    FROM icfservice AS a INNER JOIN /iwfnd/i_med_srh AS b ON a~icfaltnme = b~service_name
                         INNER JOIN /iwfnd/i_med_srt AS c ON b~srv_identifier = c~srv_identifier
       INTO TABLE @et_apis
*    WHERE ( a~icfaltnme LIKE @gc_api OR a~icfaltnme LIKE @gc_zapi OR a~icfaltnme LIKE @gc_wildcard )
      WHERE a~icfaltnme IN @lr_range
      AND c~language = @sy-langu
      ORDER BY icfaltnme.
  ENDIF.


  DELETE ADJACENT DUPLICATES FROM et_apis COMPARING api.


ENDFUNCTION.
