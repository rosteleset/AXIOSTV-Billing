<form name='IP_POOLS_CHECKBOXES_FORM' id='IP_POOLS_CHECKBOXES_FORM' method='get'>
  <input type='hidden' name='ids' id='ids_not_save' value='$FORM{ids}'/>
  <input type='hidden' name='ids_remove' id='ids_remove'/>
  %TABLE_IPPOOLS%
</form>

<script>
  var chkArray = [ ];
  jQuery('input[name=ids]:checkbox').each(function() {
    chkArray.push(jQuery(this).val());
  });

  jQuery('#ids_remove').val(chkArray.join(','));

  jQuery('#ids_not_save').val(
    remove_duplicates_es6(jQuery('#ids_not_save').val()
  ).join(', '))

  jQuery('#NAS_IP_POOLS_').on('change', (event) => {
    var ids = jQuery('#ids_not_save').val()

    if (event.target.checked === true) {
      var patt = new RegExp(event.target.value);
      if (!patt.test(ids)) {
        ids = `${ids}, ${event.target.value}`
      }
    }

    if (event.target.checked === false) {
      ids = ids.replaceAll(`${event.target.value}`, '')
    }

    ids = remove_duplicates_es6(ids).join(', ')

    jQuery('#ids_not_save').val(ids)
  });

  var idsArray = jQuery('#ids_not_save').val().split(", ")

  idsArray.forEach(element => {
    jQuery('.checked_ippool_' + element).attr('checked', true)
  });

  function remove_duplicates_es6(ids_dublicate) {
    ids_dublicate = ids_dublicate.split(', ')
    const result = ids_dublicate.filter(id => {
      if (id != "") {
        return ids_dublicate.includes(id)
      }
    })

    let s = new Set(result)
    let it = s.values()

    return Array.from(it)
  }
</script>
