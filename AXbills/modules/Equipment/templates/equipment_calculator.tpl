<script src='/styles/default/js/cytoscape.min.js'></script>
<script src='https://cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.10/lodash.js'></script>
<script src='/styles/default/js/cytoscape-edgehandles.js'></script>

<script src="/styles/default/js/popper.min.js"></script>
<script src="/styles/default/js/cytoscape-popper.js"></script>

<script src="/styles/default/js/tippy.all.min.js"></script>
<link rel="stylesheet" href="/styles/default/css/tippy.css"/>

<style>
    #cy{
        min-height: 600px;
    }
    .card-body{
        position: relative;
    }
    .buttons{
        position: absolute;
        left: 20px;
        top: 20px;
        width: 50px;
        z-index: 9999;
        background: rgba(0,0,0,0.2);
        padding: 10px;
        border-radius: 5px;
    }
    .buttons img{
        width: 100%;
        padding: 5px;
        background: rgba(0,0,0,0.5);
        border-radius: 5px;
        margin-top: 5px;
        margin-bottom: 5px;
    }

    .info-table {
        position: absolute;
        z-index: 99;
        width: 400px;
        top: 20px;
        right: 20px;
        padding: 20px;
        background: rgba(0, 0, 0, 0.2);
        display: none;
    }

    .info-table table {
        margin-bottom: 0;
        color: white;
    }
    #add_connector{
        background: grey;
        width: 100%;
        height: 30px;
        border-radius: 10px;
        margin-top: 5px;
        margin-bottom: 5px;
    }
    #hide_image{
        display: none;
    }
</style>

<div class='card card-primary card-outline container-md collapsed-card'>
    <div class='card-header with-border'>
        <div class="row">
            <div class="col-md-10 float-left text-left">
        <h3 class='card-title'> _{TYPES}_</h3>
            </div>
        <div class="col-md-2 float-right text-right">
            <div class="btn-group">
                <button type="button" title="Show/Hide" class="btn btn-tool" data-card-widget="collapse">
                    <i class="fa fa-plus"></i>
                </button>
            </div>
        </div>
        </div>
    </div>
    <div class='card-body'>
        %FORM%
    </div>
</div>

<div class='card card-primary card-outline container-md'>
    <div class='card-header with-border'>
        <h3 class='card-title'> _{CALCULATOR}_</h3>
    </div>
    <div class='card-body'>
        <div class='buttons'>
            <img src='/img/calculator/olt.svg' title="OLT" alt='olt' id='add_olt'>
            <img src='/img/calculator/split.svg' title="_{SPLITTER}_" alt='splitter' id='add_splitter'>
            <img src='/img/calculator/divide.svg' title="_{DIVIDER}_" alt='divider' id='add_divider'>
            <div id="add_connector" title="_{CONNECTOR}_" ></div>
        </div>

        <div class="info-table table-sm">
            <table class="table">

            </table>
        </div>
        <div id='cy'>
        </div>
    </div>

</div>

