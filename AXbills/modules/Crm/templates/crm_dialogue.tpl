<input type='hidden' id='ADMIN_AVATAR_LINK' name='ADMIN_AVATAR_LINK' value='%ADMIN_AVATAR_LINK%'>
<input type='hidden' id='USER_AVATAR_LINK' name='USER_AVATAR_LINK' value='%USER_AVATAR_LINK%'>
<input type='hidden' id='AID' name='AID' value='%AID%'>
<input type='hidden' id='DIALOGUE_ID' name='DIALOGUE_ID' value='%DIALOGUE_ID%'>
<input type='hidden' id='LAST_MESSAGE_FROM_AID' name='LAST_MESSAGE_FROM_AID' value='%LAST_MESSAGE_FROM_AID%'>
<div class='row'>
  <div class='col-md-10'>
    <div class='container-fluid h-100'>
      <div class='row justify-content-center h-100'>

        <div class='col-md-12 col-xl-12 chat'>
          <div class='card'>
            <div class='card-header'>
              <h4 class='card-title'>%LEAD_FIO%</h4>
            </div>
            <div class='card-body msg_card_body pb-1' id='msg_block'>
              %MESSAGES%
            </div>
            <div class='card-footer'>
              <div class='row'>
                <div class='col-md-9'>
                  <textarea class='form-control type_msg h-100' placeholder='_{CRM_ENTER_YOUR_MESSAGE}_'
                            id='message-textarea' %DISABLE_TEXTAREA%></textarea>
                </div>
                <div class='col-md-3'>
                  %ACCEPT_DIALOGUE_BTN%
                  <div class='balance-buttons mt-2 mb-2 btn-group-vertical %HIDE_CONTROL_BTN%' id='control-btn'
                       style='width: 100%'>
                    <a class='btn btn-default btn-lg' id='send-btn'>_{SEND}_</a>
                    <a class='btn btn-warning btn-lg' id='forward-dialogue'>_{REDIRECT_DIALOGUE}_</a>
                    <a class='btn btn-primary btn-lg' id='close-dialogue'>_{CLOSE_DIALOGUE}_</a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class='col-md-2'>
    <div class='card card-primary card-outline container-md'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{PENDING_APPEALS}_</h4>
      </div>
      <div class='card-body p-0'>
        %NEW%
      </div>
    </div>
    <div class='card card-success card-outline container-md'>
      <div class='card-header with-border'>
          <h4 class='card-title'>_{ACTIVE_APPEALS}_</h4>
      </div>
      <div class='card-body p-0'>
        %ACTIVE%
      </div>
    </div>
    <div class='card card-warning card-outline container-md'>
      <div class='card-header with-border'>
        <h4 class='card-title'>_{WAITING}_</h4>
      </div>
      <div class='card-body p-0'>
        %WAITING%
      </div>
    </div>
  </div>
</div>

