<style>
  .pagination {
    display: inline-block;
  }

  .pagination a {
    float: left;
    padding: 8px 16px;
    text-decoration: none;
  }

  .pagination a:hover:not(.active) {
    background-color: #ddd;
    color: black;
    border-radius: 5px;
  }
</style>

<form method='get' action='$SELF_URL' name='PAGE_IPPOOLS' id='PAGE_IPPOOLS'>
  <input type='hidden' name='%PG_INDEX%' id='pg_index' value='%PG_INDEX%'/>
  <div class='pagination'>
    <a href='%FAST_FIST_PAGE%'>&laquo;</a>
    <a href='%FIRST_PAGE%' id='btn_page_0' class='btn btn-default active'>1</a>
    %PAGE_IP_POOLS%
    <a href='%FAST_END_PAGE%'>&raquo;</a>
  </div>
</form>

<script>
  jQuery(function() {
    var id = jQuery('#pg_index').val();

    jQuery('.active').removeClass('active');
    jQuery('#btn_page_' + id).addClass('active');
  });
</script>
