<!DOCTYPE html>
<html>
<head>
    %REFRESH%
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <meta http-equiv='X-UA-Compatible' content='IE=edge'>

    <title>%TITLE%</title>

    <!-- CSS -->
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/bootstrap.min.css'>
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/currencies.css'>
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/tcal.css'>
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/chosen.min.css'>
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/jquery.arcticmodal-0.3.css'>
    %COLORS%
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/style.css'>
    <link rel='stylesheet' type='text/css' href='/styles/%HTML_STYLE%/css/font-awesome.min.css'>


    <!-- Bootstrap -->
    <script src='/styles/%HTML_STYLE%/js/jquery.min.js'></script>
    <script src='/styles/%HTML_STYLE%/js/bootstrap.min.js'></script>
    <!-- Cookies from JavaScript -->
    <script  src='/styles/%HTML_STYLE%/js/js.cookies.js'></script>
    <script  src='/styles/%HTML_STYLE%/js/permanent_data.js'></script>
    <!-- temp -->
    <script src='/styles/%HTML_STYLE%/js/functions.js'></script>
    <script src='/styles/%HTML_STYLE%/js/functions-admin.js'></script>
    <script src='/styles/%HTML_STYLE%/js/keys.js'></script>
    <script src='/styles/%HTML_STYLE%/js/timepicker.js'></script>
    <!-- Navigation bar saving show/hide state -->
    <script src='/styles/%HTML_STYLE%/js/navBarCollapse.js'></script>
    <!-- Custom calendar -->
    <script  src='/styles/%HTML_STYLE%/js/tcal.js'></script>
    <!-- Custom <select> design -->
    <script  src='/styles/%HTML_STYLE%/js/chosen.jquery.min.js'></script>
    <script  src='/styles/%HTML_STYLE%/js/QBinfo.js'></script>
    <script  src='/styles/%HTML_STYLE%/js/events.js'></script>
    <!-- Modal popup windows management -->
    <script  src='/styles/%HTML_STYLE%/js/modals.js'></script>
    <!-- AJAX Search scripts -->
    <script  src='/styles/default_adm/js/search.js'></script>
    <script  src='/styles/default_adm/js/messageChecker.js'></script>
    <script  src='/styles/default_adm/js/admin_breadcrumbs.js'></script>
    <script>
        var SELF_URL = '$SELF_URL';
        var INDEX = '$index';
        var _COMMENTS_PLEASE = '_{COMMENTS_PLEASE}_' || 'Comment please';
        document['WEBSOCKET_URL'] = '$conf{WEBSOCKET_URL}';

        //CHOSEN INIT PARAMS
        var CHOSEN_PARAMS = {
            no_results_text: '_{NOT_EXIST}_',
            allow_single_deselect: true,
            placeholder_text: '--'
        };

        jQuery(function () {
            jQuery('select:not(#type)').chosen(CHOSEN_PARAMS);
        });

    </script>

  <!--Needs WEBSOKET_URL defined above-->
  <script  src='/styles/default_adm/js/websocket_client.js'></script>

</head>
<body>
<div class='container-fluid'>
    %CALLCENTER_MENU%

    <div class='modal fade' id='comments_add' tabindex='-1' role='dialog'>
        <form id='mForm'>
            <div class='modal-dialog modal-sm'>
                <div class='modal-content'>
                    <div id='mHeader' class='modal-header'>
                        <button type='button' class='close' data-dismiss='modal' aria-hidden='true'>&times;</button>
                        <h4 id='mTitle' class='modal-title'>&nbsp;</h4>
                    </div>
                    <div class='modal-body'>
                        <div class='row'>
                            <input type='text' class='form-control' id='mInput' placeholder='_{COMMENTS}_'>
                        </div>
                    </div>
                    <div class='modal-footer'>
                        <button type='button' class='btn btn-secondary' data-dismiss='modal'>_{CANCEL}_</button>
                        <button type='submit' class='btn btn-danger danger' id='mButton'>_{EXECUTE}_!</button>
                    </div>
                </div>
            </div>
        </form>
    </div>

    <!-- Modal search -->
    <div class='modal fade' tabindex='-1' id='PopupModal' role='dialog' aria-hidden='true'>
        <div class='modal-dialog'>
            <div id='modalContent' class='modal-content'></div>
        </div>
    </div>

    <div class='modal fade' id='quickMenuModal' tabindex='-1' role='dialog'>
        <div class='modal-dialog' role='document'>
            <div class='modal-content'>
                <div class='modal-header'>
                    <button type='button' class='close' data-dismiss='modal'
                            aria-label='Close'><span aria-hidden='true'>&times;</span></button>
                </div>
                <div class='modal-body'>
                    <div class='btn-group-vertical' style='background: none'>
                        <a href='$SELF_URL?index=99' class='btn btn-secondary btn-xs'><span
                                class='fa fa-plus'></span> </a>
                        %QUICK_MENU%
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class='modal fade' id='searchMenuModal' tabindex='-1' role='dialog'>
        <div class='modal-dialog' role='document'>
            <div class='modal-content'>
                <div class='modal-header'>
                    <button type='button' class='close' data-dismiss='modal'
                            aria-label='Close'><span aria-hidden='true'>&times;</span></button>
                </div>
                <div class='modal-body'>
                    <div class='row'>
                        <form action='$SELF_URL'>
                            <input type='hidden' name='index' value='7'>
                            <input type='hidden' name='search' value='1'>
                            %SEL_TYPE%

                            <input class='form-control input-sm UNIVERSAL_SEARCH' type='text' name='LOGIN' value=''
                                   placeholder='_{SEARCH}_'>

                            <button class='btn btn-primary btn-sm pull-right' type='submit'>
                                <span class='fa fa-search'></span>
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <!-- -->
    <!--This div is used to get row-highlight background color-->
    <div class='bg-success' style='display: none'></div>



    <!-- -->

