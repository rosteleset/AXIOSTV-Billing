'use strict';

var IPv4_BITS_FOR_MASK = {
  "255.0.0.0"  : '8',
  "255.128.0.0": '9',
  "255.192.0.0": '10',
  "255.224.0.0": '11',
  "255.240.0.0": '12',
  "255.248.0.0": '13',
  "255.252.0.0": '14',
  "255.254.0.0": '15',
  
  "255.255.0.0"  : '16',
  "255.255.128.0": '17',
  "255.255.192.0": '18',
  "255.255.224.0": '19',
  "255.255.240.0": '20',
  "255.255.248.0": '21',
  "255.255.252.0": '22',
  "255.255.254.0": '23',
  
  "255.255.255.0"  : '24',
  "255.255.255.128": '25',
  "255.255.255.192": '26',
  "255.255.255.224": '27',
  "255.255.255.240": '28',
  "255.255.255.248": '29',
  "255.255.255.252": '30',
  "255.255.255.254": '31',
  "255.255.255.255": '32'
};
var IPv4_MASK_FOR_BITS = {
  '8' : "255.0.0.0",
  '9' : "255.128.0.0",
  '10': "255.192.0.0",
  '11': "255.224.0.0",
  '12': "255.240.0.0",
  '13': "255.248.0.0",
  '14': "255.252.0.0",
  '15': "255.254.0.0",
  
  '16': "255.255.0.0",
  '17': "255.255.128.0",
  '18': "255.255.192.0",
  '19': "255.255.224.0",
  '20': "255.255.240.0",
  '21': "255.255.248.0",
  '22': "255.255.252.0",
  '23': "255.255.254.0",
  
  '24': "255.255.255.0",
  '25': "255.255.255.128",
  '26': "255.255.255.192",
  '27': "255.255.255.224",
  '28': "255.255.255.240",
  '29': "255.255.255.248",
  '30': "255.255.255.252",
  '31': "255.255.255.254",
  '32': "255.255.255.255"
};

function isValidIpv4(ip) {
  if (ip.indexOf('.') !== -1) {
    var octets = ip.split('.');
    
    if (octets.length !== 4) return false;
    
    var result = true;
    $.each(octets, function (index, octet) {
      if (octet < 0 && octet > 255) result = false;
    });
    return result;
    
  }
  else {
    return false;
  }
}

function getIPv4MaskForBits(bits) {
  return IPv4_MASK_FOR_BITS[bits];
}

function getIPv4HostsCountForBits(mask_bits) {
  if (mask_bits === 32) return 1;
  var host_part_bits = 32 - mask_bits;
  return (1 << host_part_bits);
}

function getIPv4BitsForHostsCount(hosts_count) {
  var mask_length = Math.log(hosts_count) / Math.log(2);
  return Math.round(mask_length);
}


/**
 * initIPv4formValidation() - IPv4 input validation
 *
 * Form structure is shown below
 <div class='form-group'>
 <label class='col-md-3 control-label'>IP:</label>
 
 <div class='col-md-2'>
 <input class='inputs form-control' maxlength='3' id='i1' name=IP_D1 value='%IP_D1%'>
 </div>
 <div class='col-md-2'>
 <input class='inputs form-control' maxlength='3' id='i2' name=IP_D2 value='%IP_D2%'>
 </div>
 <div class='col-md-2'>
 <input class='inputs form-control' maxlength='3' id='i3' name=IP_D3 value='%IP_D3%'>
 </div>
 <div class='col-md-2'>
 <input class='inputs form-control' maxlength='3' id='i4' name=IP_D4 value='%IP_D4%'>
 </div>
 </div>
 *
 */
function initIPv4formValidation() {
  
  var IPv4RegExp = /[0-9]{1,3}/;
  
  //cache DOM
  var $inputs = $('.inputs');
  
  //bind events
  $inputs.on('input', function () {
        var $input = $(this);
        if (checkNonNumericSymbols($input))
          checkForMaxSize($input);
      }
  );
  
  //Check for backspace btn
  $inputs.on('keyup', function (event) {
    var $this = $(this);
    if (event.keyCode === 8) { //Backspace
      if (this.id !== 'i1' && this.value === '') {
        
        var isSecond = $this.attr('secondKeyStroke') === 'true';
        
        if (isSecond) {
          
          $this.attr('secondKeyStroke', 'false');
          $this.parent().prev('div').find('.inputs').focus();
          
        }
        else {
          
          $this.attr('secondKeyStroke', 'true')
          
        }
      }
    }
    else {
      if ($this.val() === '0') {
        focusNext($this);
      }
    }
  });
  
  function checkNonNumericSymbols($input) {
    var prevValue = $input.val();
    
    if (prevValue.match(IPv4RegExp) && prevValue <= 255) {
      $input.parents('.form-group').removeClass('has-error');
      return true;
    }
    else {
      $input.parents('.form-group').addClass('has-error');
      return false;
    }
  }
  
  function checkForMaxSize($input) {
    var size = $input.val().length;
    
    if (size >= $input.attr('maxlength')) {
      focusNext($input);
    }
  }
  
  function focusNext($input) {
    if ($input.attr('id') !== 'i4') {
      var next = $input.parent().next('div').find('.inputs');
      next.focus();
    }
  }
}

