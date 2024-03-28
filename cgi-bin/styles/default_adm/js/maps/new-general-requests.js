/**
 * Created by pasichnyk on 2020-01-08.
 */
'use strict';

function ABillingLinkManager() {

  let self = this;
  this.$filterForm = null;

  jQuery(function () {
    self.$filterForm = $('form#mapUserShow');
  });

  this.registerBuild = function (location_id, coordx, coordy) {
    return 'index.cgi?qindex=' + index + '&header=2&add=1&LAYER_ID=1'
      + '&update_build=1'
      + '&LOCATION_ID=' + location_id
      + '&COORDY=' + coordy
      + '&COORDX=' + coordx
      + '&change=1';
  };

  this.addMarker = function (streetId, location_id, coordx, coordy) {
    return 'index.cgi?qindex=' + index + '&header=2&add=1&LAYER_ID=1'
      + '&STREET_ID=' + streetId
      + '&ADD_ADDRESS_BUILD=' + location_id
      + '&COORDY=' + coordy
      + '&COORDX=' + coordx
      + '&change=1';
  };

  this.delObject = function (id, layer, point_id = 0) {
    if (point_id === undefined || point_id === null || point_id === 'undefined')
      point_id = 0;

    return 'qindex=' + index + '&header=2&LAYER_ID=' + layer + '&OBJECT_ID=' + id + '&del=1&POINT_ID=' + point_id;
  };

  this.addPolygon = function (streetId, location_id) {
    return 'qindex=' + index + '&header=2&add=1&LAYER_ID=12' + '&STREET_ID=' + streetId
      + '&ADD_ADDRESS_BUILD=' + location_id
      + '&change=1';
  };

  this.addWifi = function (name, color) {
    return 'qindex=' + index + '&header=2&add=1&LAYER_ID=2' + '&NAME=' + name + '&COLOR=' + color + '&change=1';
  };

  this.registerBuildPolygon = function (location_id) {
    return 'qindex=' + index + '&header=2&add=1&LAYER_ID=12'
      + '&update_build=1'
      + '&LOCATION_ID=' + location_id
      + '&change=1';
  };

  this.addressChooseLocation = function () {
    return 'index.cgi?qindex=' + index + '&SHOW_ADDRESS=1&SHOW_UNREG=1&header=2';
  };

  this.wifiAddForm = function () {
    return 'index.cgi?qindex=' + index + '&WIFI_ADD_FORM=1&header=2';
  };
}