<script>
  console.warn = function () {};
  var nodes = [];
  var olt_data = JSON.parse('%OLT%');
  var splitter_data = JSON.parse('%SPLITTER%');
  var divider_data = JSON.parse('%DIVIDER%');
  var connector_data = JSON.parse('%CONNECTOR%');

  var keys_array = Object.keys(splitter_data);
  keys_array.sort(function(a, b) {
    return parseFloat(a) - parseFloat(b);
  });


  document.addEventListener('DOMContentLoaded', function () {

    var makeTippy = function (node, text) {
      return tippy(node.popperRef(), {
        content: function () {
          var div = document.createElement('div');

          div.innerHTML = text;

          return div;
        },
        arrow: true,
        placement: 'bottom',
        hideOnClick: false,
        sticky: true,
        flip: false,
        boundary: document.querySelector('#cy'),
      });
    };



    var cy = window.cy = cytoscape({
      container: document.getElementById('cy'),
      layout: {
        name: 'breadthfirst',
        fit: true,
        avoidOverlap: true,
        avoidOverlapPadding: 100,
        animate: false,
        padding: 100,
        spacingFactor: 1.5,
        nodeDimensionsIncludeLabels: true,
        minNodeSpacing: 10,
      },
      style: [
        {
          selector: 'node',
          style: {
            'content': 'data(name)',
            'shape': 'roundrectangle',
            'background-image': function (e) {
              switch (e.data().type) {
                case "olt":
                  return '/img/calculator/olt.svg';
                case "splitter":
                  return '/img/calculator/split.svg';
                case "divider":
                  return '/img/calculator/divide.svg';
              }
            },
            'background-width': '70%',
            'background-height': '70%',
            'width': '70',
            'height': '70'
          }
        },
        {
          selector: 'node[type="connector"]',
          style: {
            'content': 'data(name)',
            'shape': 'ellipse',
            'width': '30',
            'height': '30'
          }
        },
        {
          selector: '.eh-handle',
          style: {
            'background-color': 'red',
            'width': 12,
            'height': 12,
            'shape': 'ellipse',
            'overlay-opacity': 0,
            'border-width': 12, // makes the handle easier to hit
            'border-opacity': 0,
            'background-image': 'none'
          }
        },

        {
          selector: '.eh-hover',
          style: {
            'background-color': 'red'
          }
        },

        {
          selector: '.eh-source',
          style: {
            'border-width': 2,
            'border-color': 'red'
          }
        },

        {
          selector: '.eh-target',
          style: {
            'border-width': 2,
            'border-color': 'red'
          }
        },

        {
          selector: '.eh-preview, .eh-ghost-edge',
          style: {
            'background-color': 'red',
            'line-color': 'red',
            'target-arrow-color': 'red',
            'source-arrow-color': 'red'
          }
        },

        {
          selector: '.eh-ghost-edge.eh-preview-active',
          style: {
            'opacity': 0
          }
        }
      ],

      elements: {
        nodes: nodes,
        edges: []
      }

    });

    var eh = cy.edgehandles();
    eh.disableDrawMode();

    jQuery(document).keyup(function (e) {
      if(e.keyCode === 46) {

        jQuery.each(cy.elements(':visible'), function (k, v) {
          if(v.data("tippy") !== undefined)
              v.data("tippy").destroy();
        });

        cy.nodes(':selected').remove();
        cy.edges(':selected').remove();

        calculate();
      }
    });

    jQuery('#add_olt').click(function () {
      cy.add({
        group: 'nodes',
        data: { type: 'olt', name: 'OLT',
          info: [
              {name: '_{NAME}_', type: 'name', data:'OLT'},
              {name: '_{TYPE}_', type: 'select', onChange: "typeSelect(this)", data:olt_data},
              {name: '_{SIGNAL}_', data:Object.keys(olt_data)[0], type:"signal"}
          ]},
        position: { x: cy.width()/2, y: cy.height()/2  }
      });
    });

    jQuery('#add_connector').click(function () {
      cy.add({
        group: 'nodes',
        data: { type: 'connector', name: '',  info: [
                {name: '_{NAME}_', type: 'name', data:''},
                {name: "_{SIGNAL_LOSS}_", data:Object.keys(connector_data)[0], type:"signal"}
          ]},
        position: { x: cy.width()/2, y: cy.height()/2  }
      });
    });

    jQuery('#add_splitter').click(function () {
      cy.add({
        group: 'nodes',
        data: { type: 'splitter', name: '_{SPLITTER}_',
          info: [
              {name: '_{NAME}_', type: 'name', data:'_{SPLITTER}_'},
              {name: '_{TYPE}_', type: 'range', onChange: 'splitterChange(this)'},
              {name: '_{SIGNAL_LOSS}_', data:keys_array[parseInt((keys_array.length-1)/2)], type:"signal"}
          ]},
        position: { x: cy.width()/2, y: cy.height()/2  }
      });
    });

    jQuery('#add_divider').click(function () {
      cy.add({
        group: 'nodes',
        data: { type: 'divider', name: '_{DIVIDER}_',
          info: [
              {name: '_{NAME}_', type: 'name', data:'_{DIVIDER}_'},
              {name: '_{TYPE}_', type: 'select', onChange: "typeSelect(this)", data:divider_data},
              {name: '_{SIGNAL_LOSS}_', data:Object.keys(divider_data)[0], type:"signal"}
          ]},
        position: { x: cy.width()/2, y: cy.height()/2  }
      });
    });

    cy.on('tapunselect', function (e) {
      var node = e.target;
      jQuery('.info-table').css('display', 'none');
      jQuery.each(jQuery('.info-table input, .info-table select'), function (key, value) {
        var val = jQuery(value).val();

        if(node.data("info")[key].type === "signal") {
          node.data("info")[key].data = val;
        } else if(node.data("info")[key].type === "select"){
          node.data("info")[key].selected = val;
        } else if(node.data("info")[key].type === "range"){
          node.data("info")[key].selected = val;
        } else if(node.data("info")[key].type === "name") {
          node.data("info")[key].data = val;
          node.data("name", val);
        }
      });
      calculate();
      jQuery('.info-table .table').html("");
    });

    cy.on('remove', 'node', function (e) {
      jQuery('.info-table').css('display', 'none');
      jQuery('.info-table .table').html("");
    });

    cy.on('tapselect', 'node', function (e) {
      var node = e.target;

      jQuery.each(node.data("info"), function (key, value) {
        if(value.type === "signal") {
          jQuery('.info-table .table').append(
            '<tr>' +
            '<td>' + value.name + '</td>' +
            '<td><input class="signal form-control form-control-sm" value="' + value.data + '" /></td>' +
            '</tr>');
        } else if(value.type === "select"){
          var select = '<select onChange="'+value.onChange+'" class="select2 form-control-sm col-md-12">';
          jQuery.each(value.data, function (k, v) {
            if(value.selected === k) {
              select += '<option selected value="'+k+'">'+v+'</option>'
            } else
            select += '<option value="'+k+'">'+v+'</option>'
          });
          select += '</select>';
          jQuery('.info-table .table').append(
            '<tr>' +
            '<td>' + value.name + '</td>' +
            '<td>'+select+'</td></tr>');
        } else if(value.type === "range"){
          var lenth = Object.keys(splitter_data).length-1;
          var selected = value.selected ? value.selected : (parseInt((keys_array.length-1)/2));
          jQuery('.info-table .table').append(
            '<tr>' +
            '<td>' + value.name + '<span class="splitter_type">('+splitter_data[keys_array[selected]]+')</span></td>' +
            '<td><input onChange="'+value.onChange+'" type="range" min="0" max="'+lenth+'" value="'+selected+'" class="slider form-range w-100""></td>' +
            '</tr>');
        } else if(value.type === "text"){
          jQuery('.info-table .table').append(
            '<tr>' +
            '<td>' + value.name + '</td>' +
            '<td>' + value.data + '</td>' +
            '</tr>');
        } else if(value.type === "name"){
          jQuery('.info-table .table').append(
            '<tr>' +
            '<td>' + value.name + '</td>' +
            '<td><input class="name form-control form-control-sm" value="' + value.data + '" /></td>' +
            '</tr>');
        }
        jQuery(".select2").select2({width: '100%', dropdownAutoWidth: true});
      });

      jQuery('.info-table').css('display', 'block');
    });

    cy.on('remove', 'edge:visible', function (e) {
      if(e.target.data().tippy !== undefined)
      e.target.data().tippy.destroy();
    });

    cy.on('ehcomplete', function (e, source, target, eles) {

      var connections;

      if(target.data("type") === "olt"){
        eles.remove();
      }else if(source.data("type") === "splitter"){
        connections = cy.edges('[source = "'+source.id()+'"]:visible"');
        if(connections.length > 2){
          eles.remove();
        }
      }

      if(target.data("type") === "splitter"){
        connections = cy.edges('[target = "'+target.id()+'"]:visible"');
        if(connections.length > 1){
          eles.remove();
        }
      }

      calculate();
    });


    function calculate(start, signal) {
      if(start === undefined) {
        var edges = cy.edges(":visible");
        jQuery.each(edges, function (key, value) {
          var source = cy.getElementById(value.data().source);
          if(source.data().type === "olt"){
            var info = source.data("info").find(a => a.type === "signal");
            calculate(source, info.data);
          }
        });
      } else {
        var connections = cy.edges('[source = "'+start.id()+'"]:visible"');
        jQuery.each(connections, function (key, connection) {
          if(connection.data().tippy !== undefined)
            connection.data().tippy.destroy();

          if(connection.target().data("type") === "olt")
            return;

          var calculated_signal = signal;

          if(typeof signal === "string" && signal.includes(';')){
            calculated_signal = signal.split(';')[key];
          }

          var tippy = makeTippy(connection, parseFloat(calculated_signal).toFixed(2));
          tippy.show();
          connection.data().tippy = tippy;
          var info = connection.target().data("info").find(a => a.type === "signal");

          var new_signal;
          if(connection.target().data("type") === "divider"){
            var divider = connection.target();
            if(divider.data().tippy !== undefined)
              divider.data().tippy.destroy();

            calculated_signal = parseFloat(calculated_signal) - parseFloat(info.data);
            tippy = makeTippy(divider, calculated_signal.toFixed(2));
            tippy.show();
            divider.data().tippy = tippy;

          }
          if(connection.target().data("type") === "splitter"){
            var signals = info.data.split(';');
            new_signal = (parseFloat(calculated_signal) - parseFloat(signals[0]))+
              ";"+(parseFloat(calculated_signal) - parseFloat(signals[1]));

          } else {
            new_signal = parseFloat(calculated_signal) - parseFloat(info.data);
          }

          calculate(cy.getElementById(connection.target().id()), new_signal);
        })
      }
    }


    jQuery('#calculator_types').submit(function (e) {
      var result = {};
      jQuery.each(jQuery('#calculator_types input.v_input'), function (k, v) {
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
      jQuery('input[name="new_types"]').val(json_string);
    });

  });

  function typeSelect(select) {
    var signal_input = jQuery(select).closest('table').find('.signal');
    if(signal_input.length > 0){
      signal_input.val(jQuery(select).val());
    }
  }

  function splitterChange(input){
    var value = parseInt(jQuery(input).val());

    var signal_input = jQuery(input).closest('table').find('.signal');
    if(signal_input.length > 0){
      jQuery(".splitter_type").html('('+splitter_data[keys_array[value]]+')');
      signal_input.val(keys_array[value]);
    }
  }


  function add_row(type) {
    var table = jQuery('#'+type.toUpperCase()+'_');
    if (table.find("tbody").length === 0) {
      table.append('<tbody></tbody>')
    }
    table.find("tbody").append('<tr><td><input type="text" class="form-control""></td><td><input type="text" name="'+type+'^*" class="form-control v_input" ></td></tr>')
  }

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

</script>