<form method='POST' action='_{URL}_' >
    Cумма оплаты: 
      <input type='text' name='sum' value='_{PAYMENT_AMOUNT}_'readonly/> <br />
    Номер заказа: 
      <input type='text' name='orderid' value='_{TRANSACTION_ID}_'readonly/> <br />
    Название услуги: 
      <input type='text' name='service_name' value='Тестовая оплата'readonly/> <br />
    <input type='submit' value='Перейти к оплате' />
  </form>