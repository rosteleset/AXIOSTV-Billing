/*
 Leaflet.CenterCoordinates.
 (c) 2021, Vasyl Pasichnyk, pasichnykvasyl (Oswald)
*/

(function (factory, window) {

  // define an AMD module that relies on 'leaflet'
  if (typeof define === 'function' && define.amd) {
    define(['leaflet'], factory);

    // define a Common JS module that relies on 'leaflet'
  } else if (typeof exports === 'object') {
    module.exports = factory(require('leaflet'));
  }

  // attach your plugin to the global 'L' variable
  if (typeof window !== 'undefined' && window.L) {
    window.L.YourPlugin = factory(L);
  }
}(function (L) {

  L.Control.CenterCoordinates = L.Control.extend({
    options: {
      position: 'bottomright',
      saveBtnIcon: '&#10003;'
    },

    onAdd: function (map) {
      this._map = map;

      return this._createControl(this._click);
    },

    _click: function () {
      document.getElementById('coordinates-input-control').classList.remove('leaflet-control-hidden');
      document.getElementById('coordinates-control').classList.add('leaflet-control-hidden');
    },

    _createControl: function (fn) {

      this._container = document.createElement('div');
      this._container.classList.add('leaflet-control');
      this._container.classList.add('leaflet-coordinates-control');
      this._container.classList.add('leaflet-bar');

      L.DomEvent.disableScrollPropagation(this._container);
      L.DomEvent.disableClickPropagation(this._container);

      this._container.appendChild(this._labelControl(fn));
      this._container.appendChild(this._inputControl());

      this._map.on('moveend', () => this._updateCoordinates());

      return this._container;
    },

    _inputControl: function () {
      this._coorinatesInputControl = document.createElement('div');
      this._coorinatesInputControl.classList.add('leaflet-control-hidden');
      this._coorinatesInputControl.id = 'coordinates-input-control';

      let spanLng = document.createElement('span');
      spanLng.innerHTML = 'Lng: ';
      let inputLng = document.createElement('input');
      inputLng.classList.add('input-coordinates');
      inputLng.id = 'input-lng';

      let spanLat = document.createElement('span');
      spanLat.innerHTML = ' Lat: ';
      let inputLat = document.createElement('input');
      inputLat.classList.add('input-coordinates');
      inputLat.id = 'input-lat';

      let saveBtn = document.createElement('span');
      saveBtn.classList.add('leaflet-bar');
      saveBtn.classList.add('leaflet-save-coordinates');
      saveBtn.id = 'save-coordinates';
      saveBtn.innerHTML = this.options.saveBtnIcon;
      saveBtn.addEventListener('click', function () {
        let _lat = document.getElementById('input-lat').value;
        let _lng = document.getElementById('input-lng').value;
        map.setView([_lat, _lng]);

        document.getElementById('coordinates-control').classList.remove('leaflet-control-hidden');
        document.getElementById('coordinates-input-control').classList.add('leaflet-control-hidden');
      });

      this._coorinatesInputControl.appendChild(spanLng);
      this._coorinatesInputControl.appendChild(inputLng);
      this._coorinatesInputControl.appendChild(spanLat);
      this._coorinatesInputControl.appendChild(inputLat);
      this._coorinatesInputControl.appendChild(saveBtn);

      return this._coorinatesInputControl;
    },

    _labelControl: function (fn) {
      this._coorinatesControl = document.createElement('div');
      this._coorinatesControl.id = 'coordinates-control';

      this._coorinatesControl.addEventListener('click', fn);

      return this._coorinatesControl;
    },

    _updateCoordinates: function () {
      let centerCoordinates = this._map.getCenter();
      let lat = centerCoordinates.lat;
      let lng = centerCoordinates.lng;
      document.getElementById('coordinates-control').innerHTML = `Lng: ${lng} Lat: ${lat}`;
      document.getElementById('input-lng').value = lng;
      document.getElementById('input-lat').value = lat;
    }
  });

  L.control.CenterCoordinates = function (options) {
    return new L.Control.CenterCoordinates(options);
  };
}, window));
