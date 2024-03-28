%DISTRICT_SEL%

<script>

  var district_id = jQuery(`[name='ID']`).val() || 0;

  if (jQuery(`[name='%DISTRICT_IDENTIFIER%']`).length < 1) {
    jQuery(jQuery(`[name='DISTRICT_SEL']:not([change-set])`).first().append(jQuery('<input/>', {
      type: 'hidden',
      name: '%DISTRICT_IDENTIFIER%',
      value: '%DISTRICT_SELECTED%'
    })))
  }

  jQuery(`[name='DISTRICT_SEL']:not([change-set])`).on('change', loadDistrictChild).attr('change-set', 1);
  function loadDistrictChild() {
    let district_sel = jQuery(this);

    let container = district_sel.parent().parent().parent().parent().parent();

    district_sel.parent().parent().parent().parent().nextAll('.mt-3').remove();

    let id = district_sel.val();
    if (Array.isArray(id)) {
      if (!id[0]) id.shift();
      id = !id.length ? '' : id.join(';');
    }

    jQuery(`[name='%DISTRICT_IDENTIFIER%']`).val(id);

    if (!id) {
      let lastActiveSelect = jQuery(`[name='DISTRICT_SEL']:has(option:selected):not(#${district_sel.attr('id')})`).last();
      let prev_id = lastActiveSelect.val() || '';
      jQuery(`[name='%SELECT_NAME%']`).val(prev_id);
      jQuery(`[name='%DISTRICT_IDENTIFIER%']`).val(prev_id);

      let customEvent = new CustomEvent('district-change', {detail: {district: lastActiveSelect}});
      document.dispatchEvent(customEvent);
      return;
    }

    fetch(`/api.cgi/districts?PARENT_ID=${id}&PARENT_NAME=_SHOW&ID=!${district_id}&PAGE_ROWS=1000000`, {
      mode: 'cors',
      cache: 'no-cache',
      credentials: 'same-origin',
      headers: {'Content-Type': 'application/json'},
      redirect: 'follow',
      referrerPolicy: 'no-referrer',
    })
      .then(response => {
        if (!response.ok) throw response;
        return response;
      })
      .then(response => response.json())
      .then(data => {
        let customEvent = new CustomEvent('district-change', {detail: {district: district_sel}});
        document.dispatchEvent(customEvent);

        if (data.length < 1) return;
        createSelect(data, container, id);
      })
      .catch(e => {
        console.log(e);
      });
  }

  function createSelect(data, container, parent_id) {
    let selectId = `DISTRICT_${Date.now()}`;
    let selectList = jQuery('<select></select>', {class: 'mt-1', id: selectId, name: 'DISTRICT_SEL'});
    let inputGroup = jQuery('<div></div>', {class: 'input-group-append select2-append'}).append(selectList);
    let flexFill = jQuery('<div></div>', {class: 'flex-fill bd-highlight overflow-hidden select2-border'}).append(inputGroup);
    let dFlex = jQuery('<div></div>', {class: 'd-flex bd-highlight'}).append(flexFill);

    if (jQuery(`[name='DISTRICT_MULTIPLE']`).length > 0) {
      let checkbox = jQuery('<input/>', {type: 'checkbox', name: `DISTRICT_MULTIPLE_${parent_id}`, value: 1,
        class: 'form-control-static m-2', id: `DISTRICT_MULTIPLE_${selectId}`, 'data-select-multiple': selectId})
      let checkboxGroup = jQuery('<div></div>', {class: 'input-group-text p-0 px-1 rounded-left-0'}).append(checkbox);
      let groupAppend = jQuery('<div></div>', {class: 'input-group-append h-100'}).append(checkboxGroup);
      let db = jQuery('<div></div>', {class: 'bd-highlight'}).append(groupAppend);
      dFlex.append(db);
    }

    let group = jQuery('<div></div>', {class: 'mt-3'}).append(dFlex);
    container.append(group);

    defineLinkedInputsLogic(group);
    let default_option = jQuery('<option></option>', {value: '', text: '--'});
    selectList.append(default_option);

    let optgroups = {};
    data.forEach(address => {
      if (!optgroups[address.parentId]) {
        optgroups[address.parentId] = jQuery(`<optgroup label='== ${address.parentName} =='></optgroup>`);
      }

      let option = jQuery('<option></option>', {value: address.id, text: address.name});
      optgroups[address.parentId].append(option);
    });

    jQuery.each(optgroups, function(key, value) { selectList.append(value);});

    initChosen();
    selectList.select2({width: '100%', allowClear: true, placeholder: ''});
    selectList.on('change', loadDistrictChild).focus().select2('open');
  }
</script>