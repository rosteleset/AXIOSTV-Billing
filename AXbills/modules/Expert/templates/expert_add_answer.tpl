<form action='$SELF_URL' method='post'>
  <input type='hidden' name='index' value='%INDEX%'>
  <input type='hidden' name='ID' value='%PARRENT_ID%'>
  <input type='hidden' name='ANSWER_ID' value='%ANSWER_ID%'>

  <div class='card'>
    <div class='card-header'>_{ADD}_</div>
    <div class='card-body'>
      <b>_{QUESTION_NUM}_: </b><input class='form-control' type='text' name='PARRENT_ID' value='%PARRENT_ID%'>
      <b>_{QUESTION_ANSWER}_: </b><input class='form-control' type='text' name='ANSWER' value='%ANSWER%' autofocus>
    </div>
    <div class='card-footer'>
      <input class='btn btn-primary' type='submit' name='%BUTTON_NAME%' value='%BUTTON_VALUE%'>
    </div>
  </div>
</form>
