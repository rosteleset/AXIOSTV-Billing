<script language='JavaScript'>
  let statusKeys = {
    0: 'SELL_PRICE',
    1: 'SELL_PRICE',
    2: 'RENT_PRICE',
    3: 'IN_INSTALLMENTS_PRICE'
  };

  function selectArticles() {
    let self = this;
    let mainBlock = jQuery(this).closest('.card');

    let articleTypeId = mainBlock.find('[name="ARTICLE_TYPE_ID"]').val();
    if (articleTypeId === null) return;

    let storageId = mainBlock.find('[name="STORAGE_ID"]').val();
    let searchFields = '&ARTICLE_TYPE_ID=' + articleTypeId;
    if (storageId) searchFields += '&STORAGE_ID=' + storageId;

    jQuery.post('/admin/index.cgi', 'header=2&get_index=storage_hardware&quick_info=1' + searchFields, function (result) {
      mainBlock.find("div.ARTICLES_S").empty();
      mainBlock.find("div.ARTICLES_S").html(result);
      mainBlock.find('#ARTICLE_ID').attr('id', 'ARTICLE_ID_' + jQuery(self).prop('id'));
      initChosen();
    });
  }

  function selectStorage() {
    let mainBlock = jQuery(this).closest('.card');
    mainBlock.find('[name="ARTICLE_TYPE_ID"]').change();
  }

  function selectStatus(event) {
    let select = event.target;
    let status = jQuery(select).val();
    let mainBlock = jQuery(select).parent().parent().parent();

    if (status === '3') {
      var element = jQuery("<div></div>").addClass("form-group row appended_field");
      element.append(jQuery("<label for=''></label>").text("_{MONTHES}_:").addClass("col-md-4 control-label"));
      element.append(jQuery("<div></div>").addClass("col-md-8")
        .append(jQuery("<input name='MONTHES' id='MONTHES' value='%MONTHES%'>").addClass("form-control")));

      mainBlock.append(element);
    } else {
      mainBlock.find('.appended_field').remove();
    }

    let article = jQuery(select).closest('.card-body').find('[name="SERIAL"][type="text"]');
    document.getElementById(article.attr('id').toString()).dispatchEvent(new Event("input"));
  }

  function selectAccountability() {
    let currentSelect = jQuery(this);
    let mainBlock = currentSelect.closest('.card');

    let accountabilityAid = mainBlock.find(`[name='ACCOUNTABILITY_AID']`).val() || 0;
    let typeId = mainBlock.find(`[name='IN_ACCOUNTABILITY_ARTICLE_TYPE']`).val() || 0;

    let link = `header=2&get_index=storage_hardware&quick_info=1&ACCOUNTABILITY_AID=${accountabilityAid}&TYPE_ID=${typeId}`;
    jQuery.post('/admin/index.cgi', link, function (result) {
      mainBlock.find('div.ACCOUNTABILITY_SELECT').empty().html(result);
      mainBlock.find('#ACCOUNTABILITY_ID').attr('id', 'ACCOUNTABILITY_ID' + currentSelect.prop('id'));
      initChosen();
    });
  }

  function autoReload() {
    document.storage_hardware_form.type.value = 'prihod';
    document.storage_hardware_form.submit();
  }

  function disableInputs(context) {
    var j_context = jQuery(jQuery(context).attr('href'));

    j_context.find('input').prop('disabled', true);
    j_context.find('select').prop('disabled', true);

    updateChosen();
  }

  function enableInputs(context) {
    var j_context = jQuery(jQuery(context).attr('href'));

    j_context.find('input').prop('disabled', false);
    j_context.find('select').prop('disabled', false);
  }

  jQuery(document).ready(function () {
    jQuery('#menu1').find('input').prop('disabled', true);
    jQuery('#menu1').find('select').prop('disabled', true);
    jQuery('#menu1').find('textarea').prop('disabled', true);
    jQuery('#home').find('input').prop('disabled', true);
    jQuery('#home').find('select').prop('disabled', true);
    jQuery('#home').find('textarea').prop('disabled', true);
    updateChosen();
  });

  jQuery(function () {
    jQuery('a[data-toggle=\"tab\"]').on('shown.bs.tab', function (e) {
      enableInputs(e.target);
      disableInputs(e.relatedTarget);
    })
  });
</script>

