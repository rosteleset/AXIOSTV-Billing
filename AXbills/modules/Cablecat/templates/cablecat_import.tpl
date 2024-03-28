<style>
	.associative-fields {
		width: 100%;
		min-height: 50px;
	}
</style>

<div class='card card-primary card-outline'>
  <input type='hidden' value='%IMPORT_INDEX%' id='IMPORT_INDEX'>
  <input type='hidden' value='%RESULT_INDEX%' id='RESULT_INDEX'>

  <div class='card-header with-border'>
    <h4 class='card-title'>_{IMPORT}_</h4>
  </div>
  <div class='card-body container-fluid'>
    <div class='row'>
      <div class='col-lg-12'>
        <div class='card'>
          <div class='card-body'>
            <div class='row'>
              <div class='form-group col-md-6'>
                <label for='loadUrl'>URL</label>
                <input class='form-control' id='loadUrl' placeholder='url' type='text'>
              </div>

              <div class='form-group col-md-6'>
                <label for='loadUrl'>_{PATH}_ JSON</label>
                <input class='form-control' id='jsonPath' placeholder='json path' type='text'>
              </div>

              <div class='form-group col-md-6'>
                <label for='loadUrl'>_{FILE}_ JSON</label>
                <input class='form-control' id='loadFile' type='file'>
              </div>

              <div class='form-group col-md-6'>
                <label for='loadUrl'>_{FILTERS}_</label>
                <input class='form-control' id='filters' type='text'>
              </div>

              <div class='col-md-12'>
                <button class='btn btn-info' id='load'>_{SEND}_</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div class='row'>
      <div class='col-lg-6'>
        <div class='card card-primary card-outline'>
          <div class='card-header'>
            <h4 class='card-title'>API _{FIELDS}_</h4>
            <div class='card-tools float-right'>
              %LOAD_PRESET_BTN%
            </div>
          </div>
          <div class='card-body'>
            <div id='import-field-from'></div>
          </div>
        </div>
      </div>
      <div class='col-lg-6' id='import-field-to'>
        %OUTPUT_STRUCTURE%
      </div>
    </div>

    <button disabled class='btn btn-primary' id='import'>_{IMPORT}_</button>
    <button  class='btn btn-primary' id='save_preset'>_{SAVE_PRESET}_</button>
  </div>
</div>

<div class='modal fade' id='import-progress-modal' tabindex='-1' role='dialog' aria-labelledby='exampleModalLabel'
     aria-hidden='true'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      <div class='modal-header'>
        <h5 class='modal-title' id='exampleModalLabel'>_{IMPORT}_</h5>
      </div>
      <div class='modal-body'>

        <span id='import-progress-modal-status'></span>
        <div class='progress'>
          <div class='progress-bar' id='import-progress-modal-progressbar' role='progressbar' aria-valuenow='0'
               aria-valuemin='0' aria-valuemax='0'></div>
        </div>
      </div>
      <div class='modal-footer'>
        <button type='button' id='import-progress-modal-close' class='btn btn-primary hidden' data-dismiss='modal'>
          _{CLOSE}_
        </button>
      </div>
    </div>
  </div>
</div>

<div class='modal fade' id='save-preset-modal' tabindex='-1' role='dialog' aria-hidden='true'>
  <div class='modal-dialog' role='document'>
    <div class='modal-content'>
      <div class='modal-header'>
        <h5 class='modal-title'>_{SAVE_PRESET}_</h5>
        <button type='button' class='close' data-dismiss='modal'>&times;</button>
      </div>
      <div class='modal-body'>
        <div class='form-group row'>
          <label class='col-md-4 col-form-label text-md-right required' for='PRESET_NAME'>_{NAME}_:</label>
          <div class='col-md-8'>
            <input type='text' class='form-control' required name='PRESET_NAME' id='PRESET_NAME'/>
          </div>
        </div>
      </div>
      <div class='modal-footer'>
        <button type='button' id='save-import-preset-modal' class='btn btn-primary' data-dismiss='modal'>
          _{SAVE}_
        </button>
      </div>
    </div>
  </div>
