<div class='card card-primary card-outline'>
  <div class='card-header with-border'>
    <h3 class='card-title'>_{INTERNET}_ (%ID%)</h3>
    <div class='card-tools float-right'>
      <button type='button' class='btn btn-tool' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
      </button>
    </div>
  </div>
  <div class='card-body table-responsive p-0'>
    %PAYMENT_MESSAGE%
    %NEXT_FEES_WARNING%
    %TP_CHANGE_WARNING%
    %SERVICE_EXPIRE_DATE%
	%ONLINE_TABLE%
	%LAST_LOGIN_MSG%
    <table class='table table-bordered table-sm'>
      <tr>
        <td>_{STATUS}_</td>
        <td><span class='%STATUS_FIELD%'>%STATUS_VALUE%</span>%HOLDUP_BTN%%STATUS_BTN%</td>
      </tr>
      <tr>
        <td><strong>_{TARIF_PLAN}_</strong></td>
        <td><strong>%TP_NAME%%TP_CHANGE%</strong></td>
      </tr>
      <tr>
        <td>_{DESCRIBE}_</td>
        <td>%COMMENTS%</td>
      </tr>
      %EXTRA_FIELDS%
    </table>
    %PREPAID_INFO%
  </div>
</div>