<form action=$SELF_URL name='storage_hardware_form' method=POST class='form-horizontal'>
  <input type=hidden name=index value=$index>
  <input type=hidden name=CHG_ID value=%CHG_ID%>
  <input type=hidden name='type' value='prihod2'>
  <input type=hidden name=UID value=$FORM{UID}>
  <input type=hidden name=COUNT1 value=%COUNT1%>
  <input type=hidden name=ARTICLE_ID1 value=%ARTICLE_ID1%>
  <input type=hidden name='step' value='$FORM{step}'>
  <input type=hidden name='STORAGE_MSGS_ID' value='$FORM{STORAGE_MSGS_ID}'>

  <div class='card card-primary card-outline card-form'>
    <div class="card-header">

      <ul class='nav nav-tabs' role='tablist'>
        <li class='nav-item'>
          <a class='nav-link active' id='custom-content-below-home-tab' data-toggle='tab' href='#main' role='tab'
             aria-controls='custom-content-below-home'>_{MAIN}_</a>
        </li>
        <li class='nav-item'>
          <a class='nav-link' id='custom-content-below-profile-tab' data-toggle='tab' href='#home' role='tab'
             aria-controls='custom-content-below-profile'>_{STORAGE}_</a>
        </li>
        <li class='nav-item'>
          <a class='nav-link' id='custom-content-below-messages-tab' data-toggle='tab' href='#menu1' role='tab'
             aria-controls='custom-content-below-messages'>_{ACCOUNTABILITY}_</a>
        </li>
      </ul>

    </div>

    <div class='card-body form'>

      <div id='WORKS'>
        <div class='card' id='WORK_BLOCK'>
          <div class='card-body'>
            <div class='tab-content' id='hardware-tabs'>
              <!--Main content-->
              <div id='main' class='tab-pane fade show active'>
                <input type='hidden' name='fast_install' value='1'>
                <div class='form-group row'>
                  <label class='col-md-4 control-label' for='SERIAL'>SN:</label>
                  <div class='col-md-8'>
                    <input class='form-control sn_installation' id='SERIAL' name='SERIAL' type='text' VALUE='%SERIAL%'
                           %DISABLED_SN% autofocus/>
                  </div>
                </div>

                <div class='form-group row item_info_by_sn'>

                </div>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>_{SELL_PRICE}_:</label>
                  <div class='col-md-8'>
                    <input class='form-control' name='ACTUAL_SELL_PRICE' type='text' value='%ACTUAL_SELL_PRICE%'
                           id='sell_price'/>
                  </div>
                </div>
              </div>

              <!--Home Content-->
              <div id='home' class='tab-pane fade'>
                <input type=hidden name=ID value=%ID%>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>_{STORAGE}_: </label>
                  <div class='col-md-8'>%STORAGE_STORAGES%
                  </div>
                </div>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>_{TYPE}_:</label>
                  <div class='col-md-8'>%ARTICLE_TYPES%</div>
                </div>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>_{NAME}_:</label>

                  <div class='col-md-8'>
                    <div class='ARTICLES_S'>
                      %ARTICLE_ID%
                    </div>
                  </div>
                </div>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>_{COUNT}_:</label>
                  <div class='col-md-8'>
                    <input class='form-control' name='COUNT' type='text' %DISABLE%/>
                  </div>
                </div>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>_{SELL_PRICE}_:</label>
                  <div class='col-md-8'>
                    <input class='form-control' name='ACTUAL_SELL_PRICE' type='text' value=''/>
                  </div>
                </div>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>SN:</label>
                  <div class='col-md-8'>
                    <textarea class='form-control col-xs-12' name='SERIAL'>%SERIAL%</textarea>
                  </div>
                </div>
              </div>

              <!--Menu1 Content-->
              <div id='menu1' class='tab-pane fade'>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>_{RESPOSIBLE}_:</label>
                  <div class='col-md-8'>%ACCOUNTABILITY_AID_SEL%</div>
                </div>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>_{TYPE}_:</label>
                  <div class='col-md-8'>%IN_ACCOUNTABILITY_ARTICLE_TYPES_SEL%</div>
                </div>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>_{NAME}_:</label>
                  <div class='col-md-8 ACCOUNTABILITY_SELECT'>%IN_ACCOUNTABILITY_SELECT%</div>
                </div>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>_{COUNT}_:</label>
                  <div class='col-md-8'>
                    <input class='form-control' name='COUNT_ACCOUNTABILITY' type='text' %DISABLE%/>
                  </div>
                </div>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>_{SELL_PRICE}_:</label>
                  <div class='col-md-8'>
                    <input class='form-control' name='ACTUAL_SELL_PRICE' type='text' value=''/>
                  </div>
                </div>
                <div class='form-group row'>
                  <label class='col-md-4 control-label'>SN:</label>
                  <div class='col-md-8'>
                    <textarea class='form-control col-xs-12' name='SERIAL'>%SERIAL%</textarea>
                  </div>
                </div>
              </div>
            </div>

            <div class='form-group row' style='%CHG_HIDE%'>
              <label class='col-md-4 control-label'>_{ACTION}_:</label>
              <div class='col-md-8'>%STATUS% %STORAGE_DOC_CONTRACT% %STORAGE_DOC_RECEIPT%</div>
            </div>
            <div id='storage_monthes_by_installments'>

            </div>

          </div>
        </div>
      </div>
      <div class='form-group row text-right d-%HIDE_ADD_WORK%'>
        <div class='col-md-12'>
          <div class='btn-group'>
            <a id='addBlock' title='_{ADD}_'><span class='fa fa-plus text-success p-1'></span></a>
          </div>
        </div>
      </div>

      <div class='form-group'>
        <div class='card collapsed-card card-primary card-outline box-big-form'>
          <div class='card-header with-border text-center'>
            <h3 class='card-title'>_{EXTRA}_</h3>
            <div class='card-tools float-right'>
              <button type='button' class='btn btn-tool' data-card-widget='collapse'>
                <i class='fa fa-plus'></i>
              </button>
            </div>
          </div>
          <div class='card-body'>
            <div class='form-group row'>
              <label class='col-md-4 control-label'>_{RESPONSIBLE}_ _{FOR_INSTALLATION}_:</label>
              <div class='col-md-8'>%INSTALLED_AID_SEL%</div>
            </div>
            <div class='form-group row'>
              <label class='col-md-4 control-label'>_{COMMENTS}_:</label>
              <div class='col-md-8'>
                <input name='COMMENTS' class='form-control' type='text' value='%COMMENTS%'/>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div class='card-footer'>
      %BACK_BUTTON% <input type=submit name='%ACTION%' value='%LNG_ACTION%' ID='submitbutton' class='btn btn-primary'>
    </div>
  </div>