/**
 * IP calc form input calculation
 *
 */
function initIPv4Calc() {
  //cache DOM
  var $mask                 = $('#ipv4_mask');
  var $mask_bits_select     = $('#ipv4_mask_bits').find('select');
  var $subnets_count_select = $('#subnet_count').find('select');
  var $hosts_count_select   = $('#hosts_count').find('select');
  var $subnet_mask          = $('#SUBNET_MASK');
  
  //bind events
  $mask_bits_select.on('change', function () {
    Events.emit('netlist_mask_bits_select_change', this.value);
  });
  $subnets_count_select.on('change', function () {
    Events.emit('netlist_subnets_count_select_change', this.value);
  });
  $hosts_count_select.on('change', function () {
    Events.emit('netlist_hosts_count_select_change', this.value);
  });
  
  //mask
  Events.on('netlist_mask_bits_select_change', function (data) {
    //renew network mask
    setMask(IPv4_MASK_FOR_BITS[data]);
    
    renewSubnetsCount(data);
    renewChosenValue($subnets_count_select, 1);
    
    Events.emit('netlist_subnets_count_select_change', $subnets_count_select.val());
  });
  
  Events.on('netlist_subnets_count_select_change', function (data) {
    renewHostsCountOptions();
    renewHostsCount(data);
    
    renewSubnetMask();
  });
  
  Events.on('netlist_hosts_count_select_change', function (hosts_count) {
    var hosts_per_subnet = getIPv4HostsCountForBits($mask_bits_select.val());
    hosts_count          = Number(hosts_count) + 2;
    
    var subnets_count = hosts_per_subnet / (hosts_count);
    renewChosenValue($subnets_count_select, subnets_count);
    
    renewSubnetMask();
  });
  
  //******   init   ******
  $(function () {
    Events.emit('netlist_mask_bits_select_change', $mask_bits_select.val());
    
    renewChosenValue($subnets_count_select, _FORM['SUBNET_NUMBER']);
    renewChosenValue($hosts_count_select, _FORM['HOSTS_COUNT']);
    
    renewSubnetMask();
  });
  
  function setMask(mask_text) {
    $mask.text(mask_text);
    $('#MASK_INPUT').val(mask_text);
  }
  
  function renewSubnetMask() {
    var subnets_count = $subnets_count_select.val();
    var subnet_bits   = $mask_bits_select.val();
    
    var bits = Number(subnet_bits) + getIPv4BitsForHostsCount(subnets_count);
    
    var mask = getIPv4MaskForBits(bits);
    
    $subnet_mask.val(mask);
  }
  
  
  function renewSubnetsCount(mask) {
    
    $subnets_count_select.empty();
    
    for (var i = 32; i >= mask; i--) {
      var $option = $('<option></option>');
      
      var subnetsCount = getIPv4HostsCountForBits(i);
      
      $option.text(subnetsCount);
      $option.val(subnetsCount);
      
      $subnets_count_select.append($option);
    }
    
    updateChosen();
  }
  
  function renewHostsCount() {
    var mask_bits               = $mask_bits_select.val();
    var subnets_count           = $subnets_count_select.val();
    var hosts_count_per_network = getIPv4HostsCountForBits(mask_bits);
    
    var hosts_count;
    if (subnets_count === 1) {
      hosts_count = hosts_count_per_network - 2;
    }
    else {
      hosts_count = (hosts_count_per_network / subnets_count) - 2;
    }
    
    if (hosts_count <= 0) hosts_count = 1;
    
    renewChosenValue($hosts_count_select, hosts_count);
  }
  
  function renewSubnetsCountOptions(mask) {
    
    $subnets_count_select.empty();
    
    for (var i = mask; i > 0; i--) {
      var $option       = $('<option></option>');
      var subnets_count = getIPv4HostsCountForBits(mask);
      
      if (subnets_count <= 0) subnets_count = 1;
      
      $option.val(subnets_count);
      $option.text(subnets_count);
      
      $subnets_count_select.append($option);
    }
    
    updateChosen();
  }
  
  function renewHostsCountOptions() {
    var mask = $mask_bits_select.val();
    
    $hosts_count_select.empty();
    
    for (var i = mask; i <= 32; i++) {
      var $option = $('<option></option>');
      
      var hosts_count = getIPv4HostsCountForBits(i) - 2;
      
      if (hosts_count <= 0) hosts_count = 1;
      
      $option.val(hosts_count);
      $option.text(hosts_count);
      
      $hosts_count_select.append($option);
    }
    
    updateChosen();
  }
}

$(function () {
  initIPv4formValidation();
  initIPv4Calc();
});