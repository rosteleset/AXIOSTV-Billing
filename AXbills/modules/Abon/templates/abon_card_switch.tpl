<div class='row justify-content-end px-2 pb-2'>
  <div class='justify-content-start col-md-4'>
    %CATEGORY_SELECT%
  </div>
  <div class='btn-group' role='group' aria-label='Abon card switch'>
    <a href='%LINK_TO_TABLE%' class='btn %TABLE_BUTTON_CLASS%'>
      <i class='fas fa-list'></i>
    </a>
    <a href='%LINK_TO_CARD%' class='btn %CARD_BUTTON_CLASS%'>
      <i class='fas fa-th-large'></i>
    </a>
  </div>
</div>


<script>

  function updateURL() {
    var selectElement = document.getElementById('CATEGORY_SEL');
    var selectedValue = selectElement.value;

    var url = new URL(window.location.href);
    url.searchParams.delete('CATEGORY_ID');
    var updatedUrl = url + '&CATEGORY_ID=' + selectedValue;
    window.location.href = updatedUrl;
  }

</script>