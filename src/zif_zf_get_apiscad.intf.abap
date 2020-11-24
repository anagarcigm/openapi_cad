interface ZIF_ZF_GET_APISCAD
  public .


  types:
    ICFALTNME type C length 000120 .
  types:
    /IWFND/MED_MDL_VERSION type N length 000004 .
  types:
    /IWFND/MED_MDL_SRG_DESCRIPTION type C length 000060 .
  types:
    begin of ZSAPIS,
      API type ICFALTNME,
      SERVICE_VERSION type /IWFND/MED_MDL_VERSION,
      DESCRIPTION type /IWFND/MED_MDL_SRG_DESCRIPTION,
    end of ZSAPIS .
  types:
    ZTTAPIS                        type standard table of ZSAPIS                         with non-unique default key .
  types:
    XFELD type C length 000001 .
endinterface.
