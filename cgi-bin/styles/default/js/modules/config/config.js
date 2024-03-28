function init_config() {
  let add_button = $('#add_multimultival');
  let del_button = $('#del_multimultival');

  if (add_button) {
    add_button.on('click', function() {
      let value_container = $('#multimultival');
      let child_values = value_container.children('[id^="param_"]:last');

      let num = parseInt(child_values.prop("id").match(/\d+/g), 10) +1;
      let cloned_values = child_values.clone().prop('id', 'param_'+num );
      cloned_values.find('[id^="count_"]').prop('id', 'count_'+num).html(num).end();
      cloned_values.find('input').map(function() {
        let item = jQuery(this);
        let id = item.prop('id');
        let name = item.prop('name');
        let splitted = name.split('_');
        let number_key = splitted.pop();
        let count_key = splitted.pop();
        let value = splitted.join('_');

        let final_key = [value, num - 1, number_key].join('_');
        item.prop('id', final_key);
        item.prop('name', final_key);
        return this;
      });

      value_container.append(cloned_values);
    });
  }

  if (del_button) {
    del_button.on('click', function() {
      let value_container = $('#multimultival');
      let children = value_container.children('div');

      if (children.length > 1) {
        children.last().remove();
      }
    });
  }
}

jQuery(function () {
  init_config();
});
