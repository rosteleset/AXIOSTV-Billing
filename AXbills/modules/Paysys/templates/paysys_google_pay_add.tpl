<script>
  var googlePayConfig;
  try {
    googlePayConfig = JSON.parse('%GOOGLE_PAY_CONFIG%');
  } catch (err) {
    console.log('JSON parse error.');
  }

  var UID = '%UID%';

  var baseRequest = {
    apiVersion: 2,
    apiVersionMinor: 0,
  };

  if (googlePayConfig?.parameters?.gateway === 'stripe') {
    googlePayConfig.parameters['stripe:publishableKey'] = googlePayConfig?.parameters?.stripe?.publishableKey;
    googlePayConfig.parameters["stripe:version"] = googlePayConfig?.parameters?.stripe?.version;
    delete googlePayConfig?.parameters?.stripe
  }

  var tokenizationSpecification = {
    type: 'PAYMENT_GATEWAY',
    parameters: googlePayConfig.parameters || {gateway: 'unknown'}
  };

  var baseCardPaymentMethod = {
    type: 'CARD',
    parameters: {
      allowedAuthMethods: ['PAN_ONLY', 'CRYPTOGRAM_3DS'],
      allowedCardNetworks: ['MASTERCARD', 'VISA'],
    },
  };

  var readyToPay = {
    ...baseRequest,
    allowedPaymentMethods: [baseCardPaymentMethod]
  }

  var cardPaymentMethod = Object.assign({}, baseCardPaymentMethod, {
    tokenizationSpecification: tokenizationSpecification,
  });

  var paymentsClient = null;

  function getGooglePaymentDataRequest() {
    const paymentDataRequest = Object.assign({}, baseRequest);
    paymentDataRequest.allowedPaymentMethods = [cardPaymentMethod];
    paymentDataRequest.transactionInfo = getGoogleTransactionInfo();
    paymentDataRequest.merchantInfo = googlePayConfig.merchantInfo;
    return paymentDataRequest;
  }

  function getGooglePaymentsClient() {
    if (paymentsClient === null) {
      paymentsClient = new google.payments.api.PaymentsClient({
        environment: googlePayConfig.environment,
      });
    }
    return paymentsClient;
  }

  function onGooglePayLoaded() {
    const paymentsClient = getGooglePaymentsClient();
    paymentsClient
      .isReadyToPay(readyToPay)
      .then(response => {
        if (response.result) {
          addGooglePayButton();
          prefetchGooglePaymentData();
        }
      })
      .catch(err => {
        // console.error(err);
      });
  }

  function addGooglePayButton() {
    const paymentsClient = getGooglePaymentsClient();
    const button = paymentsClient.createButton({
      onClick: onGooglePaymentButtonClicked,
      allowedPaymentMethods: [baseCardPaymentMethod],
      buttonSizeMode: 'fill',
      buttonColor: 'default',
    });
    if (document.getElementById('GooglePay')) {
      document.getElementById('GooglePay').appendChild(button);
    }
  }

  function getGoogleTransactionInfo() {
    return {
      currencyCode: googlePayConfig.currencyCode,
      totalPriceStatus: 'FINAL',
      totalPrice: document.getElementById('sum')?.value || 1,
    };
  }

  function prefetchGooglePaymentData() {
    const paymentDataRequest = getGooglePaymentDataRequest();
    paymentDataRequest.transaction = {
      totalPriceStatus: 'NOT_CURRENTLY_KNOWN',
      currencyCode: googlePayConfig.currencyCode,
    };
    const paymentsClient = getGooglePaymentsClient();
    paymentsClient.prefetchPaymentData(paymentDataRequest);
  }

  function onGooglePaymentButtonClicked() {
    const paymentDataRequest = getGooglePaymentDataRequest();
    paymentDataRequest.transactionInfo = getGoogleTransactionInfo();

    const paymentsClient = getGooglePaymentsClient();
    paymentsClient
      .loadPaymentData(paymentDataRequest)
      .then(async (paymentData) => {
        const res = await processPayment(paymentData);
        if (res?.redirectUrl) {
          document.location.href = res?.redirectUrl;
        }
        const sum = document.getElementById('sum')?.value;
        if (res) {
          jQuery('#sum-info').text(sum == 0 ? 1 : sum);
          jQuery('#transaction-info').text(res.transactionId);
          jQuery('#modal').modal('show');
        }
      })
      .catch(err => {
        // console.error(err);
      });
  }

  async function processPayment(paymentData) {
    paymentData.paymentMethodData.tokenizationData.token = btoa(unescape(encodeURIComponent(paymentData.paymentMethodData.tokenizationData.token)));

    const request = {
      sum: document.getElementById('sum').value || 1,
      gpay: paymentData,
      systemId: googlePayConfig.paysysId,
      returnUrl: 1
    };

    try {
      return await (
        await fetch(
          `${window['BASE_URL']}/api.cgi/user/paysys/pay/`,
          {
            method: 'POST',
            headers: {
              Accept: 'application/json',
              'Content-Type': 'application/json',
              USERSID: window['SID'],
            },
            body: JSON.stringify(request),
          },
        )
      ).json();
    } catch (e) {
      // console.log(e);
    }
  }
</script>

<script
        src='https://pay.google.com/gp/p/js/pay.js'
        onload='onGooglePayLoaded()'>
</script>

<style>
  #GooglePay {
    height: 45px;
  }
</style>
