FUNCTION zf_get_apiscad.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     VALUE(IV_ACTIVO) TYPE  XFELD OPTIONAL
*"  EXPORTING
*"     VALUE(ET_APIS) TYPE  ZTTAPIS
*"----------------------------------------------------------------------

* /IWBEP/I_SBD_SV ->
  IF iv_activo = abap_true.
    SELECT  a~icfaltnme, c~service_version, d~description
           FROM icfservice AS a INNER JOIN icfservloc AS b ON a~icf_name = b~icf_name
            INNER JOIN /iwfnd/i_med_srh AS c ON a~icfaltnme = c~service_name
                         INNER JOIN /iwfnd/i_med_srt AS d ON c~srv_identifier = d~srv_identifier
      INTO TABLE @et_apis
      WHERE b~icfactive = @abap_true
      AND ( a~icfaltnme LIKE @gc_api OR a~icfaltnme LIKE @gc_zapi OR a~icfaltnme LIKE @gc_wildcard )
         AND d~language = @sy-langu.
  ELSE.
    SELECT a~icfaltnme, b~service_version, c~description
    FROM icfservice AS a INNER JOIN /iwfnd/i_med_srh AS b ON a~icfaltnme = b~service_name
                         INNER JOIN /iwfnd/i_med_srt AS c ON b~srv_identifier = c~srv_identifier
       INTO TABLE @et_apis
    WHERE ( a~icfaltnme LIKE @gc_api OR a~icfaltnme LIKE @gc_zapi OR a~icfaltnme LIKE @gc_wildcard )
      AND c~language = @sy-langu.
  ENDIF.


ENDFUNCTION.
