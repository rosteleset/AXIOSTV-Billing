<!-- To new scheme in the future
<div class='card mt-3'>
  <div class='card-body p-1'>
    <div class='row m-0'>
      <span class='d-flex align-items-center mx-2'>_{DOCUMENTATION_LAST_UPDATE}_: %UPDATE_DATE%</span>
      <button id='update_from_doc' class='btn btn-xs btn-success ml-1' type='button'>_{UPDATE}_</button>
    </div>
  </div>
</div>
-->
<script>
  const probablyUpdateDate = '%UPDATE_DATE%';
  const updateDate = new Date(probablyUpdateDate);

  const currentDate = new Date();
  const currentVersion = '%VERSION%';
  const versionWhenUpdated = '%VERSION_DOCS_UPDATE%' || '1.00.00';

  const numberedCurrentVersion = currentVersion.replace(/\./g, '');
  const numberedInUpdateVersion = versionWhenUpdated.replace(/\./g, '');

  const timeDiff = currentDate - updateDate;
  const daysDiff = Math.floor(timeDiff / (1000 * 60 * 60 * 24));

/* To new scheme in the future
  if (!probablyUpdateDate || daysDiff > 28 || numberedCurrentVersion > numberedInUpdateVersion) {
    updateConfButton('loading');
    updateFromDocumentation(0).then(data => {
      if (data.error) {
        throw data.error;
      };
      if (data.status == 2) {
        updateConfButton('success');
        location.reload(true);
      }
    }).catch(err => {
      updateConfButton('error');
      throw err;
    });
  }
*/

  function updateFromDocumentation(force) {
    return fetch('$SELF_URL?get_index=config_update_docs&header=2&FORCE=' + force)
      .then(res => {
        if(!res.ok) {
          return res.text().then(text => { throw new Error(text) })
         }
        else {
         return res.json();
       }
      });
  }

  function updateConfButton(status) {
    const button = jQuery('#update_from_doc');
    if (status === 'error') {
      const icon = jQuery('<i>').addClass('fas fa-times fa-lg');
      const iconContainer = jQuery('<div>').append(icon);
      const label = jQuery('<h6>_{ERROR}_!</h6>').addClass('m-0 ml-2');
      const labelContainer = jQuery('<div>')
                               .append(iconContainer, label)
                               .prop('class', 'row justify-content-center m-3')
                               .addClass('text-danger');

      jQuery('#label1').replaceWith(labelContainer.clone());
      jQuery('#label2').replaceWith(labelContainer);

      button.html('_{UPDATE}_');
    } else if (status === 'loading') {
      const icon = jQuery('<i>').addClass('fas fa-circle-notch fa-spin fa-lg');
      const iconContainer = jQuery('<div>').append(icon);
      const label = jQuery('<h6>_{DOCUMENTATION_UPDATING_WEB}_</h6>').addClass('m-0 ml-2');
      const labelContainer = jQuery('<div>')
                              .append(iconContainer, label)
                              .prop('class', 'row justify-content-center m-3');

      labelContainer.clone().prop('id','label1').insertBefore('.card-primary');
      labelContainer.prop('id', 'label2').insertAfter('.card-primary');
      button.prop('disabled', true);
    } else {
      const icon = jQuery('<i>').addClass('fas fa-check fa-lg');
      const iconContainer = jQuery('<div>').append(icon);
      const label = jQuery('<h6>_{SUCCESS}_!</h6>').addClass('m-0 ml-2');
      const labelContainer = jQuery('<div>')
                               .append(iconContainer, label)
                               .prop('class', 'row justify-content-center m-3')
                               .addClass('text-success');

      jQuery('#label1').replaceWith(labelContainer.clone());
      jQuery('#label2').replaceWith(labelContainer);

      button.html('_{UPDATE}_');
    }
  }

/* To new scheme in the future
  jQuery('#update_from_doc').on('click', function() {
    updateConfButton('loading');
    updateFromDocumentation(1).then(data => {
      if (data.error) {
        throw data.error;
      };
      updateConfButton('success');
      location.reload(true);
    })
    .catch(err => {
      updateConfButton('error');
      throw err;
    });
  });
*/
</script>