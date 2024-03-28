<script>
  //******************************************************************
  // on submitting snmp_form form generate json string
  // and submit snmp_json_form form
  //******************************************************************
  jQuery(document).ready(function () {
    jQuery('#snmp_form').submit(function (e) {
      e.preventDefault();
      var result = {};
      jQuery.each(jQuery('#snmp_form input.v_input'), function (k, v) {
        var name = jQuery(v).parent().parent().find('input:not("v_input"):eq(0)');
        if (name.val() != '') {
          var path_string = jQuery(v).attr('name');
          path_string = path_string.replace('*', name.val());
          var path = path_string.split('^');
          var value = jQuery(v).val();
          result = generate(path, result, value);
        }
      });
      var json_string = JSON.stringify(result, null, 2);
      jQuery('#json_string').val(json_string);
      jQuery('#snmp_json_form').submit();
    });
  });

  //******************************************************************
  // generate (arr, result value) - generate json from inputs
  //
  // ATTRIBUTES:
  //  arr - path array
  //  result - result array
  //  value - path value
  // RETURNS:
  //  result
  //******************************************************************
  function generate(arr, result, value) {

    for (var i = 0; i < arr.length; i++) {
      if (arr.length === 1) {
        result[arr[i]] = value;
      } else {
        if (!result[arr[i]]) result[arr[i]] = {};
        var old_arr = arr.slice(0);
        arr.shift();
        result[old_arr[i]] = generate(arr, result[old_arr[i]], value);
      }
    }
    return result;
  }

  //******************************************************************
  // add_file () - show modal for adding new file
  //
  //
  //******************************************************************
  function add_file() {
    var modal = modal = aModal.clear()
      .setBody('<form action="index.cgi" method="GET" "><div class="text-center">' +
        '<input type="hidden" name="index" value="%INDEX%">' +
        '<div class="form-group new_group">' +
        '<label class="control-label required col-md-3">_{NAME}_</label>' +
        '<div class="col-md-9 text-left">' +
        '<input name="name" type="text" class="form-control new_name">' +
        '</div>' +
        '</div>' +
        '<button type="submit" name="add_file" value="1" class="add_file btn btn-primary">_{ADD}_</button></div><form>')
      .show();
  }

  //******************************************************************
  // add_row () - generate json from inputs
  //
  // ATTRIBUTES:
  //  type - section name
  //******************************************************************
  function add_row(type) {
    switch (type) {
      case 'main': {
        var main = jQuery('#MAIN_');
        if (main.find("tbody").length === 0) {
          main.append('<tbody></tbody>')
        }
        main.find("tbody").append('<tr><td><input type="text" class="form-control""></td><td><input type="text" name="*" class="form-control v_input" ></td></tr>')
        break;
      }
      case 'info': {
        var info = jQuery('#INFO_');
        if (info.find("tbody").length === 0) {
          info.append('<tbody></tbody>')
        }
        info.find("tbody").append('<tr><td><input type="text" class="form-control""></td><td><input type="text" name="info^*^OIDS" class="form-control v_input" ></td><td><input type="text" name="info^*^PARSER" class="form-control v_input"></td></tr>')
        break;
      }
      case 'status': {
        var status = jQuery('#STATUS_');
        if (status.find("tbody").length === 0) {
          status.append('<tbody></tbody>')
        }
        status.find("tbody").append('<tr><td><input type="text" class="form-control""></td><td><input type="text" name="status^*^OIDS" class="form-control v_input" ></td><td><input type="text" name="status^*^PARSER" class="form-control v_input"></td></tr>\'')
        break;
      }
      case 'ports': {
        var ports = jQuery('#PORTS_');
        if (ports.find("tbody").length === 0) {
          ports.append('<tbody></tbody>')
        }
        ports.find("tbody").append('<tr><td><input type="text" class="form-control""></td><td><input name="ports^*^NAME" type="text" class="form-control v_input" ></td><td><input name="ports^*^OIDS" type="text" class="form-control v_input" ></td><td><input name="ports^*^PARSER" type="text" class="form-control v_input"></td></tr>')
        break;
      }
    }
  }
</script>