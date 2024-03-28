<style>
  .used_field_select {
    cursor: pointer;
  }

  .used_field__active .used_field_selected {
    display: inline !important;
  }
</style>

<input type='hidden' id='fileName' value='%FILE_NAME%'>
<input type='hidden' id='dcs' value='%DSC%'>
<input type='hidden' id='pdf_base64' value='%PDF_BASE64%'>
<input type='hidden' id='saveIndex' value='%SAVE_INDEX%'>

<div id='pdf_header'></div>

<div class='card'>
  <div class='container-fluid'>
    <div class='row'>
      <div class='pl-0 col-6'>
        <div class='card card-primary card-outline mb-0'>
          <div class='card-header'>
            <h6 class='card-title'>_{AVAILABLE}_</h6>
          </div>

          <div id='available_fields' class='card-body overflow-auto vh-75'></div>
        </div>
      </div>

        <div class='pr-0 col-6'>
          <div class='card card-success card-outline mb-0'>
            <div class='card-header'>
              <h6 class='card-title'>_{USED}_</h6>
            </div>

            <div id='used_fields' class='card-body overflow-auto vh-75'></div>
          </div>
        </div>
      </div>
    </div>

    <div class='card-footer'>
      <ul class='float-left pagination mb-0' id='pdf_editor_pages'></ul>
      <button id='save_dsc' class='float-right float-right btn btn-success'>_{SAVE}_</button>
    </div>

</div>

<canvas id='pdf_editor'></canvas>

<script src='/styles/default/js/pdf.min.js'></script>
<script src='/styles/default/js/pdf.worker.min.js'></script>

<script id='used_field' type='x-tmpl-mustache'>
  <div class='card used_field mb-2'>
    <div class='used_field_select card-header p-0 pl-3 pr-3 d-flex align-items-center justify-content-between'>
      <div>
        {{ title }}
        <span class='used_field_selected d-none'>
          <i class='fa fa-check'></i>
        </span>
      </div>

      <input type='number' min='1' placeholder='px' class='used_field_font_size m-2 ml-auto' value='{{ fontSize }}''>
      <input type='color' class='form-control col-1 used_field_color p-1' name='COLOR' value='{{ fontColor }}' type='color'>

      <button class='ml-4 btn btn-danger btn-sm used_field_remove'>
        <i class='fa fa-trash fa-lg'></i>
      </button>
    </div>
  </div>
</script>

<script id='available_field' type='x-tmpl-mustache'>
  <div class='d-flex align-items-center justify-content-between'>
    <div class='available_field_title'>{{ title }}</div>
    <button data-variable='{{ value }}' data-example-value='_{VALUE}_' class='btn available_field_add'>_{ADD}_</button>
  </div>
</script>

<script id='docs_not_available'>
  <div class='card card-danger card-outline'>
    <div class='card-body'>
      Docs $lang{MODULE_NOT_TURNED_ON}!
    </div>
  </div>
</script>
<script>
  /* Rendering available Docs variables */
  const availableFieldsNew = document.getElementById('available_fields');
  const available_field_template = jQuery('#available_field').html();

  const myData = %DOCS_VARS%;

  Mustache.parse(available_field_template);

  const dataKeys = Object.keys(myData);
  if(dataKeys.length === 0) {
    const notAvailableDocs = jQuery('#docs_not_available').html();
    jQuery(availableFieldsNew).append(notAvailableDocs);
  }
  dataKeys.forEach(key => {
    const ava_field = Mustache.render(available_field_template, {
      title: myData[key],
      value: key
    });
    const myfield = jQuery(ava_field);
    jQuery(availableFieldsNew).append(myfield);
  });

  Object.keys(myData)
