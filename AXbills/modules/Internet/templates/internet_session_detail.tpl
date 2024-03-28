<div class='col-md-12 col-sm-12'>
  <div class='col-md-6 col-sm-6'>
    <div class='card card-primary card-outline box-form'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{SESSIONS}_</h4>
          <div class="card-tools float-right">
            <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse">
              <i class="fa fa-minus"></i>
            </button>
          </div>
      </div>
      <div class='card-body'>
        <TABLE width=600 class='table table-striped'>
        <tr><td>_{SESSION_ID}_:</td><td>%SESSION_ID%</td></tr>
        <tr><td>_{BEGIN}_:</td><td align=right>%START%</td></tr>
        <tr><td>_{END}_:</td><td align=right>%STOP%</td></tr>
        <tr><td>_{DURATION}_</td><td align=right>%DURATION%</td></tr>
        <tr><td>_{TARIF_PLAN}_</td><td>[%TP_ID%] %TP_NAME%</td></tr>
        <tr><td>_{SENT}_ (%TRAFFIC_NAMES_0%):</td><td align=right>%_SENT% (%SENT%)</td></tr>
        <tr><td>_{RECV}_ (%TRAFFIC_NAMES_0%):</td><td  align=right>%_RECV% (%RECV%)</td></tr>
        <tr><td>_{SENT}_ 2 (%TRAFFIC_NAMES_1%):</td><td align=right>%_SENT2% (%SENT2%)</td></tr>
        <tr><td>_{RECV}_ 2 (%TRAFFIC_NAMES_1%):</td><td align=right>%_RECV2% (%RECV2%)</td></tr>
        <tr><td>IP:</td><td align=right>%IP%</td></tr>
        <tr><td>CID:</td><td align=right>%CID%</td></tr>
        </td></tr>
        </table>
      </div>
    </div>
  </div>
  <div class='col-md-6 col-sm-6'>
    <div class='card card-primary card-outline box-form '>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{NAS}_</h4>
          <div class="card-tools float-right">
            <button type="button" class="btn btn-secondary btn-xs" data-card-widget="collapse">
              <i class="fa fa-minus"></i>
            </button>
          </div>
      </div>
      <div class='card-body'>
        <TABLE width=600 class='table table-striped'>
          <tr><td>ID:</td><td>%NAS_ID%</td></tr>
          <tr><td>NAME</td><td>%NAS_NAME%</td></tr>
          <tr><td>IP:</td><td>%NAS_IP%</td></tr>
          <tr><td>PORT:</td><td>%NAS_PORT%</td></tr>
          <tr><td>_{TIME_TARIF}_:</td><td>%TIME_TARIFF%</td></tr>
          <tr><td>_{TRAF_TARIF}_:</td><td>%TRAF_TARIFF%</td></tr>
          <tr><td>_{SUM}_:</td><td>%SUM%</td></tr>
          <tr><td>_{BILL}_:</td><td>%BILL_ID%</td></tr>
          <tr><td>_{ACCT_TERMINATE_CAUSE}_:</td><td>%ACCT_TERMINATE_CAUSE%</td></tr>
          <tr><td colspan='2'>&nbsp;</td></tr>
          <tr><td align=center colspan=2>
          <a href='$SELF_URL?get_index=ipn_detail&UID=$FORM{UID}&FROM_DATE=%START%&TO_DATE=%STOP%&full=1&IP=%IP%&search=1' class='btn btn-primary btn-xs'>IP _{DETAIL}_</a>
          %RECALC%
          </td></tr>
        </table>
      </div>
    </div>
  </div>
</div>
