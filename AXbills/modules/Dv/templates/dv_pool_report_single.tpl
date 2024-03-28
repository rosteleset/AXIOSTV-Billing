<style>
  table.table-labeled > tbody > tr > td:first-child {
    text-align: left;
    font-weight: bold;
  }

  table.table-labeled > tbody > tr > td:last-child {
    text-align: left;
  }

  div.padding-min {
    padding-right: 5px;
    padding-left: 5px;
  }
</style>
<div class='col-md-%COLS_SIZE% padding-min'>
  <div class='card card-primary card-outline'>
    <div class='card-header'><h4 class='card-header with-border'>%NAME%</h4></div>
    <div class='card-body'>
      <p>%IP_RANGE%</p>

      <table class='table table-labeled'>
        <tbody>
        <tr>
          <td>_{NAS}_</td>
          <td>%NAS_NAME%</td>
        </tr>
        <tr>
          <td>_{USED}_</td>
          <td>%USED%</td>
        </tr>
        <tr>
          <td>_{ERROR}_</td>
          <td>%ERROR% %</td>
        </tr>
        <tr>
          <td>_{FREE}_</td>
          <td>%FREE% %</td>
        </tr>
        </tbody>
      </table>

      <div class='row'>
        %USAGE_CHART%
      </div>

    </div>
  </div>
</div>