</script>
<script>
  pdfjsLib.disableWorker = true;
  let scale = 1.7;

  class PdfTemplateField {
    constructor(variable, x, y, exampleValue = '_{VALUE}_', fontSize = 12, fontColor = '#000') {
      this.variable = variable

      this.x = x
      this.y = y

      this.fontSize = fontSize
      this.fontColor = fontColor

      this.exampleValue = variable
    }

    draw(canvas, context) {
      context.fillStyle = this.fontColor
      context.font = `${ this.fontSize * scale }px Arial`
      context.fillText(this.exampleValue, this.x * scale, canvas.height - this.y * scale)
    }
  }

  const availableFields = document.getElementById('available_fields');
  const usedFields = document.getElementById('used_fields');
  const canvas = document.getElementById('pdf_editor');
  const context = canvas.getContext('2d');
  const dcs = JSON.parse(jQuery('#dcs').val())
  const used_field_template = jQuery('#used_field').html()
  const pages = []

  let pageNumber = 0
  let selectedField = null

  Mustache.parse(used_field_template)

  function buildDscFile() {
    let fields = {}

    pages
      .map((page, index) => {
        page.forEach(field => {
          const variable = field.variable
          const fieldUseList = fields[variable]

          const fieldInfo = {
            ...field,
            page: index,
          }

          if(fieldUseList) {
            fieldUseList.push(fieldInfo)
          } else {
            fields[variable] = [fieldInfo]
          }

        })
      })

      let dsc = ''
      const canvasHeightScaled = canvas.height / scale

      Object.keys(fields).forEach(fieldKey => {
        dsc += `${fieldKey}:::(`

        fields[fieldKey].forEach(field => {
          dsc += `page=${field.page + 1};x=${Math.round(field.x)};y=${Math.round(field.y)};font_size=${field.fontSize};font_color=${field.fontColor};,`
        })

        dsc += ')\n'
      })

      return dsc
  }

  document.addEventListener('DOMContentLoaded', async () => {
    const pdfData = document.getElementById('pdf_base64').value.replaceAll('\n', '')
    const pdfLoader = pdfjsLib.getDocument({ data: atob(pdfData) })

    const pdf = await pdfLoader.promise

    async function renderPage(pdf, canvas, context, reloadUsedFields = true) {
      const page = await pdf.getPage(pageNumber + 1)

      const viewport = page.getViewport({ scale });

      canvas.height = viewport.height;
      canvas.width = viewport.width;

      var renderContext = {
        canvasContext: context,
        viewport: viewport
      }

      await page.render(renderContext).promise;

      pages[pageNumber].forEach(pdfTemplateField => {
        pdfTemplateField.draw(canvas, context)
      })

      if(reloadUsedFields) {
        drawUsedField()
      }
    }

    function drawUsedField() {
      jQuery(usedFields).html('')

      pages[pageNumber].forEach(pdfTemplateField => {
        const usedField = Mustache.render(used_field_template, {
          ...pdfTemplateField,
          title: pdfTemplateField.variable
        })

        const usedFieldNode = jQuery(usedField)

        jQuery(usedFields).append(usedFieldNode)

        jQuery('.used_field').removeClass('used_field__active')

        if(selectedField == pdfTemplateField) {
          jQuery(usedFieldNode).addClass('used_field__active')
        }

        jQuery(usedFieldNode).find('.used_field_remove').on('click', async () => {
          pages[pageNumber].splice(jQuery(usedFieldNode).index(),1)
          jQuery(usedFieldNode).remove()

          await renderPage(pdf, canvas, context, pageNumber)
        })

        jQuery(usedFieldNode).find('.used_field_select').on('click', async () => {
          selectedField = pdfTemplateField

          jQuery('.used_field').removeClass('used_field__active')
          jQuery(usedFieldNode).addClass('used_field__active')
        })

        jQuery(usedFieldNode).find('.used_field_font_size').on('input', async ({ target }) => {
          pdfTemplateField.fontSize = target.value

          await renderPage(pdf, canvas, context, pageNumber, false)
        })

        jQuery(usedFieldNode).find('.used_field_color').on('input', async ({ target }) => {
          pdfTemplateField.fontColor = target.value

          await renderPage(pdf, canvas, context, pageNumber, false)
        })
      })
    }

    const pagesSelectBar = document.getElementById('pdf_editor_pages');

    [...Array(pdf.numPages).keys()]
      .map(pageNumber => pageNumber + 1)
      .forEach(pageNumber => {
        pages.push([])
        pagesSelectBar.innerHTML += `<li class='page-item'><a class='page-link' href='#'>${ pageNumber }</a></li>`
      });

    [...Object.keys(dcs)]
      .forEach(dcsVariable => {
        const dcsFields = dcs[dcsVariable]

        dcsFields.forEach(dcsField => {
          const dcsFieldObject = new PdfTemplateField(dcsVariable, dcsField.x, dcsField.y)

          pages[dcsField.page].push(dcsFieldObject)
      });
    })

    await renderPage(pdf, canvas, context)

    pagesSelectBar.addEventListener('click', async ({ target }) => {
      if(jQuery(target).hasClass('page-link')) {
        pageNumber = target.innerHTML - 1

        await renderPage(pdf, canvas, context)
      }
    })

    availableFields.addEventListener('click', async ({ target }) => {
      if(jQuery(target).hasClass('available_field_add')) {
        const { variable, exampleValue } = target.dataset

        const newSelectedField = new PdfTemplateField(variable, 100, 100, exampleValue)
        selectedField = newSelectedField

        pages[pageNumber].push(selectedField)

        await renderPage(pdf, canvas, context)
      }
    })

    canvas.addEventListener('click', async (event) => {
      if(selectedField) {
        const { offsetX, offsetY } = event

        selectedField.x = offsetX / scale
        selectedField.y = (canvas.height - offsetY) / scale

        await renderPage(pdf, canvas, context, pageNumber)
      }
    })
  });

  jQuery('#save_dsc').click(() => {
    const dscFileContent = buildDscFile()
    jQuery('#pdf_header').html('<span class="offset-6 fa fa-spin fa-spinner"></span>');
    var templateInfo = {
      qindex: jQuery('#saveIndex').val(),
      header: 2,
      JSON: 1,
      AJAX: 1,
      DSC_CONTENT: dscFileContent,
      FILE_NAME: jQuery('#fileName').val()
    };

    jQuery.post(SELF_URL, templateInfo)
    .catch((e) => (console.log(e)))
    .then((data) => {
      var res = (() => {
        try {
          return JSON.parse(data);
        } catch(e) {
          return { "status": 403 };
        }
      })('');

      if (res.status == 200) {
        var pdfAlert = '';
        pdfAlert = '<div class="alert alert-success text-left"> \
        <h4><span class="fa fa-check-circle"></span> _{SUCCESS}_</h4> \
        ' + jQuery('#fileName').val() + '.pdf' + ' _{TPL_CHANGED}_ </div>'
      } else {
        pdfAlert = '<div class="alert alert-danger text-left"> \
        <h4><span class="fa fa-times-circle"></span> _{ERROR}_ - _{TPL_NOT_CHANGED}_</h4> \
        _{CHECK_FILE_PERMISSIONS}_ ' + jQuery('#fileName').val() + '.pdf' + '</div>'
      }

      jQuery('#pdf_header').html(pdfAlert);
    });
  });
</script>