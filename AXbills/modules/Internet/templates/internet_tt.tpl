<form action='$SELF_URL' method='POST'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='TP_ID' value='%TP_ID%'>
  <input type=hidden name='tt' value='%TI_ID%'>

  <fieldset>
    <div class='card card-primary card-outline col-md-6 container'>
      <div class='card-header with-border'><h4 class='card-title'>_{TRAFIC_TARIFS}_</h4></div>
      <div class='card-body'>

        <div class='form-group row'>
          <label class='control-label col-sm-3'>_{INTERVALS}_:</label>

          <div class='col-sm-9'>
            <label class='control-label'>%TI_ID%</label>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-sm-3' for='SEL_ID'>_{TRAFFIC_CLASS}_:</label>

          <div class='col-sm-9'>
            %SEL_TT_ID%
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-md-3' for='NETS_SEL'>_{NETWORKS}_:</label>

          <div class='col-md-9'>
            %NETS_SEL%
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-sm-3' for='PREPAID'>_{PREPAID}_</label>

          <div class='col-sm-8'>
            <input id='PREPAID' name='PREPAID' value='%PREPAID%' placeholder='%PREPAID%'
                   class='form-control' type='text'>
          </div>
          <label class='col-md-1 control-label' style='text-align: left; padding-left: 0'> Mb </label>
        </div>

        <div class='form-group row'>
          <label class='control-label col-sm-4' style='text-align: center;'>_{TRAFIC_TARIFS}_ (1 Mb):</label>

          <label class='control-label col-sm-1' for='IN_PRICE'>IN</label>

          <div class='col-sm-3'>
            <input id='IN_PRICE' name='IN_PRICE' value='%IN_PRICE%' placeholder='%IN_PRICE%'
                   class='form-control' type='text'>
          </div>

          <label class='control-label col-sm-1' for='OUT_PRICE'>OUT:</label>

          <div class='col-sm-3'>
            <input id='OUT_PRICE' name='OUT_PRICE' value='%OUT_PRICE%' placeholder='%OUT_PRICE%'
                   class='form-control' type='text'>
          </div>

        </div>

        <div class='form-group row'>
          <label class='control-label col-sm-4' for='IN_SPEED'>_{SPEED}_ (Kbits):</label>
          <label class='control-label col-sm-1' for='IN_SPEED'>IN</label>

          <div class='col-sm-3'>
            <input id='IN_SPEED' name='IN_SPEED' value='%IN_SPEED%' placeholder='%IN_SPEED%'
                   class='form-control' type='text'>
          </div>
          <label class='control-label col-sm-1' for='OUT_SPEED'>OUT:</label>

          <div class='col-sm-3'>
            <input id='OUT_SPEED' name='OUT_SPEED' value='%OUT_SPEED%' placeholder='%OUT_SPEED%'
                   class='form-control' type='text'>
          </div>
        </div>

        <div class='card card-primary card-outline collapsed-card'>
          <div class="card-header with-border">
            <h3 class="card-title">Burst Mode</h3>
            <div class="card-tools float-right">
              <button type="button" class="btn btn-tool" data-card-widget="collapse"  data-parent='#accordion' href='#burstModeCollapse'
                        aria-expanded='false' aria-controls='collapseOne'>
                <i class="fa fa-plus"></i>
              </button>
            </div>
          </div>
         <!-- <div id='burstModeCollapse' class='card-collapse collapse collapsing' role='tabpanel'
                 aria-labelledby='burstLimit'>-->
          <div  id='burstModeCollapse' class='card-body'>
                <p class='bg-info'>
                  Burst limit > _{SPEED}_</p>
                <p class='bg-info'>
                  Burst limit > Burst threshold
                </p>

                <div class='form-group row'>
                  <label class='control-label col-md-5' for='BURST_LIMIT_DL'>Burst limit,
                    kbps</label>

                  <div class='col-md-3'>
                    <input id='BURST_LIMIT_DL' name='BURST_LIMIT_DL' value='%BURST_LIMIT_DL%'
                           placeholder='%BURST_LIMIT_DL%'
                           class='form-control' type='text'>
                  </div>
                  <div class='col-md-1 control-label'>/</div>
                  <div class='col-md-3'>
                    <input id='BURST_LIMIT_UL' name='BURST_LIMIT_UL' value='%BURST_LIMIT_UL%'
                           placeholder='%BURST_LIMIT_UL%'
                           class='form-control' type='text'>
                  </div>
                </div>

                <div class='form-group row'>
                  <label class='control-label col-md-5' for='BURST_THRESHOLD_DL'>Burst threshold,
                    kbps</label>

                  <div class='col-md-3'>
                    <input id='BURST_THRESHOLD_DL' name='BURST_THRESHOLD_DL'
                           value='%BURST_THRESHOLD_DL%'
                           placeholder='%BURST_THRESHOLD_DL%' class='form-control' type='text'>
                  </div>
                  <div class='col-md-1 control-label'>/</div>
                  <div class='col-md-3'>
                    <input id='BURST_THRESHOLD_UL' name='BURST_THRESHOLD_UL'
                           value='%BURST_THRESHOLD_UL%'
                           placeholder='%BURST_THRESHOLD_UL%' class='form-control' type='text'>
                  </div>
                </div>

                <div class='form-group row'>
                  <label class='control-label col-md-5' for='BURST_TIME_DL'>Burst time,
                    _{SECONDS}_</label>

                  <div class='col-md-3'>
                    <input id='BURST_TIME_DL' name='BURST_TIME_DL' value='%BURST_TIME_DL%'
                           placeholder='%BURST_TIME_DL%'
                           class='form-control' type='text'>
                  </div>
                  <div class='col-md-1 control-label'>/</div>
                  <div class='col-md-3'>
                    <input id='BURST_TIME_UL' name='BURST_TIME_UL' value='%BURST_TIME_UL%'
                           placeholder='%BURST_TIME_UL%' class='form-control' type='text'>
                  </div>
                </div>
              </div>
            </div>

        <div class='form-group row'>
          <label class='control-label col-sm-3' for='DESCR'>_{DESCRIBE}_:</label>

          <div class='col-sm-9'>
            <input id='DESCR' name='DESCR' value='%DESCR%' placeholder='%DESCR%'
                   class='form-control' type='text'>
          </div>
        </div>

        <div class='form-group row'>
          <label class='control-label col-sm-3' for='EXPRESSION'>_{EXPRESSION}_:</label>

          <div class='col-md-9'>
                        <textarea class='form-control' id='EXPRESSION'
                                  name='EXPRESSION'>%EXPRESSION%</textarea>
          </div>

          <div class='form-group'>
          </div>

        </div>
        %DV_EXPPP_NETFILES%


      </div>
      <div class='card-footer'>
        %BACK_BUTTON% <input type=submit name=%ACTION% value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
      </div>
    </div>
    </div>

  </fieldset>

