<!--<style>
    #_main {
        min-height: 250px;
    }

    #_address {
        min-height: 250px;
    }

    #_comment {
        min-height: 150px;
    }
</style>-->

<form class='form-horizontal' action='$SELF_URL' name='users_pi' METHOD='POST' ENCTYPE='multipart/form-data'>

    <input type='hidden' name='index' value='$index'>
    %MAIN_USER_TPL%
    <input type=hidden name=UID value='%UID%'>

    <!-- General panel -->
    <div class='card card-primary card-outline box-big-form'>
        <div class='card-header with-border'><h3 class="card-title">_{INFO}_</h3>
            <div class="card-tools float-right">
                <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse"><i class="fa fa-minus"></i>
                </button>
                <button type="button" class="btn btn-secondary btn-xs" data-card-widget="remove"><i class="fa fa-times"></i></button>
            </div>
        </div>
    <div class='nav-tabs-custom box-big-form box-body' style="padding: 0">
        <div class='visible-xs'>%HEADER2%</div>
        <div class='hidden-xs'>%HEADER%</div>
        <div class="tab-content user_pi">
            <div class="tab-pane active" id="_user_main">
                <div class='form-group'>
                    <label class='control-label col-xs-4' for='FIO'>_{FIO}_</label>
                    <div class='col-xs-8'>
                        <input name='FIO' class='form-control' rows='1' id='FIO' value='%FIO%'>
                    </div>
                </div>

                %ACCEPT_RULES_FORM%

                <div class='form-group'>

                    <label class='control-label col-xs-4 col-md-2' for='PHONE'>_{PHONE}_</label>
                    <div class='col-xs-8 col-md-4'>
                        <div class="input-group">
                            <input id='PHONE' name='PHONE' value='%PHONE%' placeholder='%PHONE%'
                                   class='form-control' type='text'
                                   data-inputmask='"mask": "(999) 999-9999"' data-mask>

                            <div class="input-group-addon">
                                <i class="fa fa-phone"></i>
                            </div>
                        </div>
                    </div>
                    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 10px"> </span>
                    <label class='control-label col-xs-4 col-md-2' for='EMAIL'>E-mail (;)</label>
                    <div class='col-xs-8 col-md-4'>
                        <div class='input-group'>
                            <input id='EMAIL' name='EMAIL' value='%EMAIL%' placeholder='%EMAIL%'
                                   class='form-control' type="email">
                    <span class='input-group-addon'>
                    <a href='$SELF_URL?UID=$FORM{UID}&get_index=msgs_admin&add_form=1&SEND_TYPE=1&header=1&full=1'
                       class='fa fa-envelope'></a>
                    </span>
                        </div>
                    </div>
                </div>
                <line class="visible-xs visible-sm dashed"></line>
                <div class='form-group'>
                    <label class='control-label col-xs-4 col-md-2' for='CONTRACT_ID'>_{CONTRACT_ID}_ %CONTRACT_SUFIX%</label>
                    <div class='col-xs-8 col-md-4'>
                        <div class='input-group'>
                            <input id='CONTRACT_ID' name='CONTRACT_ID' value='%CONTRACT_ID%'
                                   placeholder='%CONTRACT_ID%' class='form-control' type='text'>
                            <div class='input-group-btn'>
                                <button type='button' class='btn btn-secondary dropdown-toggle'
                                        data-toggle='dropdown'
                                        aria-expanded='false'><span class='caret'></span></button>
                                <ul class='dropdown-menu dropdown-menu-right' role='menu'>
                                    <li><span class='input-group-addon'>%PRINT_CONTRACT%</span></li>
                                    <li><span class='input-group-addon'><a
                                            href='$SELF_URL?qindex=15&UID=$FORM{UID}&PRINT_CONTRACT=%CONTRACT_ID%&SEND_EMAIL=1&pdf=1'
                                            class='fa fa-envelope' target=_new>
                                    </a></span></li>
                                </ul>
                            </div>
                        </div>
                    </div>
                    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"> </span>
                    <label class='control-label col-xs-4 col-md-2' for='CONTRACT_DATE'>_{DATE}_</label>
                    <div class='col-xs-8 col-md-4'>
                        <input id='CONTRACT_DATE' type='text' name='CONTRACT_DATE'
                               value='%CONTRACT_DATE%' class='datepicker form-control'>
                    </div>
                </div>
                <line class="visible-xs visible-sm dashed"></line>
                %CONTRACT_TYPE%

            </div>

            <!-- Address panel -->
            <div class="tab-pane" id="_address">
                %ADDRESS_TPL%
            </div>

            <!-- Pasport panel -->
            <div class="tab-pane" id="_pasport">

                <div class='form-group'>
                    <!-- <label class='col-md-12 bg-primary'>_{PASPORT}_</label> -->
                    <label class='control-label col-xs-4 col-md-2' for='PASPORT_NUM'>_{NUM}_</label>
                    <div class='col-xs-8 col-sm-4'>
                        <input id='PASPORT_NUM' name='PASPORT_NUM' value='%PASPORT_NUM%'
                               placeholder='%PASPORT_NUM%'
                               class='form-control' type='text'>
                    </div>
                    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 10px"> </span>
                    <label class='control-label col-xs-4 col-md-2' for='PASPORT_DATE'>_{DATE}_</label>
                    <div class='col-xs-8 col-sm-4'>
                        <input id='PASPORT_DATE' type='text' name='PASPORT_DATE' value='%PASPORT_DATE%'
                               class='datepicker form-control'>
                    </div>
                </div>
                <div class='form-group'>
                    <label class='control-label col-xs-4 col-md-2' for='PASPORT_GRANT'>_{GRANT}_</label>
                    <div class='col-xs-8 col-md-10'>
                    <textarea class='form-control' id='PASPORT_GRANT' name='PASPORT_GRANT'
                              rows='2'>%PASPORT_GRANT%</textarea>
                    </div>
                </div>
            </div>


            <!-- comment panel -->
            <div class="tab-pane" id="_comment">
                <div class='form-group'>
                    <label class='control-label col-sm-2' for='COMMENTS'>_{COMMENTS}_</label>
                    <div class='col-sm-10'>
                                    <textarea class='form-control' id='COMMENTS' name='COMMENTS'
                                              rows='3'>%COMMENTS%</textarea>
                    </div>
                </div>
            </div>
            <!-- info fields + contacts panel -->
            <div class="tab-pane" id="__other">
                %INFO_FIELDS%
            </div>
            <div class="tab-pane" id="_contacts_content">
                %CONTACTS%
            </div>

        </div>
        <div class='card-footer'>
            <input type=submit class='btn btn-primary' name='%ACTION%' value='%LNG_ACTION%'>
        </div>
    </div>
</div>
</form>