<script>
  let start_date = formatDate(new Date(), 'yyyy-mm-dd hh:ii:ss');
  let end_date = start_date;
  let last_message_from_aid = jQuery('#LAST_MESSAGE_FROM_AID').val();

  jQuery(document).ready(function () {
    scrollToBottom();

    jQuery('#accept-dialogue').on('click', function () {
      let self = this;
      sendRequest(`/api.cgi/crm/dialogue/${jQuery('#DIALOGUE_ID').val()}`, {aid: jQuery('#AID').val()}, 'PUT')
        .then((data) => {
          if (data.affected) {
            jQuery(self).hide()
            jQuery('#control-btn').removeClass('d-none');
            jQuery('#message-textarea').removeAttr('disabled');
          } else {
            jQuery(self).addClass('disabled').text('_{DIALOGUE_ALREADY_ACCEPTED}_');
          }
        });
    });

    jQuery('#close-dialogue').on('click', function () {
      jQuery('#message-textarea').attr('disabled', 'disabled');
      sendRequest(`/api.cgi/crm/dialogue/${jQuery('#DIALOGUE_ID').val()}`, {state: 1}, 'PUT')
        .then((data) => {
          jQuery('#control-btn').remove();
        });
    });

    jQuery('#send-btn').on('click', function () {
      let message = jQuery('#message-textarea').val();

      if (!message) return;
      jQuery('#message-textarea').val('');

      addReply(message, true);
      sendRequest(`/api.cgi/crm/dialogue/${jQuery('#DIALOGUE_ID').val()}/message`, {message: message})
        .then((data) => {
          console.log(data);
        });
    });

    jQuery('#forward-dialogue').on('click', function () {
      jQuery('#control-btn').addClass('d-none');
      jQuery('#message-textarea').attr('disabled', 'disabled');
      sendRequest(`/api.cgi/crm/dialogue/${jQuery('#DIALOGUE_ID').val()}`, {aid: '0'}, 'PUT')
        .then((data) => {
          location.reload();
        });
    });

    setInterval(function () {
      end_date = formatDate(new Date(), 'yyyy-mm-dd hh:ii:ss');
      sendRequest(`/api.cgi/crm/dialogue/${jQuery('#DIALOGUE_ID').val()}/messages?AID=0&AVATAR_LINK=_SHOW&FROM_DATE=${start_date}&TO_DATE=${end_date}`, {}, 'GET')
        .then(data => {
          if (!Array.isArray(data)) return;
          if (data.length > 0) start_date = end_date;

          data.forEach(function (message) {
            createMessage(message);
            scrollToBottom();
          });
        });
    }, 10000);
  });

  function createMessage(message) {
    if (jQuery('.hr-lines').last().text() !== message.day) {
      let date_line = document.createElement('h6');
      date_line.classList.add('hr-lines', 'text-muted');
      date_line.innerText = message.day;
      document.getElementById('msg_block').appendChild(date_line);
      last_message_from_aid = undefined;
    }

    let message_type = 'justify-content-start';
    let avatar = message.avatarLink ? `/images/${message.avatarLink}` : jQuery('#USER_AVATAR_LINK').val();
    if (message.aid) message_type = 'justify-content-end';

    let time = document.createElement('span');
    time.classList.add('text-muted', 'ml-1', 'float-right');
    time.innerText = message.time;

    let message_container = document.createElement('div');
    message_container.classList.add('message');
    message_container.innerText = message.message;
    message_container.appendChild(time);

    let image = document.createElement('img');
    image.src = avatar;
    image.classList.add('rounded-circle', 'user_img_msg');
    let image_container = document.createElement('div');
    image_container.classList.add('img_cont_msg');

    if (last_message_from_aid === undefined || last_message_from_aid != message.aid) image_container.appendChild(image);

    let main_container = document.createElement('div');
    main_container.classList.add('d-flex', 'mb-3', message_type);

    if (message.aid) {
      main_container.appendChild(message_container);
      main_container.appendChild(image_container);
    } else {
      main_container.appendChild(image_container);
      main_container.appendChild(message_container);
    }

    document.getElementById('msg_block').appendChild(main_container);
    last_message_from_aid = message.aid || 0;
  }

  async function sendRequest(url = '', data = {}, method = 'POST') {
    const response = await fetch(url, {
      method: method,
      mode: 'cors',
      cache: 'no-cache',
      credentials: 'same-origin',
      headers: {'Content-Type': 'application/json'},
      redirect: 'follow',
      referrerPolicy: 'no-referrer',
      body: method === 'GET' ? undefined : JSON.stringify(data)
    });
    return response.json();
  }

  function formatDate(date, format) {
    const leadingZero = (num) => `0${num}`.slice(-2);
    const map = {
      mm: leadingZero(date.getMonth() + 1),
      dd: leadingZero(date.getDate()),
      yyyy: date.getFullYear(),
      hh: leadingZero(date.getHours()),
      ii: leadingZero(date.getMinutes()),
      ss: leadingZero(date.getSeconds()),
    }

    return format.replace(/mm|dd|yyyy|hh|ii|ss/gi, matched => map[matched])
  }

  function addReply(message, admin = false) {
    let aid = admin ? jQuery('#AID').val() : 0;
    let reply_class = admin ? 'justify-content-end' : 'justify-content-start';
    let main = document.createElement('div');
    main.classList.add(reply_class, 'd-flex', 'mb-3');

    let img = document.createElement('img');
    img.src = admin ? jQuery('#ADMIN_AVATAR_LINK').val() : jQuery('#USER_AVATAR_LINK').val();
    img.classList.add('rounded-circle', 'user_img_msg');
    let avatar = document.createElement('div');
    avatar.classList.add('img_cont_msg');
    if (aid != last_message_from_aid) avatar.appendChild(img);

    let message_block = document.createElement('div');
    message_block.classList.add('message');
    message_block.innerText = message;
    let time = document.createElement('span');
    time.classList.add('text-muted', 'float-right', 'ml-1');
    const now = new Date();
    time.innerText = now.getHours() + ':' + now.getMinutes();
    message_block.appendChild(time);

    main.appendChild(message_block);
    admin ? main.appendChild(avatar) : main.prepend(avatar);

    setTimeout(function () {
      let messages = document.getElementById('msg_block');
      messages.appendChild(main);
      scrollToBottom();
    }, 300);
    last_message_from_aid = aid;
  }

  function scrollToBottom() {
    let messages = document.getElementById('msg_block');
    messages.scrollTop = messages.scrollHeight;
  }
</script>

<style>

  .inner-message {
		background-color: #6c757d !important;
		padding: 5px 20px 5px 20px !important;
		color: white;
  }

	.justify-content-start, .justify-content-end {
		animation-duration: 0.3s;
	  animation-delay: 0.2s;
		animation-name: animate-slide;
		animation-timing-function: cubic-bezier(.26,.53,.74,1.48);
		animation-fill-mode: backwards;
	}

	.animate.slide { animation-name: animate-slide; }
	@keyframes animate-slide {
		0% {
			opacity: 0;
			transform: translate(0,20px);
		}
		100% {
			opacity: 1;
			transform: translate(0,0);
		}
	}

	.hr-lines {
		position: relative;
		max-width: 92%;
		margin: 20px auto;
		text-align: center;
	}

	.hr-lines:before {
		content: " ";
		height: 2px;
		width: 40%;
		background: #e3effd;
		display: block;
		position: absolute;
		top: 50%;
		left: 0;
	}

	.hr-lines:after {
		content: " ";
		height: 2px;
		width: 40%;
		background: #e3effd;
		display: block;
		position: absolute;
		top: 50%;
		right: 0;
	}

	.balance-buttons a {
		margin-top: .25rem !important;
	}

	.balance-buttons a.btn-primary {
		font-weight: bold;
	}

	.msg_card_body {
		max-height: 70vh;
		overflow-y: auto;
	}

	.user_img_msg {
		height: 40px;
		width: 40px;
		border: 1.5px solid #f5f6fa;
	}

	.img_cont_msg {
		height: 40px;
		width: 40px;
	}

	.dark-mode .message {
		color: black;
	}

	.message {
		margin-top: auto;
		margin-bottom: auto;
		margin-left: 10px;
		background-color: #f6f6f6;
		padding: 10px;
		border-radius: 12px;
		position: relative;
	}

	.justify-content-end .message {
		margin-right: 10px !important;
		background-color: #e3effd !important;
	}

	.message .text-muted {
		position: relative;
		top: 10px;
		font-size: 0.8rem;
	}
</style>