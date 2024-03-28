<form name='form_collection_add' id='form_collection_add' action='$SELF_URL' method='post' class='form form-horizontal'>  

    <input type='hidden' name='index' value='$index'>

    <div class='form-group' style="padding-top: 10px">
        <label class='control-label col-md-5' for='%COLLECTION%'>Name %COLLECTION%:</label>
        <div class='col-md-3 control-element'>
            <input type='text' name='_id' value='' class='form-control' ID='_id' data-check-for-pattern='^[A-Za-z0-9-_]+\$' maxlength='20'/>
        </div>
    </div>
    <span class="visible-xs visible-sm col-xs-12" style="padding-top: 5px"></span>


    <div class='card-footer'>
        <input type='submit' name='add' value='_{ADD}_' ID='add' class='btn btn-primary'>
    </div>
</form>

<script>
    jQuery(document).ready(function(){
        pageInit('#form_collection_add');
        jQuery('#form_collection_add').submit(function(e) {
            if (jQuery('#form_collection_add').find('.has-error').find('.form-control').attr( "id"))
            {
              e.preventDefault();
            }
        });
    });
</script>
