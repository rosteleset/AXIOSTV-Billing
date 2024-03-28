<style>
	.timeline-item-footer {
		background-color: rgba(0, 0, 0, .03);
	}

	.step-info-btn {
		position: relative;
		top: 13px;
		left: -4px;
  }

	.steps-info:before,
	.steps-info:after {
		border-left: 0 !important;
  }

	.steps-info-hide {
		width: 0 !important;
		height: 0 !important;
	}

	.steps-info-hide:after,
	.steps-info-hide:before {
		width: 0 !important;
		border: none !important;
	}


	.steps-container {
		overflow: hidden;
		margin: 0;
		padding: 0;
		white-space: nowrap;
		border-left: 2px solid;
		border-right: 2px solid;
		width: 100%;
		counter-reset: steps;
	}
	.steps {
		position: relative;
		display: inline-block;
		left: -28px; /* -2px default + 26px offset to hide skewed area on the left side of first element*/
		height: 50px;
		line-height: 50px;
		margin-left: -1px !important;
		margin-right: 0;
		counter-increment: steps;
		cursor: pointer;
		transition: background 1s;
		min-height: 30px;
	}

	.steps:after,
	.steps:before {
		position: absolute;
		content: '';
		left: 0;
		height: 50%;
		width: 100%;
		border-top: 2px solid;
		border-bottom: 2px solid;
		border-left: 3px solid; /* thicker border as skew makes them look thin */
		border-right: 3px solid;
		background: rgba(255, 255, 255, 0.15);
	}

	.steps:before {
		transform: skew(45deg);
		top: 0;
		border-bottom: none;
		transform-origin: top left;
	}

	.steps:after {
		transform: skew(-45deg);
		bottom: 0;
		border-top: none;
		transform-origin: bottom left;
	}

	.steps span{
		display: block;
		padding-left: 40px;
		overflow: hidden;
		text-overflow: ellipsis;
		width: 100%;
		height: 75%;
		vertical-align: middle;
	}

	.steps.active span{
		font-weight: bold;
	}
	.steps.active:nth-child(1n):before,
	.steps.active:nth-child(1n):after {
		background: rgba(0, 123, 255, 0.5);
	}

	.steps.active:nth-child(2n):before,
	.steps.active:nth-child(2n):after {
		background: rgba(23, 162, 184, 0.5);
	}

	.steps.active:nth-child(3n):before,
	.steps.active:nth-child(3n):after {
		background: rgba(40, 167, 69, 0.5);
	}

	.steps.active:nth-child(4n):before,
	.steps.active:nth-child(4n):after {
		background: rgba(220, 53, 69, 0.5);
	}

	.steps.active:nth-child(5n):before,
	.steps.active:nth-child(5n):after {
		background: rgba(255, 193, 7, 0.5);
	}

	.steps.active:nth-child(6n):before,
	.steps.active:nth-child(6n):after {
		background: rgba(52, 58, 64, 0.5);
	}

  %CSS%
</style>

<!-- PROGRESSBAR -->
<div class='card'>

  <div class='card-body'>
    <div class='row mb-2' id='progressTracker'>
      <input type='hidden' name='OBJECT_TYPE' id='OBJECT_TYPE' value='%OBJECT_TYPE%'/>
      <input type='hidden' name='OBJECT_VALUE' id='OBJECT_VALUE' value='%OBJECT_VALUE%'/>
      <hr/>
      <div class='col-md-12 mb-2'>
        <div class='steps-container' id='step_icon'>
          %STEPS%
        </div>
      </div>
      <hr/>
    </div>
    %STEPS_COMMENTS%
  </div>
</div>

