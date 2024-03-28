<div class='card card-primary card-outline'>
  <div class='card-header with-border text-center pb-0'>
    <h4>_{BALANCE_RECHARCHE}_</h4>
  </div>
  <div class='card-body'>
    <div class='text-center mt-3'>
      <div id='paypal-button-container'></div>
    </div>
    <script src='%BUTTON_LINK%'
            data-sdk-integration-source='button-factory'>
    </script>
    <script>
      {
        paypal.Buttons({
          style: {
            shape: 'rect',
            color: 'blue',
            layout: 'vertical',
            label: 'pay',
          },

          createOrder: function (data, actions) {
            return actions.order.create({
              purchase_units: JSON.parse('%PURCHASE_UNITS%')
            });
          },

          onApprove: function (data, actions) {
            return actions.order.capture().then(function (orderData) {
              const url = `%SUCCESS_URL%&PAYPAL_ORDER_ID=${orderData.id}`
              actions.redirect(url);
            });
          },

          onError: function (err) {
            console.log(err);
          }
        }).render('#paypal-button-container');
      }
    </script>
  </div>
</div>
