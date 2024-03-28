/**
 * 
 * Created by devasx666 on 07.10.2020.
 * 
 * The file is designed to be able to select the 
 * priority of launching the plugin
 * 
 */

$(() => {
  function renderPluginsBlock(plugin_array) {
    plugin_raw.sort((a, b) => (a.priority - b.priority));

    $plugins_wrapper.empty();

    $.each(plugin_array, (i, plugin) => {
      $plugins_wrapper.append(renderPlugin(plugin, i));
    });

    $plugins_wrapper.find('input').on('input', () => {
      setPluginsChangedStatus(true);
    });

    $plugins_wrapper.sortable({
      update: () => {
        setPluginsChangedStatus(true);
      }
    });
  }

  window.renewPlugins = renderPluginsBlock;

  function parseCurrentDisplayedPlugins(aid) {
    var $inputs = $plugins_wrapper.find('input');
    var result = [ ];

    $.each($inputs, (index, plugin) => {
      var $plugin = $(plugin);

      result.push({
        TYPE_ID    : $plugin.attr('name'),
        VALUE      : $plugin.val(),
        PRIORITY   : index,
        AID        : aid
      });
    });

    return result;
  }

  function showDefaultTypesIfNotPresent(plugin_raw, types) {
    var types_present = [ ];

    $.each(plugin_raw, (_i, plugin) => {
      types_present[plugin.type_id] = 1;
    });

    $.each(types, (_i, type) => {
      if (type.is_default == '1' && !types_present[type.id]) {
        plugin_raw.push({
          type_id: type.id,
          name: type.name,
          is_default: true,
          value: '',
          priority: 10
        });
      }
    });
  }

  function renderPlugin(plugin_json, position) {
    plugin_json.form = 'some_random_input';
    plugin_json.name = getPluginTypeName(plugin_json.type_id);
    
    plugin_json.is_default = (plugin_json.is_default === "1");

    plugin_json.position = position;
    var rendered = Mustache.render(plugin_template, plugin_json);
    
    return $(rendered);
  }

  function getPluginTypeName(type_id) {
    return plugin_types[type_id].name;
  }

  function submitPlugins(e) {
    e.preventDefault();

    var $sub_btn_icon = $sub_btn.find('span');

    $sub_btn.prop('disabled', true);
    $sub_btn_icon.attr('class', 'fa fa-spinner fa-pulse');

    var request = null;

    if (PLUGIN_JSON.options.aid) {
      var plugin_to_send = parseCurrentDisplayedPlugins(PLUGIN_JSON.options.aid);

      request = {
        'qindex': options.callback_index,
        'header': 2,
        'aid': options.aid,
        'PLUGINS': JSON.stringify(plugin_to_send)
      };
    } else {
      (new ATooltip()).displayError("Error send request!");
    }

    $.post(SELF_URL, request, (data) => {
      var object = null;

      try {
        object = JSON.parse(data);
      }
      catch (JSONParseError) {
        (new ATooltip()).displayError("Error parse JSON! Not Valid JSON");
      }

      $sub_btn.prop('disabled', false);
      $sub_btn_icon.attr('class', 'fa fa-check');

      if (object === null)
        return false;

      $plugins_response.text(object.message);

      if (object.status === 0) {
        setTimeout(() => {
          $plugins_response.text('');
        }, 3000);
        setPluginsChangedStatus(false);
      }
      else {
        (new ATooltip()).displayError("Error! Not valid status");
        return false;
      }
    });
  }

  function setPluginsChangedStatus(boolean) {
    if (boolean) {
      if ($sub_btn.data('active') !== true) {
        $sub_btn.data('active', true);
        $sub_btn
          .fadeOut(300)
          .attr('class', 'btn btn-xs btn-warning')
          .fadeIn(300);
      }
    }
    else {
      $sub_btn.attr('class', 'btn btn-xs btn-primary disabled');
      $sub_btn.data('active', false);
    }
  }

  var $plugins_controls = $('#plugins_controls');
  var $plugins_wrapper = $('#plugins_wrapper');

  var $sub_btn = $plugins_controls.find('#plugin_submit');

  var $plugins_response = $plugins_controls.find('#plugins_response');

  var plugin_raw = PLUGIN_JSON.plugins || [ ];
  var options = PLUGIN_JSON.options;

  var plugin_types = { };

  $.each(options.types, (_, e) => {
    plugin_types[e.id] = e;
  });

  var plugin_template = $('#plugin_template').html();
  
  Mustache.parse(plugin_template);

  showDefaultTypesIfNotPresent(plugin_raw, options.types);

  renderPluginsBlock(plugin_raw);

  $sub_btn.on('click', submitPlugins);
});
