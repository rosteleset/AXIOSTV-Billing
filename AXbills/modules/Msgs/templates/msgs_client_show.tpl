<style>
	.attachment_responsive {
		border-radius: 5px;
		cursor: pointer;
		transition: 0.3s;
	}

	.attachment_responsive:hover {
		opacity: 0.7;
	}

	.modal-img {
		display: none;
		position: fixed;
		z-index: 99999;
		padding-top: 100px;
		left: 0;
		top: 0;
		width: 100%;
		height: 100%;
		overflow: auto;
		background-color: rgb(0, 0, 0);
		background-color: rgba(0, 0, 0, 0.9);
	}

	.modal-content-img {
		margin: auto;
		display: block;
		max-width: 90%;
	}

	.modal-content-img {
		-webkit-animation-name: zoom;
		-webkit-animation-duration: 0.6s;
		animation-name: zoom;
		animation-duration: 0.6s;
	}

	@-webkit-keyframes zoom {
		from {
			-webkit-transform: scale(0)
		}
		to {
			-webkit-transform: scale(1)
		}
	}

	@keyframes zoom {
		from {
			transform: scale(0)
		}
		to {
			transform: scale(1)
		}
	}

	.closeImageResize {
		position: absolute;
		top: 15px;
		right: 35px;
		color: #f1f1f1;
		font-size: 40px;
		font-weight: bold;
		transition: 0.3s;
	}

	.closeImageResize:hover,
	.closeImageResize:focus {
		color: #bbb;
		text-decoration: none;
		cursor: pointer;
	}

	@media only screen and (max-width: 700px) {
		.modal-content-img {
			width: 100%;
		}
	}
</style>

<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message_form' id='add_message_form'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='UID' value='$FORM{UID}'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='PARENT' value='%PARENT%'/>
  <input type='hidden' name='CHAPTER' value='%CHAPTER%'/>
  <input type='hidden' name='INNER_MSG' value='%INNER_MSG%'/>


  <div style='word-wrap: break-word;'>
    <div class='card card-primary card-outline %MAIN_PANEL_COLOR%'>
      <div class='card-header'>
        <h3 class='card-title'>
          <span class='badge badge-primary'>%ID%</span>
          %SUBJECT%
        </h3>
      </div>

      <div class='card-body text-left'>
        %MESSAGE%
        %PROGRESSBAR%
      </div>

      <div class='card-footer text-left'>
        %ATTACHMENT%
        <div class='row'>
          <div class='col-md-12'>_{UPDATED}_: %UPDATED%</div>
        </div>
        <div class='row'>
          <div class='col-md-3'>_{STATUS}_: %STATE_NAME%</div>
          <div class='col-md-3'>_{PRIORITY}_: %PRIORITY_TEXT%</div>
        </div>
        <div class='row'>
          <div class='col-md-3'>_{CREATED}_: %DATE%</div>
          <div class='col-md-3'>_{CHAPTER}_: %CHAPTER_NAME%</div>
          <div class='col-md-6 text-right'>%QUOTING% %DELETE%</div>
        </div>
      </div>
    </div>

    <div class='timeline'>
      %REPLY%
      <div>%TIMELINE_LAST_ITEM%</div>
    </div>
    %REPLY_BLOCK%
  </div>
</form>

<div id='myModalImg' class='modal-img'>
  <span class='closeImageResize'>&times;</span>
  <img class='modal-content-img' id='img_resize'>
  <div id='caption'></div>
  <br/>
  <a id='download_btn' class='btn btn-success btn-large'>_{DOWNLOAD}_</a>
  <br/><br/>
</div>

<script>
  var saveStr = '_{SAVE}_';
  var cancelStr = '_{CANCEL}_';
  var replyId = 0;

  var modal = document.getElementById('myModalImg');
  var modalImg = document.getElementById('img_resize');
  var captionText = document.getElementById('caption');

  var downloadBtn = jQuery('#download_btn');
  var span = jQuery('.closeImageResize');

  jQuery('.attachment_responsive').on('click', function (event) {
    modal.style.display = 'block';
    modalImg.src = this.src;
    downloadBtn.attr('href', this.src);
  });

  span.on('click', function (event) {
    modal.style.display = 'none';
  });

  jQuery('#myModalImg').on('click', function (event) {
    modal.style.display = 'none';
  });

  document.addEventListener('keydown', function (event) {
    const key = event.key;
    if (key === 'Escape') {
      modal.style.display = 'none';
    }
  });

  function quoting_reply(element) {
    var replyField = jQuery('#REPLY_TEXT');

    var replyElement = jQuery(element).closest('.timeline-item').children('.timeline-body');
    var oldReply = replyElement[0].innerText;

    oldReply = oldReply.replace(/^/g, '> ');
    oldReply = oldReply.replace(/\n/g, '\n> ');

    replyField.val(oldReply);
  }

  jQuery(function () {
    jQuery('.quoting-reply-btn').click(function (event) {
      event.preventDefault();
      quoting_reply(this);
    });
  }());
</script>