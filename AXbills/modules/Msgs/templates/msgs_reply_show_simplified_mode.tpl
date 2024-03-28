<style>
	body {
		font-family: Arial, Helvetica, sans-serif;
	}

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

<div>
  <i class='fa fa-user %COLOR%'></i>
  <div class='timeline-item text-left'>
    <span class='time'>%DATE%</span>
    <h3 class='timeline-header'>%PERSON%</h3>
    <div class='timeline-body'>%MESSAGE%</div>
    <div class='timeline-footer'>
      <div class='row'>
        <div class='col-md-12'>
          %ATTACHMENT%
          <span class='pull-left'><small>%RUN_TIME%</small></span>
          <span class='pull-right'>%QUOTING% %DELETE% %NEW_TOPIC%</span>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
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

    var replyElement = jQuery(element).closest('.box').find('.box-body');
    var oldReplyHtml = replyElement[0].innerHTML;
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
  });
</script>