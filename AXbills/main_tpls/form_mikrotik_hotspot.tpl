<div class='card card-primary card-outline box-form'>

  <div class='card-header with-border'><h4 class='card-title'>Mikrotik Hotspot</h4></div>
  <div class='card-body'>

    <form name='MIKROTIK_HOTSPOT' id='form_MIKROTIK_HOTSPOT' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'/>
      <input type='hidden' name='mikrotik_hotspot' value='1'/>
      <input type='hidden' name='WALLED_GARDEN_ENTRIES' id='WALLED_GARDEN_ENTRIES' value='0'/>


      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='HOTSPOT_DNS_NAME_id'>АСР КАЗНА 39 IP _{ADDRESS}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control ip-input' required name='BILLING_IP_ADDRESS' value='%BILLING_IP_ADDRESS%'/>
        </div>
      </div>

      <div class='form-group bg-info'>
        <h4>Hotspot</h4>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3 required'>Hotspot _{INTERFACE}_</label>
        <div class='col-md-9'>
          %INTERFACE_SELECT%
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='HOTSPOT_ADDRESS_id'>IP _{ADDRESS}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control ip-input' required name='ADDRESS' value='%ADDRESS%'
                 id='HOTSPOT_ADDRESS_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='HOTSPOT_NETMASK_id'>_{SIZE}_ _{NETWORK}_ </label>
        <div class='col-md-9'>
          <input type='text' class='form-control' required name='NETMASK' value=%NETMASK%
                 id='HOTSPOT_NETMASK_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='HOTSPOT_NETWORK_id'>_{NETWORK}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control ip-input' required name='NETWORK' value='%NETWORK%'
                 id='HOTSPOT_NETWORK_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='DHCP_RANGE_id'>DHCP _{RANGE}_</label>
        <div class='col-md-9'>
          <input type='text' class='form-control' required name='DHCP_RANGE' value='%DHCP_RANGE%' id='DHCP_RANGE_id'/>
        </div>
      </div>

      <hr>

      <div class='form-group row'>
        <label class='control-label col-md-3 required' for='MIKROTIK_DNS_id'>DNS</label>
        <div class='col-md-9'>
          <input type='text' class='form-control ip-input' required name='DNS' value='%MIKROTIK_DNS%'
                 id='MIKROTIK_DNS_id'/>
        </div>
      </div>

      <div class='form-group bg-info' id='last_form_row'>
        <h4>Walled Garden</h4>
      </div>

      <div id='walled_garden_wrapper'></div>
      <div class='row'>
        <div id='walled_garden_controls text-right'>
          <button class='btn btn-xs btn-success' id='walled_garden_add_btn'>
            <span class='fa fa-plus'></span>
          </button>
        </div>
      </div>

    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_MIKROTIK_HOTSPOT' class='btn btn-primary' name='action' value='_{SET}_'>
  </div>
</div>

<script id='form-group_template' type='x-tmpl-mustache'>

 <div class='form-group row' data-counter='{{counter}}'>
   <label class='control-label col-md-3'>
   <a class='text-danger remove_host_btn form-control-static'>
       <span class='fa fa-times'></span>
     </a>
   {{#label}}{{label}}{{/label}}
      </label>
   <div class='col-md-8'>
     <input class='form-control' type='text' name='{{name}}' {{#value}}value='{{value}}'{{/value}}/>
   </div>
 </div>


</script>

<script>
  var _form = jQuery('#form_MIKROTIK_HOTSPOT');
  var _wrapper       = _form.find('#walled_garden_wrapper');
  var _add_btn       = _form.find('#walled_garden_add_btn');
  var _count_input = _form.find('#WALLED_GARDEN_ENTRIES');

  var input_template = jQuery('#form-group_template').text();
  Mustache.parse(input_template);

  var walled_garden_entries = 0;
  var deleted_numbers       = [];

  append_new_row('8.8.8.8');

  _add_btn.on('click', function (e) {
    e.preventDefault();
    append_new_row();
  });

  _form.on('submit', function(){
    _count_input.val(_wrapper.find('input').length);
  });

  function append_new_row(value) {

    var next_number = (deleted_numbers.length > 0)
        ? deleted_numbers.pop()
        : walled_garden_entries++;

    var _new_row = jQuery(render_new_row(next_number, {value : value}));

    _new_row.find('.remove_host_btn').on('click', function (e) {
      e.preventDefault();
      remove_this_row(this);
    });

    _wrapper.append(_new_row);
  }

  function render_new_row(counter, params) {
    var name_param = {name: "WALLED_GARDEN_" + counter, label: "Host " + counter, counter: counter};

    params = jQuery.extend(params, name_param);
    console.log(params);

    return Mustache.render(input_template, params);
  }

  function remove_this_row(context) {

    var _this_form_group = jQuery(context).parents('.form-group').first();
    var number_to_remove = _this_form_group.attr('data-counter');

    deleted_numbers.push(number_to_remove);
    // Reverse sort;
    deleted_numbers.sort(function (a, b) { return b - a });

    _this_form_group.remove();
  }

</script>