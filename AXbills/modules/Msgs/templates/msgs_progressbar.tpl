<style>
    ol.progtrckr, ol.progtrckrText {
        margin: 0;
        padding: 0;
        list-style-type: none;
    }

    ol.progtrckr li {
        display: inline-block;
        text-align: center;
        line-height: 3em;
    }

    ol.progtrckrText li {
        display: inline-block;
        text-align: center;
        line-height: 1em;
    }

    ol.progtrckr-width[data-progtrckr-steps='2'] li {
        width: 49%;
    }

    ol.progtrckr-width[data-progtrckr-steps='3'] li {
        width: 33%;
    }

    ol.progtrckr-width[data-progtrckr-steps='4'] li {
        width: 24%;
    }

    ol.progtrckr-width[data-progtrckr-steps='5'] li {
        width: 19%;
    }

    ol.progtrckr-width[data-progtrckr-steps='6'] li {
        width: 16%;
    }

    ol.progtrckr-width[data-progtrckr-steps='7'] li {
        width: 14%;
    }

    ol.progtrckr-width[data-progtrckr-steps='8'] li {
        width: 12%;
    }

    ol.progtrckr-width[data-progtrckr-steps='9'] li {
        width: 11%;
    }

    ol.progtrckr li.progtrckr-done {
        color: black;
        border-bottom: 4px solid yellowgreen;
    }

    ol.progtrckr li.progtrckr-todo {
        color: silver;
        border-bottom: 4px solid silver;
    }

    ol.progtrckr li:after {
        content: '\00a0\00a0';
    }

    ol.progtrckr li:before {
        position: relative;
        bottom: -2.5em;
        float: left;
        left: 50%;
        line-height: 1em;
    }

    ol.progtrckr li.progtrckr-done:before {
        content: '\2713';
        color: white;
        background-color: yellowgreen;
        height: 1.2em;
        width: 1.2em;
        line-height: 1.2em;
        border: none;
        border-radius: 1.2em;
    }

    ol.progtrckr li.progtrckr-todo:before {
        content: '\039F';
        color: silver;
        background-color: white;
        font-size: 1.5em;
        bottom: -1.6em;
    }

    #step_icon {
        margin-bottom: 1em;
    }

    @media (max-width: 768px) {
        #step_name {
            line-height: 4em;
            text-align: center;
            horiz-align: center;
        }

        #step_name li:nth-child(even) {
            position: relative;
            bottom: -2em;
        }
    }
</style>

<script>

    function fillNames(namesArr) {
        var olElement = jQuery('#step_icon');
        var olElementName = jQuery('#step_name');
        var olElementDate = jQuery('#step_date');

        jQuery('.progtrckr-width').attr('data-progtrckr-steps', namesArr.length);

        for (var i = 0; i < namesArr.length; i++) {
            // console.log('appending' + namesArr[i][0] + ':"' + namesArr[i][1] + '"');
            appendProgressElement(namesArr[i][0], namesArr[i][1], i);
        }

        function appendProgressElement(name, date, i) {
            olElementName.append(createLiElement(name));

            olElement.append(createLiElement().attr('id', i));

            olElementDate.append(createLiElement(date));

            function createLiElement(text) {
                var li = jQuery('<li></li>');
                if (text) li.html(text);
                return li;
            }
        }

    }


    function refreshProgress() {
        clearProgress();
        var progress = jQuery('#progressStatus').val();
        console.log(progress);
        for (var i = 0; i <= progress; i++) {
            toggleElement(jQuery('#step_icon').children()[i]);

            getLocation();
        }
    }

    function clearProgress() {
        jQuery('#step_icon').children().attr('class', 'progtrckr-todo');
    }

    function toggleElement(element) {
        jQuery(element).attr('class', 'progtrckr-done');
    }

    jQuery(document).ready(function () {
        fillNames(namesArr);
        refreshProgress();

        jQuery('.progtrckr>li').on('click', function () {
            jQuery('#progressStatus').val(this.id);
            refreshProgress();

            getLocation();

        });

        //remove tips alert-info if no text
        var tipsDiv = jQuery('#tips');
        if (tipsDiv.text() == '') tipsDiv.remove();
    });
</script>


<script>
    <!--
    var namesArr = [ %PROGRESS_NAMES% ]
    -->
</script>


<div class='row' id='progressTracker'>
    <input type='hidden' name='STEP_NUM' id='progressStatus' value='%CUR_STEP%'/>
    <input type='hidden' name='COORDX' id='location_x'/>
    <input type='hidden' name='COORDY' id='location_y'/>

    <hr/>
    
    <div class='alert alert-info' id='tips'>%TIPS%</div>

    <ol class='progtrckrText progtrckr-width' id='step_name'></ol>
    <ol class='progtrckr progtrckr-width' id='step_icon'></ol>
    <ol class='progtrckrText progtrckr-width' id='step_date'></ol>

    <hr/>
</div>
