/**
 * Created by Anykey on 09.09.2015.
 */
'use strict';
$(function () {
  var SPINNER = "<i class=\"fa fa-spinner fa-pulse\"></i>";

  $('div.form-address').each(function (i, form) {
    var $form = $(form);

    // Check it was already init
    if ($form.data('init')) {
      return true;
    }

    $form.data('init', true);
    var $MUTABLE_SELECTS = $form.find("select[data-download-on-click=\"1\"]");

    var $street_select     = $form.find("select.SELECT-STREET");
    var $streets_input_div = $street_select.next('div');

    // Loading districts needs special behaviour to save previous value;
    var loadDistricts = function () {
      var $districts_label = $form.find("label.LABEL-DISTRICT");
      var $district_select = $form.find("select.SELECT-DISTRICT");

      var currentDistrict = $district_select.val() || false;

      //append_spinner
      $districts_label.append(SPINNER);

      //AJAX get
      $.get(SELF_URL, 'qindex=30&address=1', function (data) {
        $district_select.html(data);

        var $options = $district_select.find('option');

        currentDistrict
          ? renewChosenValue($district_select, currentDistrict)
          : updateChosen();

        // If has only one district, should load all streets  for this district
        if ($options.length === 2) {
          var value = $options[1].value;
          renewChosenValue($district_select, value);

          $streets_input_div.off('click', loadStreetsWithoutDistricts);
          loadList('STREET', 'DISTRICT_ID', value);
        }
      }).done(function () {
        $districts_label.find('i.fa').remove();
      });

    };

    var loadList = function (elem_id, param, value) {
      var $select = $form.find('select.SELECT-' + elem_id);
      var $label  = $form.find('label.LABEL-' + elem_id);
      //append_spinner
      $label.append(SPINNER);

      var currentValue = $select.val();

      //AJAX get
      var params = 'qindex=30&address=1&' + param + '=' + value;

      $.get(SELF_URL, params, function (data) {
          $select.empty().html(data);
          $select.prop('disabled', false);
          $select.data('loaded', 1);

          if (typeof currentValue !== 'undefined') {
            renewChosenValue($select, currentValue)
          }
          else {
            updateChosen();
          }
        })
        .done(function () {
          $label.find('i.fa').remove();
        });
    };

    var loadNext = function (elem_id) {
      switch (elem_id) {
        case 'DISTRICT':
          //load streets
          loadList('STREET', 'DISTRICT_ID', getValue('DISTRICT'));
          break;
        case 'STREET':
          //load builds
          loadList('BUILD', 'STREET_ID', getValue('STREET'));
          break;
      }
    };

    var clearNext = function (id) {

      switch (id) {
        case 'DISTRICT':
          //enable streets
          clearSelect('STREET');
          clearSelect('BUILD');
          break;
        case 'STREET':
          //enable builds
          clearSelect('BUILD');
          break;
      }
    };

    var getValue = function (elem_id) {
      return $form.find('input.HIDDEN-' + elem_id).val();
    };

    var getSelect = function (elem_id) {
      return $form.find('select.SELECT-' + elem_id);
    };

    var clearSelect = function (elem_id) {
      getSelect(elem_id).val('')
        .select2(CHOSEN_PARAMS)
        .prop('disabled', true)
        .trigger("select2:updated");

      $form.find('input.HIDDEN-' + elem_id).val('');

      //TODO: check and remove
      //if (elem_id == 'BUILD') {
      //  $form.find('#LOCATION_ID').val('');
      //}
    };

    var loadStreetsWithoutDistricts = function () {
      var district_id = getValue('DISTRICT');
      if (
        /// District is not chosen or there's no necessary to choose ( single option )
      district_id === '' || getSelect('DISTRICT').find('option').length <= 2
      ||
      // Streets where not loaded before
      !getSelect('STREET').data('loaded')
      ) {
        loadList('STREET', 'DISTRICT_ID', (district_id === '') ? '*' : district_id);
      }
    };

    var loadBuildsIfStreetSelected = function(){
      var street_id = getValue('STREET');
      // Builds where not loaded before
      if (street_id !== '' && !getSelect('BUILD').data('loaded') ) {
        loadNext('STREET')
      }
    };

    var initFlatForBuildCheckLogic = function () {
      var CHECK_FREE     = document['FLAT_CHECK_FREE'] !== "0";
      var CHECK_OCCUPIED = document['FLAT_CHECK_OCCUPIED'] !== "0";

      if (!(CHECK_FREE || CHECK_OCCUPIED)) {
        return true;
      }

      var $flat_input        = $form.find('input.INPUT-FLAT');
      var $flat_input_holder = $flat_input.parents('.form-group').first();
      var current_checker    = null;

      var initialized = false;

      Events.on('BUILD_SELECTED' + i, function (build_id) {

        if (!build_id) {
          return false;
        }

        //Load all flats for build_id
        $.get(SELF_URL, 'qindex=30&address=1&LOCATION_ID=' + build_id, function (data) {

          try {
            var flats       = JSON.parse(data);
            current_checker = new FlatInputChecker(initialized, $flat_input, $flat_input_holder, flats, CHECK_FREE, CHECK_OCCUPIED);
          }
          catch (JsonParseException) {
            (new ATooltip).displayError(JsonParseException);
            console.warn(JsonParseException);
          }
        });
      })
    };

    var initAddBuildMenu = function () {

      $form.find('a.BUTTON-ENABLE-ADD').click(function (e) {
        e.preventDefault();
        $form.find('.addBuildMenu').hide();
        $form.find('.changeBuildMenu').show();
      });
      $form.find('a.BUTTON-ENABLE-SEL').click(function (e) {
        e.preventDefault();
        $form.find('.addBuildMenu').show();
        $form.find('.changeBuildMenu').hide();
      });
    };

    //Register onClick handlers;
    $MUTABLE_SELECTS.on('change', function () {
      var $select = $(this);
      var value   = $select.val();

      //update hidden
      var name = $select.data('fieldname');
      $form.find('input.HIDDEN-' + name).val(value);

      Events.emit(name + '_SELECTED' + i, value);

      // TODO: check and remove
      //if (id == 'BUILD') {
      //  $('#LOCATION_ID').val(value);
      //  Events.emit('buildselected', value);
      //}

      clearNext(name);
      loadNext(name);
    });

    //Allow loading streets before districts
    $streets_input_div.on('click', loadStreetsWithoutDistricts);

    // Allow change of build only
    getSelect('BUILD').next('div').on('click', loadBuildsIfStreetSelected);

    loadDistricts();
    initAddBuildMenu();

    initFlatForBuildCheckLogic();

    var $location_id_input = $form.find('input.HIDDEN-BUILD');
    var $add_address_input = $form.find('input.INPUT-ADD-BUILD');

    $form.on('submit', function () {

      if ($add_address_input.val()) {
        $location_id_input.val('');

        // Need to send street
        return true;
      }

      // If got half of data, invalidate all
      if (!$location_id_input.val()) {
        $MUTABLE_SELECTS.val('');
      }

    })

  });


  function FlatInputChecker(initialized, $flat_input, $flat_input_holder, flats, CHECK_FREE, CHECK_OCCUPIED) {

    // Starting check process
    $flat_input.on('input', check_input_value);

    // Dismissing check if new build selected
    Events.on('buildselected', function () {
      $flat_input.off('input');
      $flat_input.popover('destroy');
    });

    function check_input_value() {
      var flat = this.value;
      if (typeof (flats[flat]) !== 'undefined') {
        show_occupied(flats[flat]);
      }
      else {
        hide_occupied();
      }
    }

    function show_occupied(user) {
      CHECK_FREE ? $flat_input_holder.addClass('has-error') : '';
      CHECK_OCCUPIED ? $flat_input_holder.addClass('has-success') : '';

      var content = '<a href="?index=15&UID=' + user.uid + '" target="_blank">' + user.user_name + '</a>';
      if (!initialized) {
        $flat_input.popover({
          'content'  : content,
          'html'     : true,
          'placement': 'top'
        });
        initialized = true;
      }
      else {
        $flat_input.attr('data-content', content).data('bs.popover').setContent();
      }

      $flat_input.popover('show');
    }

    function hide_occupied() {
      CHECK_FREE ? $flat_input_holder.removeClass('has-error') : '';
      CHECK_OCCUPIED ? $flat_input_holder.removeClass('has-success') : '';
      $flat_input.popover('hide');
    }

  }
});
