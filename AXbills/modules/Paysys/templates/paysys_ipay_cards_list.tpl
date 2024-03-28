<style>
  table tr:hover {
    background-color: #ddd;
    cursor: pointer;
  }

  #add-card:hover > span {
    color: #ffffff !important;
  }

  #add-card > #add-card-icon {
    font-size: 18px;
    margin-top: 2px;
  }

  #add-card > #add-card-text {
    color: #43464d;
  }
</style>

<h5 class='text-center m-2'>Список платіжних карток</h5>

<table class='table'>
  <thead>
  <tr style='color: #64676a'>
    <th scope='col'>Вибрана картка</th>
    <th scope='col'>Назва</th>
    <th scope='col'>Номер картки</th>
    <th scope='col'>Картка активна</th>
    <th scope='col'></th>
  </tr>
  </thead>
  <tbody>
    %CARDS%
  </tbody>
</table>
<form name='ipay_pay_form' id='ipay_pay_form' method='post'>
  <input type='hidden' id='CARD_ALIAS' name='CARD_ALIAS' value='%CARD_ALIAS%'/>
  <div class='d-flex justify-content-between m-3'>
    <a href='%ADD_CARD%' id='add-card' class='btn btn-outline-success d-flex'>
      <span class='fas text-success fa-plus' id='add-card-icon'></span>
      <span class='ml-2' id='add-card-text'>_{ADD_CARD}_<span>
    </a>
    <input type='submit' class='btn btn-primary double_click_check' id='%SUBMIT_NAME%'
           name='%SUBMIT_NAME%' value='_{PAY}_'/>
  </div>
</form>

<script>
  function changeActiveCard(name) {
    Array.from(document.getElementsByClassName('ipay-btn')).map(e => {
      e.classList.remove('table-info');
      if (e.firstElementChild.firstElementChild) {
        e.firstElementChild.firstElementChild.remove();
      }
    });
    document.getElementById(name).classList.add('table-info');
    var elem = document.createElement('span');
    elem.classList.add('fa', 'fa-check', 'text-success');
    document.getElementById(name).getElementsByTagName('td')[0].append(elem);
    document.getElementById('CARD_ALIAS').value = name;
  }
</script>
