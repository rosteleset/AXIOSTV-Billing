'use strict';

window['IPV4REGEXP'] = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$|^(([a-zA-Z]|[a-zA-Z][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z]|[A-Za-z][A-Za-z0-9\-]*[A-Za-z0-9])$|^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$";

function IPv4Network() {
  this.address_int = 0;
  this.bits        = 0;
  
  this.range_offset = 0;
  this.range_margin = 0;
}

IPv4Network.prototype = {
  setAddress                    : function (new_value) {
    this.address_int = this.getNetworkAddressFromIPAddress(this.addressToAddressInt(new_value));
  },
  getAddress                    : function () {
    return this.addressIntToAddress(this.address_int);
  },
  setAddressInt                 : function (new_value) {
    this.address_int = this.getNetworkAddressFromIPAddress(new_value);
  },
  getAddressInt                 : function () {
    return this.address_int;
  },
  setNetmask                    : function (new_value) {
    this.setBits(this.calculateNetmaskToCIDR(new_value));
  },
  getNetmask                    : function () {
    return this.calculateCIDRToNetmask(this.bits);
  },
  getNetmaskInt                 : function () {
    return this.addressToAddressInt(this.calculateCIDRToNetmask(this.bits))
  },
  setBits                       : function (new_value) {
    this.bits = new_value;
    this.setAddressInt(this.address_int);
  },
  getBits                       : function () {
    return this.bits;
  },
  setHostsCount                 : function (new_hosts_count) {
    // Calculate new mask to handle hosts
    this.bits = this.calculateBitsForHostsCount(new_hosts_count + this.range_offset);
    this.calculateMargin(new_hosts_count);
    this.hosts_count = new_hosts_count;
  },
  getHostsCount                 : function () {
    return this.calculateHostsCountForBits(this.bits);
  },
  getRangeHostsCount            : function () {
    return this.getHostsCount() - (this.range_offset + this.range_margin)
  },
  getFirstAddress               : function (with_offset) {
    return this.addressIntToAddress(this.address_int
        + (with_offset && this.range_offset
            ? this.range_offset
            : 1));
  },
  getLastAddress                : function (with_margin) {
    return this.addressIntToAddress(this.address_int + this.getHostsCount()
        - (with_margin && this.range_margin
            ? this.range_margin
            : 2));
  },
  getOffset                     : function () {
    return this.range_offset;
  },
  getMargin : function () {
    return this.range_margin;
  },
  calculateMargin               : function (hosts_count) {
    this.range_margin = (this.getHostsCount() - this.range_offset) - hosts_count;
  },
  getNetworkAddressFromIPAddress: function (address_int, bits) {
    var netmask_int          = this.addressToAddressInt(this.calculateCIDRToNetmask(bits || this.bits));
    var pure_network_address = parseInt(address_int & netmask_int);
    
    if (pure_network_address < 0) {
      pure_network_address = Math.abs(pure_network_address >>> 0);
    }

    this.range_offset = address_int - pure_network_address;
    
    return pure_network_address;
  },
  addressToAddressInt           : function (address) {
    var a = address.split('.');
    return ((a[0] << 24) >>> 0) + ((a[1] << 16) >>> 0) + ((a[2] << 8) >>> 0) + (a[3] >>> 0);
  },
  addressIntToAddress           : function (address_int) {
    var a = ((address_int >> 24) & 0xFF) >>> 0;
    var b = ((address_int >> 16) & 0xFF) >>> 0;
    var c = ((address_int >> 8) & 0xFF) >>> 0;
    var d = (address_int & 0xFF) >>> 0;
    
    return (a + "." + b + "." + c + "." + d);
  },
  
  calculateCIDRToNetmask: function (bits) {
    var mask = [];
    for (var i = 0; i < 4; i++) {
      var n = Math.min(bits, 8);
      mask.push(256 - Math.pow(2, 8 - n));
      bits -= n;
    }
    return mask.join('.');
  },
  
  calculateNetmaskToCIDR    : function (netmask) {
    var maskNodes = netmask.match(/(\d+)/g);
    var cidr      = 0;
    for (var i in maskNodes) {
      if (!maskNodes.hasOwnProperty(i)) continue;
      cidr += (((maskNodes[i] >>> 0).toString(2)).match(/1/g) || []).length;
    }
    return cidr;
  },
  calculateBitsForHostsCount: function (hosts_count) {
    var bits = 32;
    while ((1 << (32 - bits)) < hosts_count && bits > 15) {
      --bits
    }
    return bits;
  },
  calculateHostsCountForBits: function (bits) {
    return 1 << (32 - bits)
  },
  isValidIPv4               : function (address) {
    return address.match(window['IPV4REGEXP'])
  }
};


/*
function IPv4Range() {
  this.hosts_count = 0;
  
  // If address is not pure network address, difference stored here
  this.range_offset = 0;
  
  // If someone declared there should
  this.range_margin = 0;
}

// Inheritance from IPv4Network
$.extend(IPv4Range.prototype, IPv4Network.prototype, {
  getNetworkAddressFromIPAddress        : function (address_int) {
    var netmask_int          = this.addressToAddressInt(this.calculateCIDRToNetmask(this.bits));
    var pure_network_address = address_int & netmask_int;
    this.range_offset        = address_int - pure_network_address;
    
    return pure_network_address;
  },
  setHostsCount       : function (new_value) {
    while (new_value > this.getHostsCount() && this.bits >= 0) {
      this.bits--;
    }
    this.range_margin = this.getHostsCount() - new_value;
    this.hosts_count  = new_value;
  },
  getNetworkHostsCount: function () {
    return IPv4Network.prototype.getHostsCount.apply(this);
  },
  getHostsCount       : function () {
    return this.getNetworkHostsCount() - (this.range_offset || 0) - (this.range_margin || 0)
  },
  getFirstAddress     : function (with_offset) {
    return this.addressIntToAddress(
        this.address_int +
        (with_offset && this.range_offset
            ? this.range_offset
            : 1)
    );
  },
  getLastAddress      : function (with_margin) {
    return this.addressIntToAddress(
        this.address_int + this.getNetworkHostsCount() -
        (with_margin && this.range_margin
            ? this.range_margin
            : 2)
    );
  },
  getOffset           : function () {
    return this.range_offset;
  },
  getMargin           : function () {
    return this.range_margin;
  }
});*/
