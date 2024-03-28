<style>
  #add-card:hover > span {
    color: #ffffff !important;
  }

  #add-card > #add-card-icon {
    font-size: 18px;
    margin-top: 2px;
  }

  #add-card > #add-card-text {
    color: #43464d;
  }

</style>

<div style='display: flow-root;'>
  <p><strong>%MESSAGE%</strong></p>
  <img class='img-fluid center-block' style='max-width: 300px' src='styles/default/img/paysys_logo/masterpass.png'>

  <br>

  <a href='%BTN_URL%' id='add-card' class='btn btn-outline-success mt-2 float-right'>
    <span class='fas text-success fa-plus' id='add-card-icon'></span>
    <span class='ml-2' id='add-card-text'>%BTN_TEXT%<span>
  </a>
</div>
