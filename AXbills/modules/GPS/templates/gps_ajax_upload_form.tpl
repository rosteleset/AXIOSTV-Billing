<style>
    #ICON_SELECT, #ICON_SELECT_chosen, #ICON_SELECT_chosen > .chosen-single {
        min-height: 60px;
    }
</style>

<div class='row'>
    <!-- Nav tabs -->
    <ul class='nav nav-tabs' role='tablist'>
        <li role='presentation' class='active'>
            <a href='#chooseThumbnail' aria-controls='chooseThumbnail' role='tab' data-toggle='tab'>_{SELECTED}_</a>
        </li>
        <li role='presentation'>
            <a href='#newThumbnail' aria-controls='newThumbnail' role='tab' data-toggle='tab'>_{NEW}_</a>
        </li>
    </ul>

    <!-- Tab panes -->
    <div class='tab-content'>
        <div role='tabpanel' class='tab-pane active' id='chooseThumbnail'>


            <form class='form form-horizontal' name='form_select_thumbnail' id='form_select_thumbnail'>

                <input type='hidden' name='AID' value='$FORM{AID}'/>
                <input type='hidden' name='get_index' value='%CALLBACK_FUNC%'/>
                <input type='hidden' name='header' value='2'/>

                <input type='hidden' name='choosed' value='1'/>

                <div class='card box-primary'>
                    <div class='card-header with-border text-center'>
                        _{ADMIN}_ _{ICON}_
                    </div>

                    <div class='card-body'>
                        <div class='form-group'>
                            <label for='ICON_SELECT' class='control-label col-md-3'>_{ICON}_</label>
                            <div class='col-md-9'>
                                %ICON_SELECT%
                            </div>
                        </div>
                    </div>

                    <div class='card-footer'>
                        <input class='btn btn-primary' type='submit' id='select_thumbnail_btn' value='_{CHANGE_}_'/>
                    </div>

                </div>


            </form>


        </div>
        <div role='tabpanel' class='tab-pane' id='newThumbnail'>




        </div>
    </div>

</div>


<script>
    jQuery(function () {
        /** Anykey : pictures inside select **/

        var BASE_DIR = '/styles/default/img/maps/adm_thumbnails/';
        var EXTENSION = '.png';

        var select = jQuery('#ICON_SELECT');
        var options = select.find('option');

        _log(1, 'AdminsGPS options', options.length);

        jQuery.each(options, function (i, option) {
            var _opt = jQuery(option);

            var icon_name = _opt.text();
            icon_name.replace(/\n/g, '');

            var icon_src = BASE_DIR + icon_name + EXTENSION;

            var img = document.createElement('img');
            img.src = icon_src;
            jQuery(img).addClass('img-fluid img-thumbnail');

            var strong = document.createElement('strong');
            jQuery(strong).addClass('text-left col-md-6');
            strong.innerText = icon_name;

            _opt.addClass('text-center');
            _opt.html(strong.outerHTML + img.outerHTML);
        });
        jQuery(select).chosen(CHOSEN_PARAMS);
//        updateChosen();

        /** ajax submit form ( Tab 1)*/

        var _form = jQuery('#form_select_thumbnail');
        _form.on('submit', function(e){
            e.preventDefault();
            var formData = _form.serialize();

            aModal.hide();
            aModal.destroy();

            loadToModal('index.cgi?' + formData);
        })
    });

</script>
<script src='/styles/default/js/ajax_upload.js'></script>