</form>

<script>
  jQuery(function () {

    var timeout = null;
    var blocks = 0;

    function doDelayedSearch(val, element, parentElement) {
      if (timeout) {
        clearTimeout(timeout);
      }
      timeout = setTimeout(function () {
        doSearch(val, element, parentElement); //this is your existing function
      }, 500);
    }

    function doSearch(val, element, parentElement) {
      if (!val) {
        console.log("Value is empty");
        return 1;
      }
      jQuery.post('$SELF_URL', 'header=2&get_index=storage_main&get_info_by_sn=' + val, function (data) {
        var info;
        try {
          info = JSON.parse(data);
        } catch (Error) {
          console.log(Error);
          alert("Cant handle info");
          return 1;
        }
        if (info.error) {
          jQuery(element).parent().removeClass('has-success').addClass('has-error');
          jQuery(element).css('border', '3px solid red');
          jQuery(parentElement).find('[name="ACTUAL_SELL_PRICE"]').val('');
          jQuery(parentElement).find('.item_info_by_sn').text('');
        } else {
          jQuery(element).parent().removeClass('has-error');
          jQuery(element).css('border', "");
          let status = jQuery(parentElement).parent().parent().find('[name="STATUS"]').val();
          jQuery(parentElement).find('[name="ACTUAL_SELL_PRICE"]').val(statusKeys[status] ? info[statusKeys[status]] : info.SELL_PRICE);
          jQuery(parentElement).find('.item_info_by_sn').html('<label class="control-label col-md-4">_{ARTICLE}_</label><div class="col-md-8">' +
            '<input type="text" value="' + info.ARTICLE_TYPE_NAME + ' ' + info.ARTICLE_NAME + '" class="form-control" disabled></div>');
        }

      });
    }

    function addWorkBlock() {
      let work_block = jQuery('#WORK_BLOCK');
      let active_tab = jQuery('#hardware-tabs').find('.active');

      let selects = [];

      work_block.find('select').each(function () {
        let select = active_tab.find('[name="' + jQuery(this).prop('name') + '"]');
        if (select.length <= 0) return;
        jQuery(this).removeAttr("onchange");

        selects.push(removeSelect2(select));
      });
      selects.push(removeSelect2(jQuery('#STATUS')));

      let new_block = work_block.clone().prop('id', 'WORK_BLOCK_' + blocks);
      new_block.find('.card-body').addClass('pt-0');
      new_block.addClass('new-block');
      new_block.appendTo('#WORKS')

      new_block.prepend(jQuery(createRemoveBtn('#' + 'WORK_BLOCK_' + blocks)));

      selects.forEach(function (select_id) {
        let new_id = select_id + '_' + blocks;
        new_block.find('#' + select_id).attr('id', new_id);
        let newSelect = jQuery('#' + new_id);

        let changeFunction = newSelect.data('change');
        if (typeof window[changeFunction] !== undefined) newSelect.on('change', window[changeFunction]);
      });

      initChosen();

      let tabId = active_tab.prop('id');
      if (tabId === 'main') updateMainTab(new_block);

      blocks++;
    }

    function updateMainTab(new_block) {
      _clearMainTab(new_block);

      jQuery('.new-block').each(function (index, block) {
        jQuery(block).find('[name="SERIAL"]').on('input', function (event) {
          let element = event.target;
          let inputId = jQuery(block).prop('id') + '_SERIAL';
          jQuery(element).prop('id', inputId);

          _checkOthersSN(inputId, jQuery(block));
        });
      });
    }

    function _checkOthersSN(id, parentElement) {
      let blocks = jQuery('.new-block');
      let serialInput = jQuery('#' + id);

      serialInput.parent().removeClass('has-error');
      serialInput.css('border', "");

      blocks.each(function (index, block) {
        let currentSelect = jQuery(block).find('[name="SERIAL"]');
        if (id === currentSelect.prop('id')) return;
        if (currentSelect.val() !== serialInput.val()) return;
        if (serialInput.val() === '') return;

        serialInput.parent().removeClass('has-success').addClass('has-error');
        serialInput.css('border', '3px solid red');
      });

      if (id !== 'SERIAL' && serialInput.val() !== '' && jQuery('#SERIAL').val() === serialInput.val()) {
        serialInput.parent().removeClass('has-success').addClass('has-error');
        serialInput.css('border', '3px solid red');
      }

      if (!serialInput.parent().hasClass('has-error')) {
        doDelayedSearch(serialInput.val(), serialInput, parentElement);
      }
    }

    function _clearMainTab(block) {
      block.find('input').parent().removeClass('has-error');
      block.find('input').css('border', "");
      block.find('.item_info_by_sn').html('');
      block.find('[name="ACTUAL_SELL_PRICE"]').val('');
      block.find('[name="SERIAL"]').val('');
      block.find('.appended_field').remove();
    }

    function removeSelect2(select) {
      let select_id = select.prop('id');
      jQuery('#' + select_id).select2("destroy").removeAttr('data-select2-id');

      return select_id;
    }

    function createRemoveBtn(blockId) {
      let row = document.createElement('div');
      row.classList.add('form-group', 'mb-0', 'p-2', 'row', 'text-right');

      let col = document.createElement('div');
      col.classList.add('col-md-12');

      let btnGroup = document.createElement('div');
      btnGroup.classList.add('btn-group');

      let button = document.createElement('a');
      button.setAttribute('title', '_{REMOVE}_');
      button.onclick = function () {
        jQuery(blockId).remove();
      };

      let icon = document.createElement('span');
      icon.classList.add('fa', 'fa-times', 'text-danger', 'p-1');
      button.appendChild(icon);
      btnGroup.appendChild(button);
      col.appendChild(btnGroup);
      row.appendChild(col);

      return row;
    }

    jQuery('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {
      jQuery('.new-block').remove();
      initChosen();
    });

    jQuery('.sn_installation').on('input', function () {
      _checkOthersSN('SERIAL', jQuery('#main'));
    });

    jQuery('#ACCOUNTABILITY_AID').on('change', selectAccountability);
    jQuery('#IN_ACCOUNTABILITY_ARTICLE_TYPE').on('change', selectAccountability);

    jQuery('#addBlock').on('click', addWorkBlock);

    jQuery('#ARTICLE_TYPE_ID').on('change', selectArticles);

    jQuery('#STORAGE_SELECT_ID').removeAttr("onchange");
    jQuery('#STORAGE_SELECT_ID').on('change', selectStorage);

    jQuery('#STATUS').on('change', selectStatus);
    if (jQuery('#STATUS').val()) jQuery('#STATUS').change();
  });
</script>