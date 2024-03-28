<link rel='stylesheet' href='/styles/default/css/jquery-ui.min.css'>
<style>
  ul.color-container {
    min-height: 50px;
    padding-bottom: 50px;
  }

  ul.color-container > li {
    width: 100% !important;
  }

  ul.color-container > li.colorBlock {
    width: 100%;
  }

  ul.color-container > li.colorBlock > div.color-background > span {
    margin: 0;
    padding: 3px;
    background-color: white;
    min-width: 2em;
  }

  ul.color-container > li.colorBlock > div.color-background > span.number {
    position: relative;
    float: left
  }

  ul.color-container > li.colorBlock > div.color-background > span.mark {
    position: relative;
    float: right;
    min-width: 1em;
  }

  ul.color-container > li.colorBlock > div.color-background > span.color_name {
    position: relative;
    float: left;
    opacity: 0.6;
  }

  ul.color-container > li > div.color-background {
    height: 25px;
    margin: 5px 0;
    border: 1px solid silver;
    cursor: pointer;
  }

  ul.color-container {
    list-style: none none;
  }

  #variantsTrash.highlighted {
    border: 1px solid red;
    background-color: lightcoral;
  }

  #resultList.highlighted {
    border: 1px solid lightgreen;
  }
</style>

<div class='card card-primary card-outline card-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{COLOR_SCHEME}_</h4></div>
  <div class='card-body'>

    <form name='CABLECAT_COLOR_SCHEME' id='form_CABLECAT_COLOR_SCHEME' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      <input type='hidden' name='ID' value='%ID%'/>
      <input type='hidden' name='%SUBMIT_BTN_ACTION%' value='1'/>
      <input type='hidden' name='COLORS' value='%COLORS%' id='COLORS_id'/>
      <input type='hidden' value='%CABLECAT_COLORS%' id='CABLECAT_COLORS'/>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right required' for='NAME_id'>_{NAME}_:</label>
        <div class='col-md-8'>
          <input type='text' class='form-control' required='required' name='NAME' value='%NAME%' id='NAME_id'/>
        </div>
      </div>

      <div class='form-group row'>
        <label class='col-md-4 col-form-label text-md-right' for='COLORS_id'>_{COLORS}_</label>
        <div class='col-md-8'>
        </div>
      </div>
    </form>

    <div class='form-group'>
      <div class='btn-group' role='group'>
        <button type='button' class='btn btn-default' id='variantsTrash'>
          <span class='fa fa-trash text-red'></span>
        </button>
        <button type='button' class='btn btn-default' id='duplicateWithMark'>_{DUPLICATE_WITH_MARK}_</button>
        <button type='button' class='btn btn-default' id='duplicateWithMarkTroughOne'>_{DUPLICATE_WITH_MARK}_
          _{THROUGH_ONE}_
        </button>
      </div>
    </div>

    <div class='form-group'>
      <div id='colorPicker' class='row'>
        <div class='col-md-6'>
          <p class='text-center'>_{COLOR_SCHEME}_</p>
          <div id='resultContainer'>
            <ul id='resultList'></ul>
          </div>
        </div>
        <div class='col-md-6'>
          <p class='text-center'>_{AVAILABLE_COLORS}_</p>
          <div id='variantsContainer'>
            <ul id='variantsList'>
            </ul>
          </div>
        </div>
      </div>
    </div>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_CABLECAT_COLOR_SCHEME' class='btn btn-primary' name='submit'
           value='%SUBMIT_BTN_NAME%'>
  </div>
</div>
<script type="text/javascript">
    var COLORS_NAME = {
        '#fcfefc' : '_{WHITE}_',
        '#04fefc' : '_{SEA}_',
        '#fcfe04' : '_{YELLOW}_',
        '#048204' : '_{GREEN}_',
        '#840204' : '_{BROWN}_',
        '#fc0204' : '_{RED}_',
        '#fc9a04' : '_{ORANGE}_',
        '#fc9acc' : '_{PINK}_',
        '#848284' : '_{GRAY}_',
        '#0402fc' : '_{BLUE}_',
        '#840284' : '_{VIOLET}_',
        '#040204' : '_{BLACK}_',
        '#04fe04' : '_{YELLOWGREEN}_',
        '#9cce04' : '_{OLIVE}_',
        '#fcfe9c' : '_{BEIGE}_',
        '#dbefdb' : '_{NATURAL}_',
        '#fde910' : '_{LEMON}_',
        '#9c3232' : '_{CHERRY}_',
    };
</script>
<script src='/styles/default/js/modules/cablecat/color_editor.js'></script>

