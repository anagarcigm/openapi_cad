*---------------------------------------------------------------------*
*    view related data declarations
*   generation date: 25.11.2020 at 09:49:49
*   view maintenance generator version: #001407#
*---------------------------------------------------------------------*
*...processing: ZTOPEN_API......................................*
DATA:  BEGIN OF STATUS_ZTOPEN_API                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTOPEN_API                    .
CONTROLS: TCTRL_ZTOPEN_API
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTOPEN_API                    .
TABLES: ZTOPEN_API                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
