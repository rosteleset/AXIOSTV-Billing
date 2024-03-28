<div class='card'>
  <div class='card-header'><h4 class='card-title'>_{CONNECT_BY_NUMBER}_</h4></div>
  <div class='card-body'>

    <div class='form-group' id='cables_chooser'>
      <p>_{CHOOSE}_ _{CABLES}_</p>
      <div class='col-md-12'>
        <label for='CABLE_1'>
          %CABLE_1_SELECT%
        </label>
      </div>
      <div class='col-md-12'>
        <label for='CABLE_2'>
          %CABLE_2_SELECT%
        </label>
      </div>
    </div>

    <div class='form-group' id='fibers_chooser'>
      <!--<div class='row' id='fibers_chooser' style="display: none">-->
      <p>_{CHOOSE}_ _{FIBERS}_</p>

      <div class="col-md-6">
        <div class="col-md-5">
          <label for="cable_1_start">
            <select class="form-control" name="cable_1_start" id="cable_1_start"></select>
          </label>
        </div>
        <div class="col-md-2">-</div>
        <div class="col-md-5">
          <label for="cable_1_end">
            <select class="form-control" name="cable_1_end" id="cable_1_end"></select>
          </label>
        </div>
      </div>

      <div class="col-md-6">
        <div class="col-md-5">
          <label for="cable_2_start">
            <select class="form-control" name="cable_2_start" id="cable_2_start"></select>
          </label>
        </div>
        <div class="col-md-2">-</div>
        <div class="col-md-5">
          <label for="cable_2_end">
            <select class="form-control" readonly="readonly" name="cable_2_end" id="cable_2_end"></select>
          </label>
        </div>
      </div>

    </div>


  </div>
  <div class='card-footer'>
    <button type='button' class='btn btn-secondary' data-dismiss='modal'>_{CANCEL}_</button>
    <button type='button' class='btn btn-primary' id='connect_by_numbers_btn'>_{CONNECT}_</button>
  </div>
</div>

<script>
  jQuery(function () {

    var cables_chooser = jQuery('div#cables_chooser');
    var select_1       = cables_chooser.find('select#CABLE_1');
    var select_2       = cables_chooser.find('select#CABLE_2');

    var fibers_chooser = jQuery('div#fibers_chooser');
    var cable_1        = {
      fiber_start: fibers_chooser.find('select#cable_1_start'),
      fiber_end  : fibers_chooser.find('select#cable_1_end')
    };

    var cable_2 = {
      fiber_start: fibers_chooser.find('select#cable_2_start'),
      fiber_end  : fibers_chooser.find('select#cable_2_end')
    };

    var connect_fibers_btn = jQuery('button#connect_by_numbers_btn');
    connect_fibers_btn.off('click');

    function getFibersCountFor(cable_id) {
      var cable = ACommutation.getElementByTypeAndId('CABLE', cable_id);
      return cable.fibers.length;
    }

    function insertNumericOptions(select, count, selected) {
      select.empty();
      for (var i = 1; i <= count; i++) {
        var sel = '';
        if (selected && i === selected) {
          sel = ' selected="selected" ';
        }
        select.append('<option value="' + i + '"' + sel + '>' + i + '</option>');
      }
    }


    function updateFibersCountFor(fibers_selects) {
      return function () {
        var select   = jQuery(this);
        var cable_id = select.val();

        var fibers_count = getFibersCountFor(cable_id);

        insertNumericOptions(fibers_selects['fiber_start'], fibers_count, 1);
        insertNumericOptions(fibers_selects['fiber_end'], fibers_count, fibers_count);

        updateChosen();
      };
    }

    function setCorrespondingOption(this_fibers_select, that_fibers_select) {
      // Get this range
      var start1 = +this_fibers_select['fiber_start'].val();
      var end1   = +this_fibers_select['fiber_end'].val();

      var this_range = end1 - start1;

      // Get that start
      var start2 = +that_fibers_select['fiber_start'].val();

      console.log(this_range, start2);

      // Set second end to (start + range)
      renewChosenValue(that_fibers_select['fiber_end'], start2 + this_range);
    }

    function alignSelectRanges(this_select, that_select) {
      return function () {
        setCorrespondingOption(this_select, that_select);
      }
    }

    jQuery(select_1).on('change', updateFibersCountFor(cable_1));
    jQuery(select_2).on('change', updateFibersCountFor(cable_2));
    updateFibersCountFor(cable_1).bind(select_1)();
    updateFibersCountFor(cable_2).bind(select_2)();

    cable_1.fiber_end.on('change', alignSelectRanges(cable_1, cable_2));
    cable_2.fiber_start.on('change', alignSelectRanges(cable_1, cable_2));
    cable_2.fiber_end.on('change', alignSelectRanges(cable_2, cable_1));

    connect_fibers_btn.on('click', function () {
      aModal.hide();
      ACommutationControls.connectTwoCablesByNumbers({
        cable_1_id: +select_1.val(),
        cable_2_id: +select_2.val(),

        cable_1_start: +cable_1['fiber_start'].val(),
        cable_1_end  : +cable_1['fiber_end'].val(),
        cable_2_start: +cable_2['fiber_start'].val(),
        cable_2_end  : +cable_2['fiber_end'].val()
      });
    })

  });
</script>