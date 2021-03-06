CLASS zcl_abapgit_gui_router DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zif_abapgit_gui_event_handler.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS general_page_routing
      IMPORTING
        !ii_event TYPE REF TO zif_abapgit_gui_event
      RETURNING
        VALUE(rs_handled) TYPE zif_abapgit_gui_event_handler=>ty_handling_result
      RAISING
        zcx_abapgit_exception.
    METHODS abapgit_services_actions
      IMPORTING
        !ii_event TYPE REF TO zif_abapgit_gui_event
      RETURNING
        VALUE(rs_handled) TYPE zif_abapgit_gui_event_handler=>ty_handling_result
      RAISING
        zcx_abapgit_exception.
    METHODS db_actions
      IMPORTING
        !ii_event TYPE REF TO zif_abapgit_gui_event
      RETURNING
        VALUE(rs_handled) TYPE zif_abapgit_gui_event_handler=>ty_handling_result
      RAISING
        zcx_abapgit_exception.
    CLASS-METHODS file_download
      IMPORTING
        !iv_package TYPE devclass
        !iv_xstr    TYPE xstring
      RAISING
        zcx_abapgit_exception .
    METHODS git_services
      IMPORTING
        !ii_event TYPE REF TO zif_abapgit_gui_event
      RETURNING
        VALUE(rs_handled) TYPE zif_abapgit_gui_event_handler=>ty_handling_result
      RAISING
        zcx_abapgit_exception.
    METHODS remote_origin_manipulations
      IMPORTING
        !ii_event TYPE REF TO zif_abapgit_gui_event
      RETURNING
        VALUE(rs_handled) TYPE zif_abapgit_gui_event_handler=>ty_handling_result
      RAISING
        zcx_abapgit_exception.
    METHODS sap_gui_actions
      IMPORTING
        !ii_event TYPE REF TO zif_abapgit_gui_event
      RETURNING
        VALUE(rs_handled) TYPE zif_abapgit_gui_event_handler=>ty_handling_result
      RAISING
        zcx_abapgit_exception.
    METHODS other_utilities
      IMPORTING
        !ii_event TYPE REF TO zif_abapgit_gui_event
      RETURNING
        VALUE(rs_handled) TYPE zif_abapgit_gui_event_handler=>ty_handling_result
      RAISING
        zcx_abapgit_exception.
    METHODS zip_services
      IMPORTING
        !ii_event TYPE REF TO zif_abapgit_gui_event
      RETURNING
        VALUE(rs_handled) TYPE zif_abapgit_gui_event_handler=>ty_handling_result
      RAISING
        zcx_abapgit_exception.
    METHODS repository_services
      IMPORTING
        !ii_event TYPE REF TO zif_abapgit_gui_event
      RETURNING
        VALUE(rs_handled) TYPE zif_abapgit_gui_event_handler=>ty_handling_result
      RAISING
        zcx_abapgit_exception.
    METHODS get_page_diff
      IMPORTING
        !iv_getdata    TYPE clike
      RETURNING
        VALUE(ri_page) TYPE REF TO zif_abapgit_gui_renderable
      RAISING
        zcx_abapgit_exception .
    METHODS get_page_branch_overview
      IMPORTING
        !iv_getdata    TYPE clike
      RETURNING
        VALUE(ri_page) TYPE REF TO zif_abapgit_gui_renderable
      RAISING
        zcx_abapgit_exception .
    METHODS get_page_stage
      IMPORTING
        !iv_getdata    TYPE clike
      RETURNING
        VALUE(ri_page) TYPE REF TO zif_abapgit_gui_renderable
      RAISING
        zcx_abapgit_exception .
    METHODS get_page_background
      IMPORTING
        !iv_key        TYPE zif_abapgit_persistence=>ty_repo-key
      RETURNING
        VALUE(ri_page) TYPE REF TO zif_abapgit_gui_renderable
      RAISING
        zcx_abapgit_exception .

    CLASS-METHODS jump_display_transport
      IMPORTING
        !iv_getdata TYPE clike
      RAISING
        zcx_abapgit_exception.

    METHODS call_browser
      IMPORTING
        iv_url TYPE csequence
      RAISING
        zcx_abapgit_exception.

