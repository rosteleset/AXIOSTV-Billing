<div class='row'>
  %ITEMS%
</div>

<script>
  jQuery.fn.isValid = function(){
    return this[0].checkValidity()
  }

  function countValidate() {
    let parent = jQuery(this).parent().parent().parent().parent();
    let invalid_feedback = parent.find('.invalid-feedback');
    let sell_btn = parent.parent().find('.sell-btn');

    if (jQuery(this).isValid()) {
      invalid_feedback.removeClass('d-block');
      jQuery(this).removeClass('is-invalid pr-0');

      sell_btn.removeClass('disabled');
      return;
    }

    invalid_feedback.addClass('d-block');
    jQuery(this).addClass('is-invalid pr-0');
    sell_btn.addClass('disabled');
  }

  jQuery('.count').on('keyup', countValidate);
  jQuery('.count').on('change', countValidate);

  jQuery('.sell-btn').on('click', function(event) {
    let href = jQuery(this).data('url');
    let parent = jQuery(this).parent().parent();
    let count = parent.find('.count').val() || 0;
    let article_name = parent.find('.article-name').text() || '';

    cancelEvent(event);
    showCommentsModal(`${jQuery(this).text()} ${article_name}?`, `${href}&COUNT=${count}`, '-', { ajax: '', type : 'allow_empty_message' } )
  })
</script>

<style>
	.image-container {
		height: 160px;
		text-align: center;
		position: relative;
	}

	.item-card {
		min-height: 100%;
		margin-bottom: 10px;
	}

	.item-image {
		max-height: 100%;
		max-width: 100%;
		width: 100%;
		height: auto;
		position: absolute;
		top: 0;
		bottom: 0;
		left: 0;
		right: 0;
		margin: auto;
		object-fit: scale-down;
	}

  .modal-body {
    display: none;
  }
</style>