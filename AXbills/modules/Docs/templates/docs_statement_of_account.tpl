<!DOCTYPE html>
<html lang='en'>
<head>
  <meta charset='utf-8'>
  <title>_{STATEMENT_OF_ACCOUNT}_</title>
  <link href='/styles/default/css/adminlte.min.css' rel='stylesheet'>
</head>
<script language='JavaScript'>
  function autoReload() {
    document.docs_statment_account.submit();
  }
</script>
<body>

<div class='content'>
  <div class='container'>

    <div class='row d-print-none'>
      <form action='%SELF_URL%' name='docs_statment_account' class='form-inline'>
        <input type=hidden name='qindex' value=15>
        <input type=hidden name='STATMENT_ACCOUNT' value=1>
        <input type=hidden name='UID' value=%UID%>
        <input type=hidden name='header' value='2'>
        %YEAR_SEL%
        <a href='javascript:window.print();' class='btn btn-light border fas fa-print mt-1 mr-2'>_{PRINT}_</a>
        %UPLOAD_XML%
      </form>
    </div>

    <div class='row'>
      <div class='row col-md-12 invoice-info'>
        <h3>%COMPANY_NAME% </h3>
        <div class='row col-md-6 invoice-col'>

          <div class='col-md-6 text-right'>
            <b>_{MAIL_ADDRESS}_:</b> <br>
            <b>_{ADDRESS}_:</b> <br>
            <br>
          </div>

          <div class='col-md-6 text-left'>
            <u>%ADDRESS_STREET% %ADDRESS_BUILD% %ADDRESS_FLAT% </u> <br>
            <u>%ADDRESS_STREET% %ADDRESS_BUILD% %ADDRESS_FLAT%</u> <br>
            %DISTRICT%, %CITY%, %ZIP% <br>
          </div>

        </div>

        <div class='row col-md-6 invoice-col'>

          <div class='col-md-6 text-right'>
            <b>_{PHONE}_:</b> <br>
            <b>_{FAX}_:</b> <br>
            <b>E-mail:</b> <br>
          </div>

          <div class='col-md-6 text-left'>
            %PHONE% <br>
            %_fax% <br>
            %EMAIL% <br>
          </div>

        </div>

        <div class='col-md-12 text-center'>
          <br>
          <h4>_{STATEMENT_OF_ACCOUNT}_</h4>
          _{FOR_TIME}_ _{FROM}_ %PERIOD_FROM% _{TO}_ %PERIOD_TO%
        </div>

        <div class='row col-md-6 float-left'>
          <div class='col-md-6 text-right'>
            <br>
            <b>_{NUMBER_STATEMENT}_:</b> <br>
            <b>_{DATE}_:</b> <br>
            <b>_{CODE_CLIENT}_: </b>
            <br>
          </div>
          <div class='col-md-6 text-left'>
            <br>%UID%_%DATE%<br>
            <b>%DATE% </b><br>
            <b>%UID%</b>
            <br>
          </div>

        </div>

        <div class='row col-md-6 float-right'>
          <div class='col-md-6 text-right'>
            <br>
            <b>_{PAYER}_:</b>
            <br>

          </div>
          <div class='col-md-6 text-left'>
            <br> %FIO% <br>
            %COMPANY_NAME%<br>
            %ADDRESS_STREET% %ADDRESS_BUILD% %ADDRESS_FLAT% <br>

            %DISTRICT%, %CITY%, %ZIP% <br>

          </div>
        </div>
      </div> <!-- /row -->
    </div>


    <div class='row col-md-12'>
      <table class='table table-striped'>
        <thead>
        <tr>
          <th>_{DATE}_</th>
          <th>_{LOGIN}_</th>
          <th>_{BILL_ACCOUNT}_</th>
          <th>_{ACCOUNT}_</th>
          <th>_{DESCRIBE}_</th>
          <th>_{FEE}_</th>
          <th>_{PAYMENT}_</th>
          <th>_{BALANCE}_</th>
        </tr>
        </thead>
        <tbody>
        %ROWS%
        </tbody>
      </table>

      <H4>_{DEPOSIT}_: %DEPOSIT% </H4>

    </div>


  </div> <!-- /container -->
</div>


</body>
</html>
