'use strict';

var IPv6_HOSTS_COUNT = ['0',
  '9,223,372,036,854,775,808 networks /64',
  '4,611,686,018,427,387,904 networks /64',
  '2,305,843,009,213,693,952 networks /64',
  '1,152,921,504,606,846,976 networks /64',
  '576,460,752,303,423,488 networks /64',
  '288,230,376,151,711,744 networks /64',
  '144,115,188,075,855,872 networks /64',
  '72,057,594,037,927,936 networks /64',
  '36,028,797,018,963,968 networks /64',
  '18,014,398,509,481,984 networks /64',
  '9,007,199,254,740,992 networks /64',
  '4,503,599,627,370,496 networks /64',
  '2,251,799,813,685,248 networks /64',
  '1,125,899,906,842,624 networks /64',
  '562,949,953,421,312 networks /64',
  '281,474,976,710,656 networks /64',
  '140,737,488,355,328 networks /64',
  '70,368,744,177,664 networks /64',
  '35,184,372,088,832 networks /64',
  '17,592,186,044,416 networks /64',
  '8,796,093,022,208 networks /64',
  '4,398,046,511,104 networks /64',
  '2,199,023,255,552 networks /64',
  '1,099,511,627,776 networks /64',
  '549,755,813,888 networks /64',
  '274,877,906,944 networks /64',
  '137,438,953,472 networks /64',
  '68,719,476,736 networks /64',
  '34,359,738,368 networks /64',
  '17,179,869,184 networks /64',
  '8,589,934,592 networks /64',
  '4,294,967,296 networks /64',
  '2,147,483,648 networks /64',
  '1,073,741,824 networks /64',
  '536,870,912 networks /64',
  '268,435,456 networks /64',
  '134,217,728 networks /64',
  '67,108,864 networks /64',
  '33,554,432 networks /64',
  '16,777,216 networks /64',
  '8,388,608 networks /64',
  '4,194,304 networks /64',
  '2,097,152 networks /64',
  '1,048,576 networks /64',
  '524,288 networks /64',
  '262,144 networks /64',
  '131,072 networks /64',
  '65,536 networks /64',
  '32,768 networks /64',
  '16,384 networks /64',
  '8,192 networks /64',
  '4,096 networks /64',
  '2,048 networks /64',
  '1,024 networks /64',
  '512 networks /64',
  '256 networks /64',
  '128 networks /64',
  '64 networks /64',
  '32 networks /64',
  '16 networks /64',
  '8 networks /64',
  '4 networks /64',
  '2 networks /64',
  '18,446,744,073,709,551,616',
  '9,223,372,036,854,775,808',
  '4,611,686,018,427,387,904',
  '2,305,843,009,213,693,952',
  '1,152,921,504,606,846,976',
  '576,460,752,303,423,488',
  '288,230,376,151,711,744',
  '144,115,188,075,855,872',
  '72,057,594,037,927,936',
  '36,028,797,018,963,968',
  '18,014,398,509,481,984',
  '9,007,199,254,740,992',
  '4,503,599,627,370,496',
  '2,251,799,813,685,248',
  '1,125,899,906,842,624',
  '562,949,953,421,312',
  '281,474,976,710,656',
  '140,737,488,355,328',
  '70,368,744,177,664',
  '35,184,372,088,832',
  '17,592,186,044,416',
  '8,796,093,022,208',
  '4,398,046,511,104',
  '2,199,023,255,552',
  '1,099,511,627,776',
  '549,755,813,888',
  '274,877,906,944',
  '137,438,953,472',
  '68,719,476,736',
  '34,359,738,368',
  '17,179,869,184',
  '8,589,934,592',
  '4,294,967,296',
  '2,147,483,648',
  '1,073,741,824',
  '536,870,912',
  '268,435,456',
  '134,217,728',
  '67,108,864',
  '33,554,432',
  '16,777,216',
  '8,388,608',
  '4,194,304',
  '2,097,152',
  '1,048,576',
  '524,288',
  '262,144',
  '131,072',
  '65,536',
  '32,768',
  '16,384',
  '8,192',
  '4,096',
  '2,048',
  '1,024',
  '512',
  '256',
  '128',
  '64',
  '32',
  '16',
  '8',
  '4',
  '2',
  '1'
];

