<style type="text/css">
  .calend{
    max-width:1000px;
  }
</style>

<div class='card box-info calend'>

<div class='card-header with-border '>

  <a href='/admin/index.cgi?index=$index&year=%LAST_YEAR%&month=%LAST_MONTH%'>
    <button type='submit' class='btn btn-secondary btn-xs' align='left'>
      <span class="fa fa-arrow-left" aria-hidden="true"></span>
    </button>
  </a>
  <label class='control-label'>%MONTH% %YEAR%</label>
  
  <a href='/admin/index.cgi?index=$index&year=%NEXT_YEAR%&month=%NEXT_MONTH%'>
    <button type='submit' class='btn btn-secondary btn-xs' align='right'>
      <span class="fa fa-arrow-right" aria-hidden="true"></span>
    </button>
  </a>

</div>

<div class='table-responsive text-center' >
  <table class='table table-bordered no-highlight'>
    <thead>
      <tr>
        <td>Пн</td>
        <td>Вт</td>
        <td>Ср</td>
        <td>Чт</td>
        <td>Пт</td>
        <td class='danger'>Сб</td>
        <td class='danger'>Вс</td>
      </tr>
    </thead>
    <tbody>
      %DAYS%
    </tbody>
  </table>
</div>

</div>

