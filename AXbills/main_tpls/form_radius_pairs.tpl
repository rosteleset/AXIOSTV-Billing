<div class='form-group'>
    <input type=hidden name='RAD_PAIRS_JSON' id="RAD_PAIRS_JSON" value='%RAD_PAIRS%'>
    <input type=hidden name='SAVE_INDEX' id="SAVE_INDEX" value='%SAVE_INDEX%'>
    <input type=hidden name='RESOURCE_ID' id="RESOURSE_ID" value='%ID%'>

    <label class='col-sm-offset-2 col-sm-8'>RADIUS</label>
    <div class='col-md-12'>
        <table class='table table-bordered table-hover'>
            <thead>
                <tr>
                    <th class='text-center'>
                        _{EMPTY_FIELD}_
                    </th>
                    <th class='text-center'>
                        _{LEFT_PART}_
                    </th>
                    <th class='text-center'>
                        _{CONDITION}_
                    </th>
                    <th class='text-center'>
                        _{RIGHT_PART}_
                    </th>
                </tr>
            </thead>
            <tbody id='radius_parameters'></tbody>
        </table>
    </div>
    <div class='col-12 float-right d-flex'>
        <span id='operation_result_message' class="flex-grow-1"></span>
        <a title='_{ADD}_' class='d-block m-1 btn btn-sm btn-info' id='add_field'>
            <span class='fa fa-plus'></span>
        </a>
        <a title='_{DELETE}_' class='d-block m-1 btn btn-sm btn-info' id='del_field'>
            <span class='fa fa-minus'></span>
        </a>
        <a title='_{SAVE}_' class='d-block m-1 btn btn-sm btn-primary' id='save_pairs'>
            <span class='fa fa-check'></span>
        </a>
    </div>
</div>

<script id='form_radius_pairs_ignore' type='x-tmpl-mustache'>
    <td>
        <span
            data-tooltip="_{EMPTY_FIELD}_"
            data-content="_{EMPTY_FIELD}_"
            data-html="true"
            data-toggle="popover"
            data-trigger="hover"
            data-tooltip-position="right"
            data-container="body"
        >
            <i class="fa fa-exclamation"></i>
            <input type="checkbox" name="ignore" {{ checked }} value="{{ value }}">
        </span>
    </td>
</script>

<script id='form_radius_pairs_input' type='x-tmpl-mustache'>
    <td class='cnd'>
        <input type='text' name='{{ name }}' value='{{ value }}' placeholder='{{ placeholder }}' class='form-control {{ name }}' />
    </td>
</script>

<script>
    class RadiusPair {
        constructor(left = '', condition = '', right = '', ignore = false) {
            this.left = left
            this.condition = condition
            this.right = right

            this.ignore = ignore
        }

        get isEmpty() {
            return !!(this.left || this.right)
        }
    }

    class RadiusPairInput {
        pairInputPart(name = '', placeholder = '', value = '') {
            return Mustache.render(inputTemplate, {
                name,
                placeholder,
                value: value.replaceAll('’', '\'')
            })
        }

        createIgnoreCheckboxInput(isIgnored) {
            const checked = isIgnored ? 'checked' : ''
            const value = isIgnored ? '1' : '0'

            return Mustache.render(ignoreInputTemplate, { value, checked })
        }

        changeHandlerBuilder(radiusPair) {
            return ({ target }) => {
                const fieldName = target.name
                const targetElement = jQuery(target)

                status = 'changed'
                updateSavePairs()

                radiusPair[event.target.name] = targetElement.is(':checkbox') ?
                    target.checked : target.value
            }
        }

        createInput(radiusPair) {
            const newPairInput = jQuery('<tr></tr>')

            newPairInput.append(this.createIgnoreCheckboxInput(radiusPair.ignore))

            newPairInput.append(this.pairInputPart('left', '_{LEFT_PART}_', radiusPair.left))
            newPairInput.append(this.pairInputPart('condition', '=',  radiusPair.condition))
            newPairInput.append(this.pairInputPart('right', '_{RIGHT_PART}_',  radiusPair.right))

            newPairInput.on('input', this.changeHandlerBuilder(radiusPair))

            return newPairInput
        }
    }


    const inputTemplate = jQuery('#form_radius_pairs_input').html()
    Mustache.parse(inputTemplate)

    const ignoreInputTemplate = jQuery('#form_radius_pairs_ignore').html()
    Mustache.parse(ignoreInputTemplate)

    const radiusPairsContainer = jQuery('#radius_parameters')
    const radiusPairInput = new RadiusPairInput()

    let radiusPairs = JSON.parse(jQuery('#RAD_PAIRS_JSON').val())
        .map(pair => new RadiusPair(pair.left, pair.condition, pair.right, Boolean(pair.ignore)) )

    const savePairs = jQuery('#save_pairs')
    const operationResultMessage = jQuery('#operation_result_message')

    const saveIndex = jQuery('#SAVE_INDEX').val()
    const id = jQuery('#RESOURSE_ID').val()

    let status = 'unchanged'

    radiusPairs.forEach(radiusPair => {
        radiusPairsContainer.append(radiusPairInput.createInput(radiusPair))
    })

    function createNewRadiusPair() {
        const newRadiusPair = new RadiusPair()

        radiusPairs.push(newRadiusPair)
        radiusPairsContainer.append(radiusPairInput.createInput(newRadiusPair))
    }

    function updateSavePairs() {
        operationResultMessage.removeClass('text-red')
        operationResultMessage.removeClass('text-green')

        if(status == 'changed') {
            savePairs.removeClass('btn-primary')
            savePairs.addClass('btn-warning')

            operationResultMessage.addClass('text-red')
            operationResultMessage.html('_{UNSAVED_CHANGES}_')
        }

        if(status == 'loading') {
            savePairs.children().removeClass('fa-check')
            savePairs.children().addClass('fa-spinner fa-pulse')
        }

        if(status == 'saved') {
            savePairs.removeClass('btn-warning')
            savePairs.addClass('btn-primary')

            savePairs.children().removeClass('fa-spinner fa-pulse')
            savePairs.children().addClass('fa-check')

            operationResultMessage.addClass('text-green')
            operationResultMessage.html('_{SAVED}_')
        }
    }

    jQuery('#add_field').on('click', () => {
        createNewRadiusPair()

        status = 'changed'
        updateSavePairs()
    })

    jQuery('#del_field').on('click', () => {
        radiusPairs.pop()
        radiusPairsContainer
            .children()
            .last()
            .remove()

        status = 'changed'
        updateSavePairs()
    })

    savePairs.on('click', () => {
        const filledRadiusPairs = radiusPairs.filter(radiusPair => radiusPair.isEmpty)

        status = 'loading'
        updateSavePairs()

        jQuery.post(SELF_URL, {
            qindex: saveIndex,
            header: 2,
            JSON: 1,
            RADIUS_PAIRS: JSON.stringify(filledRadiusPairs),
            ID: id
        }, (result) => {
            try {
                const {status: resultStatus, message} = JSON.parse(result)
                status = 'saved'

            } catch(e) {
                status = 'error'
                console.log(e)
            }

            updateSavePairs()
        })
    })

    createNewRadiusPair()

    // ([0-9a-zA-Z\-!:]+)([-+=]{1,2})([:\-_\;\(\,\)\\'\\’\"\#= 0-9a-zA-Zа-яА-Я.]+)/
</script>
