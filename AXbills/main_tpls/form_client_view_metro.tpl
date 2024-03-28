<link rel="stylesheet" type="text/css" href="/styles/default/fonts/google-static/Roboto.css">
<link rel="stylesheet" type="text/css" href="/styles/default/css/infopanels.css">

<div class="row dynamicTile">
    <div class="row">
        <div id="infoPanelsDiv"></div>
    </div>
</div>

<!-- InfoPanels -->
<script type='text/javascript' src='/styles/default/js/infopanels.js'></script>

<script>
    var panels = JSON.parse('%METRO_PANELS%');
    if (panels.length > 0){
        jQuery.each(panels, function (index, entry) {
            AInfoPanels.InfoPanelsArray.push(entry);
        });

        Events.emit('infoPanels_renewed', true);
    }
</script>