function ABillingLocation(LocationArray) {
  let self = this;

  this.locationArray = null;
  this.streetId = null;
  this.locationId = null;
  this.newNumber = null;

  if (LocationArray) this.setLocation(LocationArray);

  this.setLocation = function (LocationArray) {
    this.locationArray = LocationArray;
    this.streetId = LocationArray[1];
    this.locationId = LocationArray[2];
    this.newNumber = LocationArray[3];
  };

  this.getLocationId = function () {
    return this.locationId;
  };

  this.delLocation = function (object, callback) {
    aModal.clear()
      .setId('ModalDelLocation')
      .setBody('<h4>' + _DELETE_ITEM_FROM_MAP + '</h4>')
      .addButton(_CANCEL, 'districtModalCancelButton', 'default')
      .addButton(_YES, 'districtModalButton', 'primary')
      .show(setUpDelModal);

    function setUpDelModal(amodal) {

      jQuery('#districtModalButton').on('click', function () {
        let link = aBillingAddressManager.delObject(object['object'], object['layer'], object['point']);

        jQuery.ajax({
          url: '/admin/index.cgi',
          type: 'POST',
          data: link,
          contentType: false,
          cache: false,
          processData: false,
          success: function (result) {
            amodal.hide();

            let message_type = result === 'Error' ? 'err' : 'info';
            if (result !== 'Error' && callback) {
              callback();
            }
            displayJSONTooltip({MESSAGE: {caption: result, message_type: message_type}});
          },
          fail: function (error) {
            aTooltip.displayError(error);
          },
        });
      });

      jQuery('#districtModalCancelButton').on('click', function () {
        amodal.hide();
      })
    }
  };

  this.askLocation = function (callback) {
    jQuery.get(aBillingAddressManager.addressChooseLocation(), function (data) {
      aModal.clear()
        .setId('ModalLocation')
        .setHeader(_CHOOSE_ADDRESS)
        .setBody(data)
        .addButton(_CANCEL, 'districtModalCancelButton', 'default')
        .addButton(_YES, 'districtModalButton', 'primary')
        .show(setUpAddressModalForm);

      function setUpAddressModalForm(amodal) {

        initChosen();

        //bind handlers
        jQuery('#districtModalButton').on('click', function () {

          var dId = amodal.$modal.find('input[name="DISTRICT_ID"]').val();
          var sId = amodal.$modal.find('input[name="STREET_ID"]').val();
          var lId = amodal.$modal.find('input[name="LOCATION_ID"]').val();

          var newNumber = amodal.$modal.find('input.INPUT-ADD-BUILD').val() || null;

          self.setLocation([dId, sId, lId, newNumber]);

          if (callback) {
            callback(self, amodal);
          }
        });

        jQuery('#districtModalCancelButton').on('click', function () {
          discardAddingPoint()
        })
      }

    }, 'text');
  };

  this.askCustomMarker = function (lat, lng, url, callback, point_id) {
    sendGetAjaxForm(url, function (data) {
      aModal.clear()
        .setId('customMarker')
        .setBody(data)
        .show(setUpCustomeMarkerModalForm);

      function setUpCustomeMarkerModalForm(amodal) {
        initChosen();
        openModal = amodal;
        jQuery("form").on("submit", function (event) {
          event.preventDefault();
          let $form = amodal['$modal'].find('form');
          createHiddenInput($form, 'COORDX', lat);
          createHiddenInput($form, 'COORDY', lng);
          if (point_id)
            createHiddenInput($form, 'NEW_POINT_ID', point_id);

          sendPostAjaxForm($form, callback);
        });
      }
    });
  };

  this.askCustomPolyline = function (latLngStr, url, callback) {
    sendGetAjaxForm(url, function (data) {
      aModal.clear()
        .setId('customPolyline')
        .setBody(data)
        .show(setUpCustomPolylineModalForm);

      function setUpCustomPolylineModalForm(amodal) {
        initChosen();
        openModal = amodal;
        jQuery("form").on("submit", function (event) {
          event.preventDefault();
          let $form = amodal['$modal'].find('form');
          createHiddenInput($form, 'coords', latLngStr);
          sendPostAjaxForm($form, callback);
        });
      }
    });
  };

  this.askCustomPolygon = function (latLngStr, url, callback) {
    sendGetAjaxForm(url, function (data) {
      aModal.clear()
        .setId('customPolygon')
        .setBody(data)
        .show(setUpCustomPolygonModalForm);

      function setUpCustomPolygonModalForm(amodal) {
        initChosen();
        openModal = amodal;
        jQuery("form").on("submit", function (event) {
          event.preventDefault();
          let $form = amodal['$modal'].find('form');
          createHiddenInput($form, 'coords', latLngStr);
          sendPostAjaxForm($form, callback);
        });
      }
    });
  };

  this.askWiFi = function (callback) {
    sendGetAjaxForm(aBillingAddressManager.wifiAddForm(), function (data) {
      aModal.clear()
        .setId('ModalWifi')
        .setHeader(_ADD + ' Wi-Fi')
        .setBody(data)
        .addButton(_ADD, 'wifiModalButton', 'primary')
        .show(setUpWifiModalForm);

      function setUpWifiModalForm(amodal) {
        jQuery('#wifiModalButton').on('click', function () {
          let name = amodal.$modal.find('input[name="NAME"]').val();
          let color = amodal.$modal.find('input[name="COLOR"]').val();
          if (callback) {
            callback(name, color, amodal);
          }
        });
      }
    });
  };

  let sendPostAjaxForm = function (form_, callback) {
    let $form = form_;
    let data_ajax = 'q' + $form.serialize() + '&AJAX=1&json=1&MESSAGE_ONLY=1&header=2&ADD_ON_NEW_MAP=1';

    jQuery.ajax({
      url: $form.attr('action') || '/admin/index.cgi',
      type: $form.attr('method') || 'POST',
      data: data_ajax,
      contentType: $form.attr('enctype') || false,
      cache: false,
      processData: false,
      success: function (result) {
        openModal.hide();
        if (callback)
          callback(form_);
        displayJSONTooltip(result);
      },
      fail: function (error) {
        aTooltip.displayError(error);
      },
      complete: function () {
      }
    });
  };

  let sendGetAjaxForm = function (link, callback) {
    if (!link)
      return 0;

    jQuery.ajax({
      url: link,
      type: 'GET',
      contentType: false,
      cache: false,
      processData: false,
      success: function (result) {
        callback(result);
      },
      fail: function (error) {
        aTooltip.displayError(error);
      },
      complete: function () {
      }
    });
  };

  let createHiddenInput = function (form_, name, value) {
    let hidden_input = document.createElement('input');
    jQuery(hidden_input).attr({type: 'hidden', name: name, value: value});
    form_.append(hidden_input);
  };

}

var aBillingAddressManager = new ABillingLinkManager();
var openModal = {};
var mainLocation = new ABillingLocation();