</div>

<template id='import-field-template'>
  <div draggable='true' class='card card-outline import-field'>
    <div class='card-header'>
      <span class='import-field-name'></span>
      <a data-tooltip-position='top' data-html='true' data-toggle='popover' data-trigger='hover'
         data-placement='top' data-container='body' data-original-title='' title=''>
        <i class='float-right import-field-examples fa fa-info'></i>
      </a>
    </div>
  </div>
</template>

<script>
  const loadButton = document.getElementById('load')
  const importButton = document.getElementById('import')
  const savePresetButton = document.getElementById('save_preset')

  class CablecatImportField {
    constructor(type) {
      this.type = type
      this.examples = []
    }

    addExample(example) {
      this.examples = [...this.examples, example]
    }
  }

  class CablecatImportLoader {
    constructor(rawData, structurePath, filterString) {
      this.filterSetup(filterString)

      this.data = this.unfold(structurePath ? rawData[structurePath] : rawData)
      this.inputSchema = {}
    }

    filterSetup(filterString) {
      const filterConditionsString = filterString.split(';')

      this.filter = filterConditionsString
        .map(conditionString => conditionString.split('='))
        .map(([field, condition]) => ({field, condition}))
    }

    useFilter(element) {
      if (this.filter.condition === undefined) return element;
      return this.filter.every(({field, condition}) => element[field] && element[field] == condition)
    }

    getData() {
      return this.data;
    }

    unfold(data) {
      const unfoldElement = (element) => {
        const elementKeys = Object.keys(element)
        let transformedElement = {}

        const objectElementKeys = elementKeys
          .filter(key => typeof element[key] === "object")

        if (objectElementKeys.length === 0) {
          return element
        }

        objectElementKeys
          .forEach(key => {
            transformedElement = {
              ...transformedElement,
              ...element[key]
            }
          })

        transformedElement = {
          ...transformedElement,
          ...(elementKeys
            .filter(key => typeof element[key] !== "object")
            .reduce((obj, key) => ({
              ...obj,
              [key]: element[key]
            }), {}))
        }

        return unfoldElement(transformedElement)
      }

      if (typeof data === 'object')
        data = Object.values(data)

      return data
        .map((element) => unfoldElement(element))
        .filter((element) => this.useFilter(element))
    }

    getFields() {
      this.data.forEach(item => {
        const fields = Object.keys(item)

        fields.forEach(field => {
          if (!this.inputSchema[field]) {
            this.inputSchema[field] = new CablecatImportField(typeof item[field])
          } else if (this.inputSchema[field].examples.length < 3) {
            this.inputSchema[field].addExample(item[field])
          }
        })
      })

      return this.inputSchema
    }
  }

  class CablecatImport {
    constructor(inputSchema) {
      this.inputSchema = inputSchema

      this.importSchema = {}

      this.drawInputSchema(inputSchema)

      const fieldsContainer = document.getElementById('import-field-to')
      const outputFields = document.querySelectorAll('.output-field')

      outputFields.forEach((element) => {
        const container = element.querySelector('.associative-fields')
        const name = element.querySelector('.output-field-name')

        const input = element.querySelector('input, select')

        jQuery(container).data('path', name.textContent)
        this.importSchema[name.textContent] = {}
        this.importSchema[name.textContent].defaultInput = input
      })

      fieldsContainer.ondragover = (event) => {
        const target = event.target

        if (target.className.includes('associative-fields')) {
          event.preventDefault();
        }
      }
      fieldsContainer.ondrop = (event) => {
        const target = event.target

        if (target.className.includes('associative-fields')) {
          event.preventDefault();

          const data = event.dataTransfer.getData("field");
          const element = document.getElementById(data)
          event.target.appendChild(element);

          const targetPath = jQuery(target).data('path')
          const elementPath = jQuery(element).data('path')

          this.importSchema[targetPath].value = elementPath
        }
      }

    }

    drawInputSchema(inputSchema) {
      const importFieldTemplateBuild = (index, name, examples) => {
        const importFieldTemplate = document.querySelector('#import-field-template')
        const importFieldTemplateContent = importFieldTemplate.content

        const card = importFieldTemplateContent.querySelector('.import-field')
        card.id = `import-field_${index}`

        const nameNode = card.querySelector('.import-field-name')
        nameNode.textContent = name

        const examplesNode = card.querySelector('.import-field-examples')
        nameNode.dataContent = examples

        return jQuery(document.importNode(importFieldTemplate.content, true))
      }

      const inputFieldsContainer = jQuery('#import-field-from')

      document.getElementById('import-field-from').ondragstart = (event) => {
        event.dataTransfer.setData("field", event.target.id);
      }

      Object.entries(this.inputSchema).forEach(([name, {
        type,
        examples
      }], index) => {
        const element = jQuery(importFieldTemplateBuild(index, name, examples))
        jQuery(inputFieldsContainer).append(element)

        jQuery(`#import-field_${index}`).data('path', name)
      });
    }

    getResult(data) {
      const result = []
      const fields = Object.getOwnPropertyNames(this.importSchema)

      fields.forEach(field => {
        const defaultInput = this.importSchema[field].defaultInput

        if (!defaultInput) {
          return
        }

        if (defaultInput.value) {
          this.importSchema[field].default = defaultInput.value
          return
        }


        if (defaultInput.type == 'checkcard') {
          this.importSchema[field].default = +!!defaultInput.checked
          return
        }
      })

      data.forEach(item => {
        const device = {}

        fields.forEach(field => {
          if (this.importSchema[field].value && item[this.importSchema[field].value]) {
            device[field] = item[this.importSchema[field].value]
            return
          }

          if (this.importSchema[field].default) {
            device[field] = this.importSchema[field].default
          }

        })

        result.push(device)
      })

      return result
    }

    showImportProgressModal(elementCount) {
      const importProgressModal = jQuery('#import-progress-modal')

      jQuery(importProgressModal).modal({
        show: true,
        keyboard: false,
        backdrop: false,
      })

      const modalStatus = document.getElementById('import-progress-modal-status')
      const modalProgressbar = jQuery('#import-progress-modal-progressbar')

      this.modalStatus = modalStatus
      this.modalProgressbar = modalProgressbar

      modalStatus.textContent = `0/${elementCount}`
      modalProgressbar.attr('aria-valuemax', elementCount)
      modalProgressbar.attr('aria-valuenow', 0)
    }

    setImportProgressModalStatus(elementCount, done) {
      if (!this.modalStatus || !this.modalProgressbar) {
        return
      }

      this.modalStatus.textContent = `${done}/${elementCount}`
      this.modalProgressbar.css('width', (done) / elementCount * 100 + '%')
      this.modalProgressbar.attr('aria-valuenow', done)

      if (elementCount === done) {
        const {
          value: resultIndex
        } = document.getElementById('RESULT_INDEX')

        window.location.replace(`/admin/index.cgi?index=${resultIndex}`)
      }
    }

    async sandToServer(resultData, importIndex) {
      let done = 0;

      this.showImportProgressModal(resultData.length)

      let requestPackage = []

      for (const [index, item] of resultData.entries()) {
        const params = {
          ...item,
          add: 1,
          submit: 'add',
          index: importIndex,
          MESSAGE_ONLY: 1,
        }

        await fetch('/admin/index.cgi/?' + new URLSearchParams(params).toString())

        done++;

        this.setImportProgressModalStatus(resultData.length, done)
      }
    }
  }

  let cableCat;
  let cablecatImportLoader;

  const loadUrl = document.getElementById('loadUrl')
  const loadFile = document.getElementById('loadFile')
  const jsonPath = document.getElementById('jsonPath')
  const filters = document.getElementById('filters')

  const inputSchema = {}

  loadButton.onclick = async () => {
    const readFile = () => new Promise((resolve, reject) => {
      const fileReader = new FileReader();

      fileReader.onload = () => {
        resolve(fileReader.result)
      };

      fileReader.readAsText(loadFile.files[0]);
    });

    let jsonData = '[]'

    if (loadFile.files.length) {
      fileJson = await readFile()
    } else if (loadUrl.value) {
      try {
        fileJson = await fetch(loadUrl.value)

        fileJson = await fileJson.text()
      } catch (e) {
        alert(e)
      }
    } else {
      return
    }

    const data = JSON.parse(fileJson)

    cablecatImportLoader = new CablecatImportLoader(data, jsonPath.value, filters.value)
    cableCat = new CablecatImport(cablecatImportLoader.getFields())

    loadButton.disabled = true
    importButton.disabled = false
  }

  importButton.onclick = async () => {
    const result = cableCat.getResult(cablecatImportLoader.getData())

    const importIndex = document.getElementById('IMPORT_INDEX').value

    cableCat.sandToServer(result, importIndex)
  }

  savePresetButton.onclick = async () => {
    jQuery(jQuery('#save-preset-modal')).modal({
      show: true,
      keyboard: false,
      backdrop: false,
    });
  }

  jQuery('#save-import-preset-modal').on('click', function() {
    const url = '/admin/index.cgi';
    const data = {
      header              : 2,
      SAVE_PRESET         : 1,
      get_index           : 'cablecat_import_presets',
      FILTERS             : jQuery('#filters').val(),
      JSON_PATH           : jQuery('#jsonPath').val(),
      LOAD_URL            : jQuery('#loadUrl').val(),
      DEFAULT_OBJECT_NAME : jQuery('#DEFAULT_OBJECT_NAME').val(),
      DEFAULT_TYPE_ID     : jQuery('select#TYPE_ID').val(),
      OBJECT_ADD          : jQuery('#DEFAULT_ADD_OBJECT').prop('checked') ? 1 : 0,
      COORDX              : getFieldItems('COORDX'),
      COORDY              : getFieldItems('COORDY'),
      OBJECT              : getFieldItems('ADD_OBJECT'),
      OBJECT_NAME         : getFieldItems('NAME'),
      TYPE_ID             : getFieldItems('TYPE_ID'),
      PRESET_NAME         : jQuery('#PRESET_NAME').val(),
    };

    jQuery.post(url, data);
  });

  function getFieldItems(field) {
    let items = [];

    jQuery('div#' + field).children().each(function () {
      items.push(jQuery(this).find('span.import-field-name').text());
    });

    return items.join(';');
  }

  function loadPreset(preset) {
    let preset_id = jQuery(preset).val();
    if (!preset_id || preset_id < 1) return;

    jQuery.post('/admin/index.cgi', { header : 2,  get_index : 'cablecat_import_presets', PRESET_ID: preset_id}, function(preset) {
      try {
        const result = JSON.parse(preset);
        jQuery('#filters').val(result['FILTERS']);
        jQuery('#jsonPath').val(result['JSON_PATH']);
        jQuery('#loadUrl').val(result['LOAD_URL']);
        jQuery('#DEFAULT_OBJECT_NAME').val(result['DEFAULT_OBJECT_NAME']);
        jQuery('select#TYPE_ID').val(result['DEFAULT_TYPE_ID']);
        jQuery('select#TYPE_ID').select2().trigger('change');
        jQuery('#DEFAULT_ADD_OBJECT').prop('checked', result['OBJECT_ADD'])

        loadField('COORDX', result['COORDX']);
        loadField('COORDY', result['COORDY']);
        loadField('ADD_OBJECT', result['OBJECT']);
        loadField('NAME', result['OBJECT_NAME']);
        loadField('TYPE_ID', result['TYPE_ID']);

      } catch(e) {
        console.log(e);
      }
    });
  }

  function loadField(fieldName, items) {
    let itemsArray = items.split(';') || [];
    let importFields = jQuery('#import-field-from').find('.import-field-name');

    importFields.each(function() {
      if (!itemsArray.includes(jQuery(this).text())) return;

      jQuery('div#' + fieldName).append(jQuery(this).parent().parent());
    });
  }
</script>