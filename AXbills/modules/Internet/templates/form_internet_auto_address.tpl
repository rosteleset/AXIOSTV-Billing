<div class='form-address'>
    <input type='hidden' name='AUTO_ADDRESS' value='1'>
    <input type='hidden' name='AUTO_POST_CODE' id="POST_CODE">

    <div class='form-group row' style='%EXT_SEL_STYLE%'>
        <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-DISTRICT'>_{ADDRESS}_:</label>
        <div class='col-sm-9 col-md-8'>
            <input id="ADDRESS" name="ADDRESS" class="form-control" required autocomplete="off"/>
        </div>
    </div>

    <div class='form-group row' style='%EXT_SEL_STYLE%'>
        <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-BUILD'>_{ADDRESS_FLAT}_:</label>
        <div class='col-sm-9 col-md-8'>
            <input id="ADDRESS_FLAT" class="form-control" name="ADDRESS_FLAT" />
        </div>
    </div>

    <div class='form-group row' style='%EXT_SEL_STYLE%'>
        <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-BUILD'>_{ADDRESS_BUILD}_:</label>
        <div class='col-sm-9 col-md-8'>
            <input id="BUILD_ID" class="form-control" required name="AUTO_BUILD" />
        </div>
    </div>

    <div class='form-group row' style='%EXT_SEL_STYLE%'>
        <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-BUILD'>_{DISTRICTS}_:</label>
        <div class='col-sm-9 col-md-8'>
            <input id="DISTRICT_ID" class="form-control" required name="AUTO_DISTRICT" />
        </div>
    </div>

    <div class='form-group row' style='%EXT_SEL_STYLE%'>
        <label class='col-sm-3 col-md-4 col-form-label text-md-right LABEL-BUILD'>_{STREET}_:</label>
        <div class='col-sm-9 col-md-8'>
            <input id="STREET_ID" class="form-control" required name="AUTO_STREET" />
        </div>
    </div>

</div>

<script>
  let autocomplete;
  let address1Field;
  let address2Field;

  function initAutocomplete() {
    address1Field = document.querySelector("#ADDRESS");
    address2Field = document.querySelector("#ADDRESS_FLAT");
    // Create the autocomplete object, restricting the search predictions to
    // addresses in the US and Canada.
    autocomplete = new google.maps.places.Autocomplete(address1Field, {
      componentRestrictions: { country: ["%REGION%"] },
      fields: ["address_components", "geometry"],
      types: ["address"],
    });
    address1Field.focus();
    // When the user selects an address from the drop-down, populate the
    // address fields in the form.
    autocomplete.addListener("place_changed", fillInAddress);
  }

  function fillInAddress() {
    // Get the place details from the autocomplete object.
    const place = autocomplete.getPlace();
    let address1 = "";
    let postcode = "";

    // Get each component of the address from the place details,
    // and then fill-in the corresponding field on the form.
    // place.address_components are google.maps.GeocoderAddressComponent objects
    // which are documented at http://goo.gle/3l5i5Mr
    for (const component of place.address_components) {
      const componentType = component.types[0];

      console.log(component);

      switch (componentType) {
        case "street_number": {
          address1 = `${component.long_name} ${address1}`;
          document.querySelector("#BUILD_ID").value = component.short_name;
          break;
        }

        case "route": {
          address1 += component.short_name;
          document.querySelector("#STREET_ID").value = component.short_name;
          break;
        }

        case "postal_code": {
          postcode = `${component.long_name}${postcode}`;
          break;
        }

        case "postal_code_suffix": {
          postcode = `${postcode}-${component.long_name}`;
          break;
        }

        case "locality":
          document.querySelector("#DISTRICT_ID").value = component.long_name;
          break;
      }
    }
    address1Field.value = address1;
    document.querySelector("#POST_CODE").value = postcode;
    // After filling the form with address components from the Autocomplete
    // prediction, set cursor focus on the second address line to encourage
    // entry of subpremise information such as apartment, unit, or floor number.
    address2Field.focus();
  }
</script>


<script src="https://maps.googleapis.com/maps/api/js?key=%API_KEY%&language=%LANG%&libraries=places&v=weekly&callback=initAutocomplete"></script>
<script src="https://polyfill.io/v3/polyfill.min.js?features=default"></script>