ENDCLASS.



CLASS ZCL_ABAPGIT_GUI_ROUTER IMPLEMENTATION.


  METHOD abapgit_services_actions.
    DATA: li_main_page TYPE REF TO zcl_abapgit_gui_page_main.
    CASE ii_event->mv_action.
      WHEN zif_abapgit_definitions=>c_action-abapgit_home.
        CREATE OBJECT li_main_page.
        rs_handled-page = li_main_page.
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-abapgit_install.                 " Install abapGit
        zcl_abapgit_services_abapgit=>install_abapgit( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
    ENDCASE.

  ENDMETHOD.


  METHOD call_browser.

    cl_gui_frontend_services=>execute(
      EXPORTING
        document               = |{ iv_url }|
      EXCEPTIONS
        cntl_error             = 1
        error_no_gui           = 2
        bad_parameter          = 3
        file_not_found         = 4
        path_not_found         = 5
        file_extension_unknown = 6
        error_execute_failed   = 7
        synchronous_failed     = 8
        not_supported_by_gui   = 9
        OTHERS                 = 10 ).

    IF sy-subrc <> 0.
      zcx_abapgit_exception=>raise_t100( ).
    ENDIF.

  ENDMETHOD.


  METHOD db_actions.

    CASE ii_event->mv_action.
      WHEN zif_abapgit_definitions=>c_action-db_edit.
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_db_edit
          EXPORTING
            is_key = zcl_abapgit_html_action_utils=>dbkey_decode( ii_event->mv_getdata ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
        IF ii_event->mi_gui_services->get_current_page_name( ) = 'ZCL_ABAPGIT_GUI_PAGE_DB_DIS'. " TODO refactor
          rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page_replacing.
        ENDIF.
      WHEN zif_abapgit_definitions=>c_action-db_display.
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_db_dis
          EXPORTING
            is_key = zcl_abapgit_html_action_utils=>dbkey_decode( ii_event->mv_getdata ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
    ENDCASE.

  ENDMETHOD.


  METHOD file_download.

    DATA:
      lv_path    TYPE string,
      lv_default TYPE string,
      li_fe_serv TYPE REF TO zif_abapgit_frontend_services,
      lv_package TYPE devclass.

    lv_package = iv_package.
    TRANSLATE lv_package USING '/#'.
    CONCATENATE lv_package '_' sy-datlo '_' sy-timlo INTO lv_default.

    li_fe_serv = zcl_abapgit_ui_factory=>get_frontend_services( ).

    lv_path = li_fe_serv->show_file_save_dialog(
      iv_title            = 'Export ZIP'
      iv_extension        = 'zip'
      iv_default_filename = lv_default ).

    li_fe_serv->file_download(
      iv_path = lv_path
      iv_xstr = iv_xstr ).

  ENDMETHOD.


  METHOD general_page_routing.

    DATA: lv_key           TYPE zif_abapgit_persistence=>ty_repo-key,
          lv_last_repo_key TYPE zif_abapgit_persistence=>ty_repo-key,
          lt_repo_list     TYPE zif_abapgit_definitions=>ty_repo_ref_tt.


    lv_key = ii_event->mv_getdata. " TODO refactor

    CASE ii_event->mv_action.
      WHEN zcl_abapgit_gui=>c_action-go_home.
        lv_last_repo_key = zcl_abapgit_persistence_user=>get_instance( )->get_repo_show( ).
        lt_repo_list = zcl_abapgit_repo_srv=>get_instance( )->list( ).

        IF lv_last_repo_key IS NOT INITIAL.
          CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_view_repo
            EXPORTING
              iv_key = lv_last_repo_key.
        ELSEIF lt_repo_list IS NOT INITIAL.
          CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_main.
        ELSE.
          rs_handled-page = zcl_abapgit_gui_page_tutorial=>create( ).
        ENDIF.

        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.

      WHEN zif_abapgit_definitions=>c_action-go_db.                          " Go DB util page
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_db.
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-go_debuginfo.
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_debuginfo.
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-go_settings.
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_settings.
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-go_background_run.              " Go background run page
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_bkg_run.
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-go_background.                   " Go Background page
        rs_handled-page  = get_page_background( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-go_diff.                         " Go Diff page
        rs_handled-page  = get_page_diff( ii_event->mv_getdata ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page_w_bookmark.
      WHEN zif_abapgit_definitions=>c_action-go_stage.                        " Go Staging page
        rs_handled-page  = get_page_stage( ii_event->mv_getdata ).
        IF ii_event->mi_gui_services->get_current_page_name( ) = 'ZCL_ABAPGIT_GUI_PAGE_DIFF'. " TODO refactor
          rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
        ELSE.
          rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page_w_bookmark.
        ENDIF.
      WHEN zif_abapgit_definitions=>c_action-go_branch_overview.              " Go repo branch overview
        rs_handled-page  = get_page_branch_overview( ii_event->mv_getdata ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-go_tutorial.                     " Go to tutorial
        rs_handled-page  = zcl_abapgit_gui_page_tutorial=>create( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-documentation.                   " abapGit docs
        zcl_abapgit_services_abapgit=>open_abapgit_wikipage( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
      WHEN zif_abapgit_definitions=>c_action-go_explore.                      " dotabap
        zcl_abapgit_services_abapgit=>open_dotabap_homepage( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
      WHEN zif_abapgit_definitions=>c_action-changelog.                       " abapGit full changelog
        zcl_abapgit_services_abapgit=>open_abapgit_changelog( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.

    ENDCASE.

  ENDMETHOD.


  METHOD get_page_background.

    CREATE OBJECT ri_page TYPE zcl_abapgit_gui_page_bkg
      EXPORTING
        iv_key = iv_key.

  ENDMETHOD.


  METHOD get_page_branch_overview.

    DATA: lo_repo TYPE REF TO zcl_abapgit_repo_online,
          lo_page TYPE REF TO zcl_abapgit_gui_page_boverview,
          lv_key  TYPE zif_abapgit_persistence=>ty_repo-key.


    lv_key = iv_getdata.

    lo_repo ?= zcl_abapgit_repo_srv=>get_instance( )->get( lv_key ).

    CREATE OBJECT lo_page
      EXPORTING
        io_repo = lo_repo.

    ri_page = lo_page.

  ENDMETHOD.


  METHOD get_page_diff.

    DATA: ls_file   TYPE zif_abapgit_definitions=>ty_file,
          ls_object TYPE zif_abapgit_definitions=>ty_item,
          lo_page   TYPE REF TO zcl_abapgit_gui_page_diff,
          lv_key    TYPE zif_abapgit_persistence=>ty_repo-key.


    zcl_abapgit_html_action_utils=>file_obj_decode(
      EXPORTING
        iv_string = iv_getdata
      IMPORTING
        ev_key    = lv_key
        eg_file   = ls_file
        eg_object = ls_object ).

    CREATE OBJECT lo_page
      EXPORTING
        iv_key    = lv_key
        is_file   = ls_file
        is_object = ls_object.

    ri_page = lo_page.

  ENDMETHOD.


  METHOD get_page_stage.

    DATA: lo_repo                TYPE REF TO zcl_abapgit_repo_online,
          lv_key                 TYPE zif_abapgit_persistence=>ty_repo-key,
          lv_seed                TYPE string,
          lo_stage_page          TYPE REF TO zcl_abapgit_gui_page_stage,
          lo_code_inspector_page TYPE REF TO zcl_abapgit_gui_page_code_insp.

    FIND FIRST OCCURRENCE OF '=' IN iv_getdata.
    IF sy-subrc <> 0. " Not found ? -> just repo key in params
      lv_key = iv_getdata.
    ELSE.
      zcl_abapgit_html_action_utils=>stage_decode(
        EXPORTING iv_getdata = iv_getdata
        IMPORTING ev_key     = lv_key
                  ev_seed    = lv_seed ).
    ENDIF.

    lo_repo ?= zcl_abapgit_repo_srv=>get_instance( )->get( lv_key ).

    IF lo_repo->get_local_settings( )-code_inspector_check_variant IS NOT INITIAL.

      CREATE OBJECT lo_code_inspector_page
        EXPORTING
          io_repo = lo_repo.

      ri_page = lo_code_inspector_page.

    ELSE.

      " force refresh on stage, to make sure the latest local and remote files are used
      lo_repo->refresh( ).

      CREATE OBJECT lo_stage_page
        EXPORTING
          io_repo = lo_repo
          iv_seed = lv_seed.

      ri_page = lo_stage_page.

    ENDIF.

  ENDMETHOD.


  METHOD git_services.

    DATA: lv_key TYPE zif_abapgit_persistence=>ty_repo-key.


    lv_key = ii_event->mv_getdata. " TODO refactor

    CASE ii_event->mv_action.
      WHEN zif_abapgit_definitions=>c_action-git_pull.                      " GIT Pull
        zcl_abapgit_services_git=>pull( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-git_reset.                     " GIT Reset
        zcl_abapgit_services_git=>reset( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-git_branch_create.             " GIT Create new branch
        zcl_abapgit_services_git=>create_branch( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-git_branch_delete.             " GIT Delete remote branch
        zcl_abapgit_services_git=>delete_branch( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-git_branch_switch.             " GIT Switch branch
        zcl_abapgit_services_git=>switch_branch( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-go_tag_overview.               " GIT Tag overview
        zcl_abapgit_services_git=>tag_overview( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-git_tag_create.                " GIT Tag create
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_tag
          EXPORTING
            io_repo = zcl_abapgit_repo_srv=>get_instance( )->get( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-git_tag_delete.                " GIT Tag create
        zcl_abapgit_services_git=>delete_tag( lv_key ).
        zcl_abapgit_services_repo=>refresh( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-git_tag_switch.                " GIT Switch Tag
        zcl_abapgit_services_git=>switch_tag( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
    ENDCASE.

  ENDMETHOD.


  METHOD jump_display_transport.

    DATA: lv_transport         TYPE trkorr,
          lv_transport_adt_uri TYPE string,
          lv_adt_link          TYPE string,
          lv_adt_jump_enabled  TYPE abap_bool.

    lv_transport = iv_getdata.

    lv_adt_jump_enabled = zcl_abapgit_persist_settings=>get_instance( )->read( )->get_adt_jump_enabled( ).
    IF lv_adt_jump_enabled = abap_true.
      TRY.
          CALL METHOD ('CL_CTS_ADT_TM_URI_BUILDER')=>('CREATE_ADT_URI')
            EXPORTING
              trnumber = lv_transport
            RECEIVING
              result   = lv_transport_adt_uri.
          lv_adt_link = |adt://{ sy-sysid }{ lv_transport_adt_uri }|.

          cl_gui_frontend_services=>execute( EXPORTING  document = lv_adt_link
                                             EXCEPTIONS OTHERS   = 1 ).
          IF sy-subrc <> 0.
            zcx_abapgit_exception=>raise( 'ADT Jump Error' ).
          ENDIF.
        CATCH cx_root.
          CALL FUNCTION 'TR_DISPLAY_REQUEST'
            EXPORTING
              i_trkorr = lv_transport.
      ENDTRY.
    ELSE.
      CALL FUNCTION 'TR_DISPLAY_REQUEST'
        EXPORTING
          i_trkorr = lv_transport.
    ENDIF.

  ENDMETHOD.


  METHOD other_utilities.

    CASE ii_event->mv_action.
      WHEN zif_abapgit_definitions=>c_action-changed_by.
        zcl_abapgit_services_basis=>test_changed_by( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
      WHEN zif_abapgit_definitions=>c_action-performance_test.
        zcl_abapgit_services_basis=>run_performance_test( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
    ENDCASE.

  ENDMETHOD.


  METHOD remote_origin_manipulations.

    DATA: lv_key TYPE zif_abapgit_persistence=>ty_repo-key.


    lv_key = ii_event->mv_getdata. " TODO refactor

    CASE ii_event->mv_action.
      WHEN zif_abapgit_definitions=>c_action-repo_remote_attach.            " Remote attach
        zcl_abapgit_services_repo=>remote_attach( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-repo_remote_detach.            " Remote detach
        zcl_abapgit_services_repo=>remote_detach( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-repo_remote_change.            " Remote change
        zcl_abapgit_services_repo=>remote_change( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
    ENDCASE.

  ENDMETHOD.


  METHOD repository_services.

    DATA: lv_url TYPE string,
          lv_key TYPE zif_abapgit_persistence=>ty_repo-key,
          li_log TYPE REF TO zif_abapgit_log.

    lv_key = ii_event->mv_getdata. " TODO refactor
    lv_url = ii_event->mv_getdata. " TODO refactor

    CASE ii_event->mv_action.
      WHEN zif_abapgit_definitions=>c_action-repo_newoffline.                 " New offline repo
        zcl_abapgit_services_repo=>new_offline( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-repo_add_all_obj_to_trans_req.
        zcl_abapgit_transport=>add_all_objects_to_trans_req( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-repo_refresh.                    " Repo refresh
        zcl_abapgit_services_repo=>refresh( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-repo_syntax_check.
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_syntax
          EXPORTING
            io_repo = zcl_abapgit_repo_srv=>get_instance( )->get( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-repo_code_inspector.
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_code_insp
          EXPORTING
            io_repo = zcl_abapgit_repo_srv=>get_instance( )->get( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-repo_purge.                      " Repo remove & purge all objects
        zcl_abapgit_services_repo=>purge( lv_key ).
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_main.
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page_replacing.
      WHEN zif_abapgit_definitions=>c_action-repo_remove.                     " Repo remove
        zcl_abapgit_services_repo=>remove( lv_key ).
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_main.
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page_replacing.
      WHEN zif_abapgit_definitions=>c_action-repo_newonline.
        rs_handled-page  = zcl_abapgit_gui_page_addonline=>create( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-repo_refresh_checksums.          " Rebuild local checksums
        zcl_abapgit_services_repo=>refresh_local_checksums( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-repo_toggle_fav.                 " Toggle repo as favorite
        zcl_abapgit_services_repo=>toggle_favorite( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-repo_transport_to_branch.
        zcl_abapgit_services_repo=>transport_to_branch( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
      WHEN zif_abapgit_definitions=>c_action-repo_settings.
        CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_repo_sett
          EXPORTING
            io_repo = zcl_abapgit_repo_srv=>get_instance( )->get( lv_key ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
      WHEN zif_abapgit_definitions=>c_action-repo_log.
        li_log = zcl_abapgit_repo_srv=>get_instance( )->get( lv_key )->get_log( ).
        zcl_abapgit_log_viewer=>show_log( ii_log = li_log
                                          iv_header_text = li_log->get_title( ) ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
    ENDCASE.

  ENDMETHOD.


  METHOD sap_gui_actions.

    DATA: ls_item TYPE zif_abapgit_definitions=>ty_item.

    CASE ii_event->mv_action.
      WHEN zif_abapgit_definitions=>c_action-jump.                          " Open object editor
        zcl_abapgit_html_action_utils=>jump_decode(
          EXPORTING iv_string   = ii_event->mv_getdata
          IMPORTING ev_obj_type = ls_item-obj_type
                    ev_obj_name = ls_item-obj_name ).
        zcl_abapgit_objects=>jump( ls_item ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.

      WHEN zif_abapgit_definitions=>c_action-jump_transport.
        jump_display_transport( ii_event->mv_getdata ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.

      WHEN zif_abapgit_definitions=>c_action-url.
        call_browser( ii_event->mv_getdata ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.

    ENDCASE.

  ENDMETHOD.


  METHOD zif_abapgit_gui_event_handler~on_event.


    rs_handled = general_page_routing( ii_event ).
    IF rs_handled-state IS INITIAL.
      rs_handled = repository_services( ii_event ).
    ENDIF.
    IF rs_handled-state IS INITIAL.
      rs_handled = git_services( ii_event ).
    ENDIF.
    IF rs_handled-state IS INITIAL.
      rs_handled = zip_services( ii_event ).
    ENDIF.
    IF rs_handled-state IS INITIAL.
      rs_handled = db_actions( ii_event ).
    ENDIF.
    IF rs_handled-state IS INITIAL.
      rs_handled = abapgit_services_actions( ii_event ).
    ENDIF.
    IF rs_handled-state IS INITIAL.
      rs_handled = remote_origin_manipulations( ii_event ).
    ENDIF.
    IF rs_handled-state IS INITIAL.
      rs_handled = sap_gui_actions( ii_event ).
    ENDIF.
    IF rs_handled-state IS INITIAL.
      rs_handled = other_utilities( ii_event ).
    ENDIF.

    IF rs_handled-state IS INITIAL.
      rs_handled-state = zcl_abapgit_gui=>c_event_state-not_handled.
    ENDIF.

  ENDMETHOD.


  METHOD zip_services.

    DATA: lv_key               TYPE zif_abapgit_persistence=>ty_repo-key,
          lo_repo              TYPE REF TO zcl_abapgit_repo,
          lv_package           TYPE devclass,
          lv_path              TYPE string,
          lv_xstr              TYPE xstring.

    " TODO refactor
    CONSTANTS:
      BEGIN OF lc_page,
        main_view TYPE string VALUE 'ZCL_ABAPGIT_GUI_PAGE_MAIN',
        repo_view TYPE string VALUE 'ZCL_ABAPGIT_GUI_PAGE_VIEW_REPO',
      END OF lc_page.

    lv_key = ii_event->mv_getdata. " TODO refactor

    CASE ii_event->mv_action.
      WHEN zif_abapgit_definitions=>c_action-zip_import.                      " Import repo from ZIP
        lo_repo = zcl_abapgit_repo_srv=>get_instance( )->get( lv_key ).
        lv_path = zcl_abapgit_ui_factory=>get_frontend_services( )->show_file_open_dialog(
          iv_title            = 'Import ZIP'
          iv_extension        = 'zip'
          iv_default_filename = '*.zip' ).
        lv_xstr = zcl_abapgit_ui_factory=>get_frontend_services( )->file_upload( lv_path ).
        lo_repo->set_files_remote( zcl_abapgit_zip=>load( lv_xstr ) ).
        zcl_abapgit_services_repo=>refresh( lv_key ).

        " TODO refactor how current page name is determined
        CASE ii_event->mi_gui_services->get_current_page_name( ).
          WHEN lc_page-repo_view.
            rs_handled-state = zcl_abapgit_gui=>c_event_state-re_render.
          WHEN lc_page-main_view.
            CREATE OBJECT rs_handled-page TYPE zcl_abapgit_gui_page_view_repo
              EXPORTING
                iv_key = lo_repo->get_key( ).
            rs_handled-state = zcl_abapgit_gui=>c_event_state-new_page.
          WHEN OTHERS.
            rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
        ENDCASE.
      WHEN zif_abapgit_definitions=>c_action-zip_export.                      " Export repo as ZIP
        lo_repo = zcl_abapgit_repo_srv=>get_instance( )->get( lv_key ).
        lv_xstr = zcl_abapgit_zip=>export( lo_repo ).
        file_download( iv_package = lo_repo->get_package( )
                       iv_xstr    = lv_xstr ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
      WHEN zif_abapgit_definitions=>c_action-zip_package.                     " Export package as ZIP
        zcl_abapgit_zip=>export_package( IMPORTING
          ev_xstr    = lv_xstr
          ev_package = lv_package ).
        file_download( iv_package = lv_package
                       iv_xstr    = lv_xstr ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
      WHEN zif_abapgit_definitions=>c_action-zip_transport.                   " Export transports as ZIP
        zcl_abapgit_transport_mass=>run( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
      WHEN zif_abapgit_definitions=>c_action-zip_object.                      " Export object as ZIP
        zcl_abapgit_zip=>export_object( ).
        rs_handled-state = zcl_abapgit_gui=>c_event_state-no_more_act.
    ENDCASE.

  ENDMETHOD.
ENDCLASS.
