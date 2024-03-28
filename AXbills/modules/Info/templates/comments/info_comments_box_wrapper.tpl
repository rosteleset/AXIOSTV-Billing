<link href='/styles/default/css/info.css' rel='stylesheet'>

<div id='form_6' class='card for_sort dataTables_wrapper card-primary card-outline'>
  <div class='card-header with-border'>
    <h4 class='card-title'>_{COMMENTS}_</h4>
    <div class='card-tools float-right'>
      %COMMENTS_CONTROLS%
      <button type='button' class='btn btn-tool text-right col-md-12' data-card-widget='collapse'>
        <i class='fa fa-minus'></i>
      </button>
    </div>
  </div>
  <div class='card-body p-0'>
    <div class="paginator text-right p-1" onclick="listing_pagination(event)"></div>
    <div id='commentsWrapper' class='row'>
      <div class='col-md-12'>
        <div class='col-md-12 timeline mb-0' id='commentsBlock'>
          %COMMENTS%
        </div>
      </div>
    </div>
  </div>
</div>

<script>
  var lang_edit = '_{EDIT}_';
  var lang_add = '_{ADD}_';
  var lang_comments = '_{COMMENTS}_';
  var lang_admin = '_{ADMIN}_';
</script>

<script src='/styles/default/js/info/info.js'></script>

<style>
    .paginator {
        line-height: 150%;
    }
    .paginator_active {
        font-weight: bold;
    }
    .paginator > span {
        display: inline-block;
        margin-right: 10px;
        cursor: pointer;
    }
</style>