<script>
  let object_type = jQuery('#OBJECT_TYPE').val();
  let object_value = jQuery('#OBJECT_VALUE').val();

  function adjustBar() {
    console.log(jQuery('.step-container').length);
    let items = jQuery('.steps:not(.steps-info)').length;
    let elHeight = jQuery('.steps:not(.steps-info)').height() / 2;
    let skewOffset = Math.tan(45 * (Math.PI / 180)) * elHeight;
    let reduction = skewOffset + ((items - 1) * 4);
    let leftOffset = jQuery('.steps:not(.steps-info)').css('left').replace('px', '');
    let factor = leftOffset * (-1) - 2;

    jQuery('.step-container').find('.steps:not(.steps-info)').css({
      'width': '-webkit-calc((100% + 4px - ' + reduction + 'px)/' + items + ')',
      'width': 'calc((100% + 4px - ' + reduction + 'px)/' + items + ')'
    });
    jQuery('.step-container:first-child, .step-container:last-child').find('.steps:not(.steps-info)').css({
      'width': '-webkit-calc((100% + 4px - ' + reduction + 'px)/' + items + ' + ' + factor + 'px)',
      'width': 'calc((100% + 4px - ' + reduction + 'px)/' + items + ' + ' + factor + 'px)'
    });
    jQuery('.step-container:last-child').addClass('last-step');

    jQuery('.steps:not(.steps-info) span').css('padding-left', (skewOffset + 15) + "px");
    jQuery('.steps:not(.steps-info):first-child span, .steps:not(.steps-info):last-child span').css({
      'width': '-webkit-calc(100% - ' + factor + 'px)',
      'width': 'calc(100% - ' + factor + 'px)',
    });
  }

  jQuery('.step-container').hover(function () {
    jQuery(this).find('.steps-info').first().removeClass('steps-info-hide');
    if (jQuery(this).hasClass('last-step')) {
      let width = jQuery(this).find('.steps:not(.steps-info)').css('width').replace('px', '');
      jQuery(this).find('.steps:not(.steps-info)').css('width', width - 64 + 'px')
    }
  }, function () {
    jQuery(this).find('.steps-info').first().addClass('steps-info-hide');
    if (jQuery(this).hasClass('last-step')) {
      let width = jQuery(this).find('.steps:not(.steps-info)').css('width').replace('px', '');
      console.log(width)
      jQuery(this).find('.steps:not(.steps-info)').css('width', (parseFloat(width) + 64) + 'px')
    }
  });

  function checkStep(step_number) {
    let convertLeadBtn = jQuery('#lead_to_client');

    if (step_number.toString() === jQuery('.steps:not(.steps-info)').length.toString()) {
      convertLeadBtn.attr('disabled', false).attr('style', 'pointer-events: ;');

      let confirmModal = new AModal();
      confirmModal
        .setBody('<h4 class="modal-title"><div id="confirmModalContent">_{ADD_USER}_?</div></h4>')
        .addButton('_{NO}_', 'confirmModalCancelBtn', 'default')
        .addButton('_{YES}_', 'confirmModalConfirmBtn', 'success')
        .show(function () {
          jQuery('#confirmModalConfirmBtn').on('click', function () {
            confirmModal.hide();
            document.getElementById('lead_to_client').click();
          });

          jQuery('#confirmModalCancelBtn').on('click', function () {
            confirmModal.hide();
          });
        });

    } else {
      convertLeadBtn.attr('disabled', true).attr('style', 'pointer-events: none;');
    }
  }

  adjustBar();

  jQuery('.steps:not(.steps-info)').on('click', function() {
    let step_number = jQuery(this).attr('id');
    if (!step_number) return;

    jQuery('.steps:not(.steps-info)').removeClass('active')
      .filter(function (index) { return index < step_number }).addClass('active');
    sendRequest(`/api.cgi/crm/${object_type}/${object_value}`, {current_step: step_number}, 'PUT');

    if (object_type === 'leads') checkStep(step_number);
  });


  jQuery(`[name='CLOSE_TASK']`).on('change', function() {
    let task_id = jQuery(this).data('task');
    if (!task_id) return;

    sendRequest(`/api.cgi/tasks/${task_id}`, {state: 1}, 'PUT');

    jQuery(`[data-task='${task_id}']`).each(function() {
      jQuery(this).parent().parent().parent().find('.fa-tasks').first().removeClass('bg-blue').addClass('bg-green');
      jQuery(this).remove();
    });
    jQuery('.popover.show').removeClass('show');
  });
</script>



