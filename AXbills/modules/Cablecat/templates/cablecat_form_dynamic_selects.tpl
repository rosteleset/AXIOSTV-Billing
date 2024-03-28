<script src='/styles/default/js/dynamicForms.js'></script>

<div id="cablecat_choose_connection"></div>
<script>
  var cablecat_connection_chooser = new ModalSelectChooser('#cablecat_choose_connection', {
    event : 'Cablecat.connection_type_choosed',
    url : 'get_index=cablecat_modal_connection_type_search&AJAX=1',
    select : {
      label : '_{TYPE}_',
      id : 'TYPE',
      options : [
        {
          name : '--',
          value : ''
        },
        {
          name : 'Fiber',
          value : '1'
        },
        {
          name : 'Equipment',
          value : '2'
        },
        {
          name : 'Point',
          value : '3'
        },
        {
          name : 'Connecter',
          value : '4'
        },
        {
          name : 'Splitter',
          value : '5'
        }
      ]
    }
  });
</script>

<!--
0 => 'fiber',
1 => 'equipment',
2 => 'point_id',
3 => 'connecter',
4 => 'splitter'

# declare name of event where should send data

#all steps are declared as
## label, input_type, request_function, request_params

# if request function is absent or false, treat as end of search

# Append first select
# When value choosed, load next select with all previous values, while have next request function
-->
