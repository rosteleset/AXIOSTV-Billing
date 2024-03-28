<form action='$SELF_URL' method='post'>
  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='chg' value='%ID%'>
  <input type='hidden' name='OLD_SUBJECT' value='%SUBJECT%'>

  <div class='card'>
    <div class='card-header'>
      <h3 class='card-title'>_{SUBJECT}_</h3>
    </div>
    <div class='card-body'>
      <input class='form-control' type='text' id='CHANGE_SUBJECT' name='SUBJECT' value='%SUBJECT%' autofocus>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='CHANGE_SUBJECT' value='_{CHANGE}_'>
    </div>
  </div>
</form>

<script>
  jQuery(function () {
    let subjectInput = jQuery('#CHANGE_SUBJECT');
    let subject = subjectInput.val();
    subjectInput.val(subject.replaceAll('\\\"', '\"'))
    subjectInput.val(subject.replaceAll('\\\'', '\''))
  });
</script>