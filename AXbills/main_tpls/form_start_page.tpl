<style>
  .start-panel {
    display: block;
    padding-left: 3px;
    padding-right: 3px;
  }

  .start-panel > .card:not(.collapsed-card-widget) > div.card-body {
    height: 270px;
  }

  .start-panel .card .card-header {
    cursor: move;
  }

  #sortable {
    padding: .5rem .3rem 0;
  }

</style>
<form action='$SELF_URL' method='post' id='FORM_QUICK_REPORT_POSITION'>
  <input type='hidden' name='AWEB_OPTIONS' value='1'/>
  <input type='hidden' name='QUICK' value='1'/>
</form>
<div class="row" id='sortable'>
  %INFO%
</div>
<script>
  jQuery(function () {

    var sortable_wrapper = jQuery("#sortable");

    /*sortable card*/
    sortable_wrapper.sortable(
        {
          cancel: ".card-body",
          scroll: true,
          helper: "clone",
          cursor: "move"
        }
    );

    /* Save order after moving panels */
    sortable_wrapper.on("sortupdate", function (event, ui) {
      var formData = '';

      // Collect panels order
      jQuery(".start-panel").map(function (indx, element) {
        formData += '&QUICK_REPORTS_SORT=' + jQuery(element).attr('id');
      });

      formData += "&AWEB_OPTIONS=1&QUICK=1";

      /* Send Data */
      jQuery.post('/admin/index.cgi', formData, function (data) { });
    });

  });

</script>
