<head>
  <link rel="stylesheet" href="/styles/default/css/adminlte.min.css">
  <meta charset="utf-8">
</head>

<style type="text/css">
  .border{
    border: 1px solid rgb(221, 221, 221);
    padding: 5px;
  }

</style>
<body>
  <div class="center-block" style="width: 80%">
    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <th class="text-center">_{USER_INFO}_</th>
      </tr>
    </table>
    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <th style="width: 50%">_{FIO}_/_{COMPANY}_</th>
        <td>%FIO%</td>
      </tr>

      <tr>
        <th>_{ADDRESS}_</th>
        <td>%ADDRESS_FULL%</td>
      </tr>

      <tr>
        <th>_{PHONE}_</th>
        <td>%PHONE_ALL%</td>
      </tr>

      <tr>
        <th>_{CELL_PHONE}_</th>
        <td>%CELL_PHONE_ALL%</td>
      </tr>

      <tr>
        <th>_{LOGIN}_</th>
        <td>%LOGIN%</td>
      </tr>

      <tr>
        <th>_{PASSWD}_</th>
        <td>%PASSWORD%</td>
      </tr>

    </table>

    <!-- Ticket info-->

    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <th class="text-center">_{TASK}_</th>
      </tr>
    </table>
    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <th>_{SUBJECT}_</th>
        <td>%MSG_SUBJECT%</td>
      </tr>
      <tr>
        <th style="width: 50%">_{CREATED}_</th>
        <td>%MSG_DATE_CREATE%</td>
      </tr>

      <tr>
        <th>_{STATE}_</th>
        <td>%MSG_STATE%</td>
      </tr>

      <tr>
        <th>_{PRIORITY}_</th>
        <td>%MSG_PRIORITY%</td>
      </tr>

      <tr>
        <th>_{CHAPTER}_</th>
        <td>%MSG_CHAPTER_NAME%</td>
      </tr>
    </table>

    <!-- Messege list  -->

    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <th class="text-center">_{RESPOSIBLE}_</th>
      </tr>
    </table>

    %TABLE%

    <!-- Global info about ticket -->

    <table class="table table-bordered" style="margin-bottom:0px">
      <tr>
        <td >
          <br>
          _{RESPOSIBLE}_: %RESPOSIBLE%
        </td>
      </tr>
    </table>

  </div>

</body>