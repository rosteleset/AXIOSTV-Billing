<form action='$SELF_URL' method='get' name='works' class='form-horizontal'>
  <input type=hidden name='index' value='$index'>
  <input type=hidden name='EXT_ID' value='%EXT_ID%'>
  <input type=hidden name='ID' value='%EXT_ID%'>
  <input type=hidden name='UID' value='%UID%'>
  %HIDDEN_INPUTS%

  <div class='card card-primary card-outline card-big-form'>
    <div class='card-header with-border'>
      <h4 class='card-title'>_{WORK}_</h4>
    </div>
    <div class='card-body'>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='ADMIN'>_{PERFORMER}_:</label>
        <div class='col-md-9'>
          %ADMIN_SEL%
        </div>
      </div>

      <div id='WORKS'>
        <div class='card' id='WORK_BLOCK'>
          <div class='card-body'>
            <div class='form-group row'>
              <label class='control-label col-md-3' for='TYPE'>_{TYPE}_:</label>
              <div class='col-md-9'>
                %WORK_SEL%
              </div>
            </div>

            <div class='form-group row mb-0'>
              <label class='control-label col-md-3' for='RATIO'>_{RATIO}_:</label>
              <div class='col-md-9'>
                <input id='RATIO' name='RATIO' value='%RATIO%' placeholder='%RATIO%' class='form-control' type='text'>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class='form-group row text-right d-%HIDE_ADD_WORK%'>
        <div class='col-md-12'>
          <div class='btn-group'>
            <a title='_{ADD}_' onclick='addWorkBlock()'><span class='fa fa-plus text-success p-1'></span></a>
          </div>
        </div>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='EXTRA_SUM'>_{EXTRA}_ _{PRICE}_:</label>
        <div class='col-md-9'>
          <div class='input-group'>
            <div class='input-group-prepend'>
              <span class='input-group-text'>
                <input type='checkbox' data-input-enables='EXTRA_SUM'>
              </span>
            </div>
            <input type='number' class='form-control' id='EXTRA_SUM' name='EXTRA_SUM' value='%EXTRA_SUM%' disabled min='0'>
          </div>
        </div>
      </div>

      %TAKE_FEES%

      <div class='form-group custom-control custom-checkbox text-center'>
        <input class='custom-control-input' type='checkbox' id='WORK_DONE' name='WORK_DONE' %WORK_DONE% value='1'>
        <label for='WORK_DONE' class='custom-control-label'>_{WORK_DONE}_</label>
      </div>

      <div class='form-group row'>
        <label class='control-label col-md-3' for='COMMENTS'>_{COMMENTS}_:</label>
        <div class='col-md-9'>
          <textarea id='COMMENTS' name='COMMENTS' rows='5' cols='60' class='form-control'>%COMMENTS%</textarea>
        </div>
      </div>


    </div>
    <div class='card-footer'>
      <input type='submit' class='btn btn-primary' name='%ACTION%' value='%ACTION_LNG%'>
    </div>
  </div>

</form>

<script>
  var blocks = 0;

  function addWorkBlock() {
    jQuery('#WORK_ID').select2("destroy").removeAttr('data-select2-id');
    jQuery('#WORK_BLOCK').clone().prop('id', 'WORK_BLOCK_' + blocks).appendTo('#WORKS');

    let newBlock = jQuery('#WORK_BLOCK_' + blocks);
    newBlock.find('.card-body').addClass('pt-0');

    newBlock.find('#WORK_ID').attr('id', 'WORK_SELECT_' + blocks);

    newBlock.prepend(jQuery(createRemoveBtn('#WORK_BLOCK_' + blocks)));

    jQuery('#WORK_ID').select2();
    jQuery('#WORK_SELECT_' + blocks).select2();
    blocks++;
  }

  function createRemoveBtn(blockId) {
    let row = document.createElement('div');
    row.classList.add('form-group');
    row.classList.add('mb-0');
    row.classList.add('p-2');
    row.classList.add('row');
    row.classList.add('text-right');

    let col = document.createElement('div');
    col.classList.add('col-md-12');

    let btnGroup = document.createElement('div');
    btnGroup.classList.add('btn-group');

    let button = document.createElement('a');
    button.setAttribute('title', '_{REMOVE}_');
    button.onclick = function () { jQuery(blockId).remove(); };

    let icon = document.createElement('span');
    icon.classList.add('fa');
    icon.classList.add('fa-times');
    icon.classList.add('text-danger');
    icon.classList.add('p-1');

    button.appendChild(icon);
    btnGroup.appendChild(button);
    col.appendChild(btnGroup);
    row.appendChild(col);

    return row;
  }
</script>