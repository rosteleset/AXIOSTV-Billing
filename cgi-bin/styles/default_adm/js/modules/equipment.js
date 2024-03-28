/**
 * Created by Anykey on 24.02.2016.
 *
 *   Javascript functions for Equipment/templates/equipment_model.tpl
 *
 */

$(function () {
  //cache DOM
  var $form = $('#EQUIPMENT_MODEL_INFO_FORM');

  var $rowsNumInput = $form.find('#ROWS_COUNT_id');
  var $portsNumInput = $form.find('#PORTS');

  var $hasExtraPortsInput = $('#HAS_EXTRA_PORTS');

  var $wrapper = $('#extraPortWrapper');
  var $controls = $('#extraPortControls');

  var $addBtn = $controls.find('#addPortBtn');
  var $remBtn = $controls.find('#removePortBtn');

  var $portShiftInput = $('#PORT_SHIFT');
  var $autoPortShiftCheckbox = $('#AUTO_PORT_SHIFT');

  var $templateSelectWrapper = $wrapper.find('#templateWrapper');
  var $portTypeOptions = $templateSelectWrapper.find('option');

  $templateSelectWrapper.remove();

  //Misc variables
  var portTypes = ['', 'RJ45', 'GBIC', 'Gigabit', 'SFP', 'QSFP', 'EPON', 'GPON'];

  var portCounter = 0;

  var extraPorts = {};
  var portsComboBusy = {};

  var comboPortSelect2Params = Object.assign({}, CHOSEN_PARAMS, { allowClear: 1, placeholder: '' });

  var portTypesHTML = '';
  $.each($portTypeOptions, function (i, option) {
    portTypesHTML += option.outerHTML;
  });

  //bind Events
  $addBtn.on('click', function (e) {
    e.preventDefault();
    addNewPortSelect();
  });

  $remBtn.on('click', function (e) {
    e.preventDefault();
    removeLastPort();
  });

  $form.on('submit', function () {
    if (portCounter > 0) {
      $hasExtraPortsInput.val(portCounter);
    }
  });

  $rowsNumInput.on('change', function() {
    var rowsNum = $(this).val();
    if (typeof(rowsNum) !== 'undefined' && rowsNum > 0){
      $('.extraPortRow').attr('max', rowsNum);
    }
  });

  $autoPortShiftCheckbox.on('click', function (e) {
    $portShiftInput.prop('disabled', $autoPortShiftCheckbox.prop('checked') );
  });

  $('#TYPE_ID').on('change', function (e) {
    var type = $(this).val();

    $('#equipmentModelPon').prop('hidden', type != 4); // 4 - PON
    $('#EPON_SUPPORTED_ONUS').prop('disabled', type != 4);
    $('#GPON_SUPPORTED_ONUS').prop('disabled', type != 4);
    $('#GEPON_SUPPORTED_ONUS').prop('disabled', type != 4);
  });

  $('#VENDOR_ID').on('change', function (e) {
    var vendor_id = $(this).val();

    $('#equipmentModelZte').prop('hidden', vendor_id != 12); // 12 - ZTE
    $('#DEFAULT_ONU_REG_TEMPLATE_EPON').prop('disabled', vendor_id != 12);
    $('#DEFAULT_ONU_REG_TEMPLATE_GPON').prop('disabled', vendor_id != 12);
  });

  $portsNumInput.on('change', function(){
    updateExtraPortsComboSelects();
  });

  $('#PORTS_TYPE').on('change', function(){
    updateExtraPortsComboSelects();
  });

  $portShiftInput.prop('disabled', $autoPortShiftCheckbox.prop('checked') );

  fillExistingPorts($('#extraPortsJson').val());

  function addNewPortSelect() {
    $wrapper.append(getNewExtraPortGroup(++portCounter));
    extraPorts[portCounter] = { portType: 1 }; // 1 - RJ45
    $.each(extraPorts, function(number, extraPort) {
      var $extraPortComboSelect = $('#EXTRA_PORT_COMBO_' + number);
      var thisPortType = extraPort["portType"];

      if (thisPortType != 1) {
        $extraPortComboSelect.append('<option value="' + portCounter + '"> e' + portCounter + ' (' + portTypes[1] + ')' + '</option>');
      }
    });
    updateExtraPortsComboSelects(portCounter);
  }

  function removeLastPort() {
    var wasComboWithPortNumber = extraPorts[portCounter]['combo'];
    if (wasComboWithPortNumber > 0) {
      extraPorts[wasComboWithPortNumber]['combo'] = null;
      $('#EXTRA_PORT_COMBO_' + wasComboWithPortNumber).val('').change();
    }
    else if (wasComboWithPortNumber < 0) {
      delete portsComboBusy[wasComboWithPortNumber];
    }

    delete extraPorts[portCounter];
    $.each(extraPorts, function(number, extraPort) {
      var $extraPortComboSelect = $('#EXTRA_PORT_COMBO_' + number);
      $extraPortComboSelect.find('option[value=' + portCounter + ']').remove();
      $extraPortComboSelect.val(extraPort['combo']);
    });

    $('#EXTRA_PORT_' + portCounter--).remove();
  }

  function fillExistingPorts(jsonString) {
    try {
      if (typeof(jsonString) !== 'undefined' && jsonString.length > 0) {
        var ports = JSON.parse(jsonString);
        $.each(ports, function (index, port) {
          appendPort(port);
        })
        updateExtraPortsComboSelects();
      }

    } catch (Error) {
      console.log(jsonString);
      alert("[ Equipment.js ] Error parsing existing ports : " + Error);
    }

    function appendPort(port) {
      if (!port.hasOwnProperty('portNumber')) return;

      var portNumber    = port.portNumber;
      var rowNumber     = port.rowNumber;
      var portType      = port.portType || 1;
      var portComboWith = port.portComboWith;

      extraPorts[portNumber] = { "portType": portType, "combo": portComboWith };
      if (portComboWith < 0) {
        portsComboBusy[portComboWith] = portNumber;
      }

      $wrapper.append(getNewExtraPortGroup(portNumber, rowNumber, portType));

      if (portNumber > portCounter) portCounter = portNumber;
    }
  }

  function updateExtraPortsComboSelects(number) {
    var portsCount = $portsNumInput.val();
    var portType = $('#PORTS_TYPE option:selected').val();
    var extraPortComboSelectBasePortsHTML = '';
    for (var i = 1; i <= portsCount; i++) {
      extraPortComboSelectBasePortsHTML += '<option value="-' + i + '">' + i + ' (' + portTypes[portType] + ')' + '</option>';
    }

    if (number) {
      updateExtraPortComboSelect(number, extraPorts[number]);
    }
    else {
      $.each(extraPorts, function(number, extraPort) {
        updateExtraPortComboSelect(number, extraPort);
      });
    }

    function updateExtraPortComboSelect(number, extraPort) {
      var $extraPortComboSelect = $('#EXTRA_PORT_COMBO_' + number);

      var thisPortType = extraPort["portType"];

      var extraPortComboSelectHTML = '';
      if (thisPortType != portType) {
        extraPortComboSelectHTML = extraPortComboSelectBasePortsHTML;
      }

      $.each(extraPorts, function(number, extraPort){
        if (extraPort["portType"] != thisPortType) { //XXX may have list what port types can be combo, e. g. no need to have RJ45 <-> Gigabit combo
          extraPortComboSelectHTML  += '<option value="' + number + '"> e' + number + ' (' + portTypes[extraPort["portType"]] + ')' + '</option>';
        }
      });

      $extraPortComboSelect.html(extraPortComboSelectHTML);
      $extraPortComboSelect.val(extraPort['combo']);
    }
  }

  function getNewExtraPortGroup(number, rowNumber, portType) {
    rowNumber = rowNumber || 0;
    portType = portType || 1;

    var $extraPortGroup = $('<div class="form-group row" id="EXTRA_PORT_' + number + '">' +
        '<label class="col-md-4 col-form-label text-md-right">' + LANG['EXTRA_PORT'] + ' ' + number + ':</label>' +
        '<div class="col-md-3">' +
          '<select class="form-control EXTRA_PORT_TYPE" style="width: 100%" name="EXTRA_PORT_TYPE_' + number + '"></select>' +
          '<small class="form-text text-muted mb-3 mb-md-0">' + LANG['PORT_TYPE'] + '</small>' +
        '</div>' +
        '<div class="col-md-2">' +
          '<input type="number" min="1" value="' + (rowNumber + 1) + '" class="form-control extraPortRow" name="EXTRA_PORT_ROW_' + number + '">' +
          '<small class="form-text text-muted mb-3 mb-md-0">' + LANG['ROW_NUMBER'] + '</small>' +
        '</div>' +
        '<div class="col-md-3">' +
          '<select class="form-control EXTRA_PORT_COMBO" style="width: 100%" name="EXTRA_PORT_COMBO_' + number + '" id="EXTRA_PORT_COMBO_' + number + '"></select>' +
          '<small class="form-text text-muted">' + LANG['COMBO_PORT'] + '</small>' +
        '</div>' +
      '</div>');

    $extraPortGroup.find('input').attr('max', $rowsNumInput.val());

    var $selectType = $extraPortGroup.find('select.EXTRA_PORT_TYPE');
    $selectType.html(portTypesHTML);
    $selectType.val(portType).change();
    $selectType.select2(CHOSEN_PARAMS);

    $selectType.on('change', function(){
      extraPorts[number]['portType'] = $(this).val();
      updateExtraPortsComboSelects();
    });

    var $selectCombo = $extraPortGroup.find('select.EXTRA_PORT_COMBO');
    $selectCombo.select2(comboPortSelect2Params);

    $selectCombo.on('change', function() {
      var wasComboWithPortNumber = extraPorts[number]['combo'];
      if (wasComboWithPortNumber > 0) {
        extraPorts[wasComboWithPortNumber]['combo'] = null;
        $('#EXTRA_PORT_COMBO_' + wasComboWithPortNumber).val('').change();
      }
      else if (wasComboWithPortNumber < 0) {
        delete portsComboBusy[wasComboWithPortNumber];
      }

      var newComboWithPortNumber = $(this).val();
      extraPorts[number]['combo'] = newComboWithPortNumber;

      if (portsComboBusy[newComboWithPortNumber]) {
        var extraPortNumber = portsComboBusy[newComboWithPortNumber];
        extraPorts[extraPortNumber]['combo'] = null;
        $('#EXTRA_PORT_COMBO_' + extraPortNumber).val('').change();
      }
      if (newComboWithPortNumber < 0) {
        portsComboBusy[newComboWithPortNumber] = number;
      }

      if (!newComboWithPortNumber || newComboWithPortNumber < 0) { return; }

      if (extraPorts[newComboWithPortNumber]['combo'] != number) {
        $('#EXTRA_PORT_COMBO_' + newComboWithPortNumber).val(number).change();
      }
    });

    return $extraPortGroup;
  }
});

