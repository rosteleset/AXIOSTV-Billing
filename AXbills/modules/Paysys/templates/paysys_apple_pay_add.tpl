<script>
  // define properties of config
  var applePayConfig = {
    country: '',
    currency: '',
    label: '',
    merchant: '',
    paysysId: 0,
  };
  async function onApplePayButtonClicked() {
    try {
      applePayConfig = JSON.parse('%APPLE_PAY_CONFIG%');
    } catch (err) {
      console.log('JSON parse error.');
    }

    const val = document.getElementById('sum')?.value;
    const sum = val == 0 ? 1 : val;

    const paymentMethodData = [{
      'supportedMethods': 'https://apple.com/apple-pay',
      'data': {
        'version': 3,
        'merchantIdentifier': applePayConfig.merchant,
        'merchantCapabilities': [
          'supports3DS'
        ],
        'supportedNetworks': [
          'amex',
          'discover',
          'masterCard',
          'visa'
        ],
        'countryCode': applePayConfig.country
      }
    }];

    const paymentDetails = {
      'total': {
        'label': applePayConfig.label,
        'amount': {
          'value': sum,
          'currency': applePayConfig.currency
        }
      }
    };

    const paymentOptions = {
      'requestPayerName': false,
      'requestBillingAddress': false,
      'requestPayerEmail': false,
      'requestPayerPhone': false,
      'requestShipping': false,
      'shippingType': 'shipping'
    };

    try {
      const request = new PaymentRequest(paymentMethodData, paymentDetails, paymentOptions);

      request.onmerchantvalidation = event => {
        validateMerchant().then(merchantSessionPromise => {
          event.complete(merchantSessionPromise);
        });
      };

      request.onpaymentmethodchange = event => {
        if (event.methodDetails.type !== undefined) {
          const paymentDetailsUpdate = {
            'total': paymentDetails.total
          };
          event.updateWith(paymentDetailsUpdate);
        } else if (event.methodDetails.couponCode !== undefined) {
          const total = calculateTotal(event.methodDetails.couponCode);
          const displayItems = calculateDisplayItem(event.methodDetails.couponCode);
          const shippingOptions = calculateShippingOptions(event.methodDetails.couponCode);
          const error = calculateError(event.methodDetails.couponCode);

          event.updateWith({
            total: total,
            displayItems: displayItems,
            shippingOptions: shippingOptions,
            modifiers: [
              {
                data: {
                  additionalShippingMethods: shippingOptions,
                },
              },
            ],
            error: error,
          });
        }
      };

      request.onshippingoptionchange = event => {
        const paymentDetailsUpdate = {
          'total': paymentDetails.total
        };
        event.updateWith(paymentDetailsUpdate);
      };

      request.onshippingaddresschange = event => {
        const paymentDetailsUpdate = {};
        event.updateWith(paymentDetailsUpdate);
      };

      const response = await request.show();
      const paymentProcess = await makePayment(response, sum);

      let status = 'success';

      if (paymentProcess?.error || paymentProcess?.errno) {
        status = 'fail';
      }
      await response.complete(status);
    } catch (e) {
      // console.log(e);
    }
  }

  async function validateMerchant() {
    try {
      return await (
        await fetch(
          `${window['BASE_URL']}/api.cgi/user/paysys/applePay/session/`,
          {
            method: 'POST',
            headers: {
              Accept: 'application/json',
              'Content-Type': 'application/json',
              USERSID: window['SID'],
            },
          },
        )
      ).json();
    } catch (e) {
      // console.log(e)
    }
  }

  async function makePayment(paymentResponse, sum) {
    const request = {
      sum: sum,
      apay: paymentResponse,
      systemId: applePayConfig.paysysId,
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
      return {
        error: 1
      };
    }
  }
</script>

<script src='https://applepay.cdn-apple.com/jsapi/v1/apple-pay-sdk.js'></script>

<style>
  apple-pay-button {
    --apple-pay-button-height: 45px;
    width: 100%;
  }
</style>