function ipv4ToIpv6(ipv4) {
  
  var octets     = ipv4.split('.');
  var octetBytes = [];
  $.each(octets, function (i, e) {
    octetBytes.push(Number(e));
  });
  
  var hextets = [];
  hextets[0]  = decimalToHex(0xffff, 4);
  hextets[1]  = decimalToHex(octetBytes[0], 2) + decimalToHex(octetBytes[1], 2);
  hextets[2]  = decimalToHex(octetBytes[2], 2) + decimalToHex(octetBytes[3], 2);
  
  var result = '::' + hextets.join(':');
  
  if (isValidIp(result)) {
    result = getIPv6ExtendedForm(result);
    return result;
  }
  else {
    return 'Error';
  }
}

function decimalToHex(decimal, chars) {
  return (decimal + Math.pow(16, chars)).toString(16).slice(-chars).toUpperCase();
}

function getHostsCountForBits(mask_bits) {
  if (mask_bits === 128) return 1;
  return IPv6_HOSTS_COUNT[mask_bits];
}

function getIPv6ExtendedForm(ip_string) {
  if (ip_string.indexOf('::') !== -1) {
    var hextets = ip_string.split(':');
    
    var empty_hextet_index = hextets.indexOf('');
    var empty_hextet_count = 8 - hextets.length;
    
    hextets[empty_hextet_index] = '0';
    while (empty_hextet_count--) {
      hextets.splice(empty_hextet_index, 0, '0');
    }
    
    return hextets.join(':')
  }
  else { //already extended
    return ip_string;
  }
}

function getIPv6ShortForm(ip_string) {
  //normalize
  ip_string = getIPv6ExtendedForm(ip_string);
  
  //split
  var hextets = ip_string.split(':');
  
  //remove trailing zeros
  $.each(hextets, function (index, hextet) {
    hextets[index] = hextet.replace(/^0*/, '');
  });
  
  //join again
  var short_string = hextets.join(':');
  
  //replace first ::* sequence
  short_string = short_string.replace(/:{2,}/, '::');
  
  return short_string;
}

function initIPv6Calc() {
  //cache DOM
  var $ip          = $('#ip');
  var $ip_extended = $('#ipv6_label_extended');
  var $ip_short    = $('#ipv6_label_short');
  
  var $prefix_select        = $('#prefix-length').find('select');
  var $subnets_count_select = $('#subnet-count').find('select');
  var $hosts_count_select   = $('#hosts-count').find('select');
  
  //bind events
  $ip.on('input', function () {
    var ip_string = $ip.val();
    
    if (isValidIp(ip_string)) {
      
      if (isValidIpv4(ip_string)) {
        ip_string = ipv4ToIpv6(ip_string);
      }
      
      $ip.parents('.form-group').removeClass('has-error');
      $ip_extended.text(getIPv6ExtendedForm(ip_string));
      $ip_short.text(getIPv6ShortForm(ip_string));
    }
    else {
      $ip.parents('.form-group').addClass('has-error');
    }
  });
  
  $prefix_select.on('change', function () {
    var value = this.value;
    renewSubnetsCount(value);
  });
  
  $subnets_count_select.on('change', function () {
    var value = this.value;
    renewHostsCount($prefix_select.val(), value);
  });
  
  //$hosts_count_select.on('change', function () {
  //var value = this.value;
  //});
  
  function renewSubnetsCount(prefixLength) {
    $subnets_count_select.empty();
    
    for (var i = 128, limit = Math.max(prefixLength, 64); i >= limit; i--) {
      var $option = $('<option></option>');
      
      var subnetsCount = getHostsCountForBits(i);
      
      $option.text(subnetsCount);
      $option.val(subnetsCount);
      
      $subnets_count_select.append($option);
    }
    
    updateChosen();
  }
  
  function renewHostsCount(prefixLength, subnetsCount) {
    $hosts_count_select.empty();
    
    for (var i = 1, limit = Math.min(prefixLength, 64); i <= limit; i++) {
      var $option = $('<option></option>');
      
      var hosts_count = getHostsCountForBits(i) << 2 * subnetsCount;
      
      $option.text(hosts_count);
      $option.val(128 - i);
      
      $hosts_count_select.append($option);
    }
    
    updateChosen();
  }
}

$(function () {
  initIPv6Calc();
});
