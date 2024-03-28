<div class='modal fade' id='group_settings_modal' tabindex='-1' role='dialog' aria-labelledby='group_settings_modal'
     aria-hidden='true'>
    <div class='modal-dialog' role='document'>
        <div class='modal-content'>
            <div class='modal-header'>
                <h5 class='modal-title' id='exampleModalLongTitle'>_{SHOW_PAYSYSTEM_IN_USER_PORTAL}_</h5>
            </div>
            <div class='modal-body'>
                _{SETTINGS}_ _{SAVED}_
            </div>
            <div class='modal-footer'>
                <button type='button' class='btn btn-primary' data-dismiss='modal'>_{CLOSE}_</button>
            </div>
        </div>
    </div>
</div>

<style type='text/css'>
    .material-switch > input[type='checkbox'] {
        display: none;
    }

    .material-switch > label {
        cursor: pointer;
        height: 6px;
        position: relative;
        width: 40px;
    }

    .material-switch > label::before {
        background: rgb(50, 50, 50);
        border-radius: 8px;
        content: '';
        height: 16px;
        margin-top: -8px;
        position: absolute;
        right: 0px;
        opacity: 0.3;
        transition: all 0.4s ease-in-out;
        width: 40px;
    }

    .material-switch > label::after {
        background: rgb(65, 65, 65);
        border-radius: 16px;
        content: '';
        height: 24px;
        left: -4px;
        margin-top: -8px;
        position: absolute;
        top: -4px;
        transition: all 0.3s ease-in-out;
        width: 24px;
    }

    .material-switch > input[type='checkbox']:checked + label::before {
        background: rgba(13, 110, 253, 0.9);;
        opacity: 0.5;
    }

    .material-switch > input[type='checkbox']:checked + label::after {
        background: rgb(13, 110, 253);
        left: 20px;
    }
</style>

<script>
    jQuery(document).ready(() => {
        jQuery('#add_settings').attr('data-target', '#group_settings_modal').attr('data-toggle', 'modal');
        jQuery('[name=PAYSYS_GROUPS_SETTINGS]').submit(function (e) {
            e.preventDefault()

            const formData = new FormData()
            const index = jQuery(this).find('input[name=index]').first().val()

            formData.append('index', index)
            formData.append('add_settings', 'Сохранить')
            formData.append('GROUPS_USER_PORTAL_TABLE__length', '10')

            const isChecked = jQuery(this).find('input:checked').get()
            const isNotChecked = jQuery(this).find('input[id^=SETTINGS]').not(':checked').get()

            for (const checkbox in isChecked) {
                formData.append(isChecked[checkbox].id, '1')
            }
            for (const checkbox in isNotChecked) {
                formData.append(isNotChecked[checkbox].id, '0')
            }

            fetch(this.action, {
                body: formData,
                method: 'POST'
            }).then()
        });

        var colCount = jQuery('#GROUPS_USER_PORTAL_TABLE_ thead tr th').length;
        var rawCount = jQuery('#GROUPS_USER_PORTAL_TABLE_ tbody tr').length

        for (var i = 2; i < colCount; i++) {
            var element = jQuery("<input type='checkbox' id='" + i + "' class='checkbox_column_name ml-1'>");
            jQuery('#GROUPS_USER_PORTAL_TABLE_ th').eq(i).append(element);
        }

        jQuery('.checkbox_column_name').change(function () {
            var id = jQuery(this).attr('id');
            var status;
            if (jQuery(this).is(':checked')) {
                status = true;
            } else {
                status = false;
            }
            for (var i = 1; i <= rawCount; i++) {
                jQuery('#GROUPS_USER_PORTAL_TABLE_ tr:eq(' + i + ') td:eq(' + id + ') div input').prop('checked', status);
            }
        });
    })
</script>