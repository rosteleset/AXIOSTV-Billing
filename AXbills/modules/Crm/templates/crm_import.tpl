<style>
	.associative-fields {
		width: 100%;
		min-height: 20px;
	}
</style>

<div class='card card-primary card-outline'>
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
                <label for='loadFile'>_{FILE}_</label>
                <input class='form-control p-1' id='loadFile' type='file'>
              </div>
              <div class='form-group col-md-6'>
                <label>_{SEPARATOR}_</label>
                <input class='form-control p-1' id='splitter' type='text' maxlength='2' placeholder=';'>
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
          <div class='card-body' style='max-height: 510px; overflow-y: scroll;'>
            <div id='import-field-from'></div>
          </div>
        </div>
      </div>
      <div class='col-lg-6' id='import-field-to'>
        <div class='card card-primary card-outline'>
          <div class='card-header'>
            <h4 class='card-title'>АСР КАЗНА 39 _{FIELDS}_</h4>
          </div>
          <div class='card-body' style='max-height: 510px; overflow-y: scroll;'>
            %OUTPUT_STRUCTURE%
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class='card-footer'>
    <button disabled class='btn btn-primary' id='import'>_{IMPORT}_</button>
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

  class crmImportField {
    constructor(type) {
      this.type = type
      this.examples = []
    }

    addExample(example) {
      this.examples = [...this.examples, example]
    }
  }

  class crmImportLoader {
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
            this.inputSchema[field] = new crmImportField(typeof item[field])
          } else if (this.inputSchema[field].examples.length < 3) {
            this.inputSchema[field].addExample(item[field])
          }
        })
      })

      return this.inputSchema
    }
  }

  class crmImport {
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
          this.importSchema[targetPath].value = jQuery(element).data('path')
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
      if (!this.modalStatus || !this.modalProgressbar) return;

      this.modalStatus.textContent = `${done}/${elementCount}`
      this.modalProgressbar.css('width', (done) / elementCount * 100 + '%')
      this.modalProgressbar.attr('aria-valuenow', done)

      if (elementCount === done) {
        const { value: resultIndex } = document.getElementById('RESULT_INDEX')

        window.location.replace(`/admin/index.cgi?index=${resultIndex}`)
      }
    }

    async sandToServer(resultData) {
      let done = 0;

      this.showImportProgressModal(resultData.length)

      for (const [index, item] of resultData.entries()) {
        await fetch('/api.cgi/crm/leads/', {
          method: 'POST',
          mode: 'cors',
          cache: 'no-cache',
          credentials: 'same-origin',
          headers: {'Content-Type': 'application/json'},
          redirect: 'follow',
          referrerPolicy: 'no-referrer',
          body:  JSON.stringify(item)
        });

        done++;

        this.setImportProgressModalStatus(resultData.length, done)
      }
    }
  }

  let crm;
  let crmImportLoaderObject;

  let fileType = 'json';
  const loadUrl = document.getElementById('loadUrl')
  const loadFile = document.getElementById('loadFile')
  const jsonPath = document.getElementById('jsonPath')
  const filters = document.getElementById('filters')

  loadButton.onclick = async () => {
    const readFile = () => new Promise((resolve, reject) => {
      const fileReader = new FileReader();

      fileReader.onload = (ev) => {
        resolve(fileReader.result)
      };

      fileReader.readAsText(loadFile.files[0]);
      if (loadFile.files[0].type === 'text/csv') fileType = 'csv';
    });

    if (loadFile.files.length) {
      fileJson = await readFile()
    } else {
      return
    }

    const data = fileType === 'csv' ? csvParse(fileJson) : JSON.parse(fileJson)

    crmImportLoaderObject = new crmImportLoader(data, jsonPath ? jsonPath.value : '', filters ? filters.value : '')
    crm = new crmImport(crmImportLoaderObject.getFields())

    loadButton.disabled = true
    importButton.disabled = false
  }

  function csvParse(data) {
    const splitter = document.getElementById('splitter').value || ';';
    let rows = data.split('\n');
    let columns = rows.shift().replace(/"/g, '').split(splitter);
    let jsonData = [];

    rows.forEach(rowStr => {
      if (rowStr === '') return;

      let row = rowStr.replace(/"/g, '').split(';');
      let jsonRow = {};
      for (let i = 0; i < columns.length; i++) {
        if (columns[i] === '') continue;

        jsonRow[columns[i]] = row[i];
      }
      jsonData.push(jsonRow);
    });

    return jsonData;
  }

  importButton.onclick = async () => {
    const result = crm.getResult(crmImportLoaderObject.getData())

    crm.sandToServer(result)
  }
</script>