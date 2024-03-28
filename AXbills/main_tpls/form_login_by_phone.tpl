<div id='LOGIN_BY_PHONE_CONTAINER' class='d-none'>
  <input type='hidden' name='LOGIN_BY_PHONE' value='1'>

  <div class='form-group' id='MESSAGE_BLOCK'></div>

  <div id='LOGIN_BY_PHONE_INPUT_DATA'>
    <div class='row p-0 m-0'>
      <div class='input-group'>
        <input id='PHONE_PATTERN_FIELD' name='PHONE_PATTERN_FIELD' value='' required placeholder='_{PHONE}_'
          class='form-control' data-phone-field='PHONE' data-check-phone-pattern='%PHONE_NUMBER_PATTERN%' type='text'
          autocomplete='off'>
        <input id='PHONE' name='PHONE' value='' class='form-control' type='hidden'>
        <div class='input-group-append'>
          <div class='input-group-text'>
            <span class='input-group-addon fa fa-phone'></span>
          </div>
        </div>
      </div>
    </div>

    <div class='row p-0 m-0 d-none' id='PIN_BLOCK'>
      <div class='input-group'>
        <input type='text' id='PIN_CODE' name='PIN_CODE' value='' class='form-control' placeholder='Pin'
          autocomplete='off'>
        <div class='input-group-append'>
          <div class='input-group-text'>
            <span class='input-group-addon fa fa-key'></span>
          </div>
        </div>
      </div>
    </div>

    <div class='row p-0 m-0'>
      <span class='w-100 text-muted' id='timerShow'></span>
    </div>

    <button class='btn btn-primary d-none' name='CONFIRM_PIN' id='CONFIRM_PIN'>_{CONFIRM}_ PIN</button>
    <button class='btn btn-primary' name='SEND_PIN' id='SEND_PIN'>_{SEND}_</button>
    <button class='btn btn-primary' name='EXIST_PIN' id='EXIST_PIN'>_{ALREADY_HAVE_A_PIN}_</button>
  </div>
  <button class='btn btn-default' name='BACK_TO_LOGIN' id='BACK_TO_LOGIN'>_{BACK_TO_LOGIN_WITH_PASSWORD}_</button>
</div>

<script>

  jQuery('#LOGIN_BY_PHONE').on('click', function (e) {
    e.preventDefault();

    jQuery('#MAIN_CONTAINER').addClass('d-none');
    jQuery('#LOGIN_BY_PHONE_CONTAINER').removeClass('d-none');
  })

  jQuery('#BACK_TO_LOGIN').on('click', function () {
    jQuery('#MAIN_CONTAINER').removeClass('d-none');
    jQuery('#LOGIN_BY_PHONE_CONTAINER').addClass('d-none');
  })

  let event = document.createEvent('Event');
  event.initEvent('input', true, true);
  document.getElementById('PHONE').dispatchEvent(event);

  let canSendPin = true;
  let uid = 0;
  let startTimeSeconds = 120;
  let timeSeconds = startTimeSeconds;
  let phone = '';

  jQuery('#SEND_PIN').on('click', sendPin);

  jQuery('#EXIST_PIN').on('click', function (e) {
    jQuery('#PIN_BLOCK').removeClass('d-none');
    jQuery('#CONFIRM_PIN').removeClass('d-none');
    jQuery('#EXIST_PIN').addClass('d-none');
    jQuery('#MESSAGE_BLOCK').html('');
    jQuery('#PIN_CODE').val('');
    jQuery('#timerShow').html('');
    e.preventDefault();
  });

  jQuery('#CONFIRM_PIN').on('click', function (e) {
    e.preventDefault();

    canSendPin = false;
    phone = jQuery('#PHONE').val().replace(/\D/g, '');
    jQuery.post('/index.cgi', {
      header: 2,
      LOGIN_BY_PHONE: 1,
      PHONE: phone,
      PIN_ALREADY_EXIST: 1
    }, function (result) {
      if (result.uid !== undefined) {
        uid = result.uid;
        jQuery.post('/index.cgi', {
          header: 2,
          LOGIN_BY_PHONE: 1,
          PIN_CODE: jQuery('#PIN_CODE').val(),
          UID: uid,
          PHONE: phone
        }, function (result) {
          if (result.users !== undefined) {
            if (result.users.length === 1) {
              window.location.replace(result.users[0].url);
            } else {
              loginButtons(result.users);
            }
          } else if (result.message !== undefined) {
            jQuery('#MESSAGE_BLOCK').html(jQuery(`<div class='alert alert-danger'>${result.message}</div>`));
          }
        });
      }
      if (result.message !== undefined) {
        jQuery('#MESSAGE_BLOCK').html(jQuery(`<div class='alert alert-danger'>${result.message}</div>`));
      }
      canSendPin = true;
    });
  });

  function loginButtons(users) {
    let loginsContainer = document.getElementById('MESSAGE_BLOCK');

    let message = document.createElement('div');
    message.classList.add('alert');
    message.classList.add('alert-info');
    message.innerText = '_{FOUND_SEVERAL_USERS}_';
    loginsContainer.appendChild(message);

    users.forEach(user => {
      let button = document.createElement('a');
      button.href = user.url;
      button.text = user.login;
      button.classList.add('btn');
      button.classList.add('btn-primary');

      loginsContainer.appendChild(button);
    });

    document.getElementById('LOGIN_BY_PHONE_INPUT_DATA').classList.add('d-none');
  }

  function sendPin(e) {
    jQuery('#MESSAGE_BLOCK').html('');
    jQuery('#PIN_CODE').val('');
    jQuery('#timerShow').html('');
    e.preventDefault();

    if (!canSendPin) return;
    phone = jQuery('#PHONE').val().replace(/\D/g, '');
    jQuery.post('/index.cgi', { header: 2, LOGIN_BY_PHONE: 1, PHONE: phone }, function (result) {
      if (result.uid !== undefined) {
        let timer = setInterval(function () {
          let seconds = timeSeconds % 60
          let minutes = timeSeconds / 60 % 60
          if (timeSeconds <= 0) {
            clearInterval(timer);
            jQuery('#timerShow').html(jQuery(`<button class='btn btn-xs btn-default' id='SEND_PIN_AGAIN'>_{SEND_AGAIN}_</button>`));
            canSendPin = true;
            timeSeconds = startTimeSeconds;
            jQuery('#SEND_PIN_AGAIN').on('click', sendPin);
          } else {
            jQuery('#timerShow').html(`_{SEND_AGAIN}_... ${('0' + Math.trunc(minutes)).slice(-2)}:${('0' + seconds).slice(-2)}`);
          }
          --timeSeconds;
        }, 1000)

        uid = result.uid;
        jQuery('#PIN_BLOCK').removeClass('d-none');
        jQuery('#CONFIRM_PIN').removeClass('d-none');
        jQuery('#SEND_PIN').addClass('d-none');
        canSendPin = false;
      } else if (result.message !== undefined) {
        jQuery('#MESSAGE_BLOCK').html(jQuery(`<div class='alert alert-danger'>${result.message}</div>`));
      }
    });
  }
</script>