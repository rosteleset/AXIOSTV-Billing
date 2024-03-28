<div class='card box-primary'>

    <div class='card-header with-border text-center'>
        _{ADMIN}_ _{ICON}_
    </div>

    <div class='card-body text-center' id='DELETE_THUMBNAIL_PANEL_BODY'>
        <img src='%IMG_PATH%' alt='admin_thumbnail'/>
        <button id='thumbnail_delete_button' class='btn btn-xs btn-danger' data-aid='%AID%' data-index='%DEL_INDEX%'>
            <span class='fa fa-times'></span>
        </button>

    </div>

</div>

<script>
    jQuery(function () {

        var button = jQuery('#thumbnail_delete_button');

        button.on('click', function () {
            removeThumbnail(this);
        });

        function removeThumbnail(context) {
            var _context = jQuery(context);
            var aid = _context.attr('data-aid');
            var del_index = _context.attr('data-index');

            jQuery.post('/admin/index.cgi', 'qindex=' + del_index + '&header=2&IN_MODAL=1&AID=' + aid, function (data) {

                jQuery('#DELETE_THUMBNAIL_PANEL_BODY')
                        .empty()
                        .html(data);

                setTimeout(function () {
                    aModal.hide();
                    aModal.destroy();
                }, 2000);

            });
        }

    });

</script>