</form>

<script>
  // Check burst mode corectness
  const LESS    = 0;
  const GREATER = 1;

  function highlightInvalidCompared(id1, id2, boolean) {
    if (boolean) {
      jQuery('#' + id1).parents('.form-group').first().addClass('has-error');
      jQuery('#' + id2).parents('.form-group').first().addClass('has-error');
    }
    else {
      jQuery('#' + id1).parents('.form-group').first().removeClass('has-error');
      jQuery('#' + id2).parents('.form-group').first().removeClass('has-error')
    }
  }

  function initInputCompare(input1, input2, constraint) {
    var compare = (constraint == LESS)
        ? function (this_value, compared_val) { return (this_value >= compared_val) }
        : function (this_value, compared_val) { return (this_value < compared_val) };

    input1.on('input', function () {
      var this_value   = Number(input1.val());
      var compared_val = Number(input2.val());
      highlightInvalidCompared(input1.attr('id'), input2.attr('id'), compare(this_value, compared_val));
    });

    input2.on('input', function () {
      var this_value   = Number(input2.val());
      var compared_val = Number(input1.val());
      highlightInvalidCompared(input2.attr('id'), input1.attr('id'), !compare(this_value, compared_val));
    });
  }

  //  Speed < Burst limit
  //  Threshold < Burst limit
  var speed_in  = jQuery('#IN_SPEED');
  var speed_out = jQuery('#OUT_SPEED');

  var burstModeCollapse = jQuery('#burstModeCollapse');

  var b_limit_in  = burstModeCollapse.find('#BURST_LIMIT_DL');
  var b_limit_out = burstModeCollapse.find('#BURST_LIMIT_UL');

  var b_tres_in  = burstModeCollapse.find('#BURST_THRESHOLD_DL');
  var b_tres_out = burstModeCollapse.find('#BURST_THRESHOLD_UL');

  burstModeCollapse.on('shown.bs.collapse', function () {
    initInputCompare(speed_in, b_limit_in, LESS);
    initInputCompare(b_tres_in, b_limit_in, LESS);

    initInputCompare(speed_out, b_limit_out, LESS);
    initInputCompare(b_tres_out, b_limit_out, LESS);
  });

  burstModeCollapse.on('hidden.bs.collapse', function () {
    speed_in.off('input');
    speed_out.off('input');
    b_limit_in.off('input');
    b_limit_out.off('input');
    b_tres_in.off('input');
    b_tres_out.off('input');
  })

</script>
