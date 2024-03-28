/* Attach with default size*/
attachWebcam(640, 480);

function attachWebcam(width, height) {
    $('#result_frame,  #camera_result').css({
        height: height,
        width: width
    });

    Webcam.set({
        height: height,
        width: width,
        flip_horiz: true
    });

    Webcam.attach('#camera_preview');
    setLiveState();
}


function setLiveState() {
    Webcam.unfreeze();
    $('#upload_btn').addClass('disabled');

    var snapshot_btn = $('#snapshot_btn');
    snapshot_btn.text('Take snapshot');
    snapshot_btn.addClass('btn-primary');
    snapshot_btn.on('click', function () {
        setFrozenState();
    });
}

function setFrozenState() {
    Webcam.freeze();
    $('#upload_btn').removeClass('disabled');

    var snapshot_btn = $('#snapshot_btn');
    snapshot_btn.text('Take another');
    snapshot_btn.removeClass('btn-primary');
    snapshot_btn.on('click', function () {
        setLiveState()
    });
}


function upload() {

    /*Get data from webcam*/
    var data_uri = '';
    Webcam.snap(function (data_uri_) {
        data_uri = data_uri_;
    });

    /*if got data fill and send form*/
    if (data_uri != '') {
        document.getElementById('PHOTO').value = data_uri.replace(/^data\:image\/\w+\;base64\,/, '');
        document.getElementById('submit_photo_form').submit();
    }
}

function changeResolution(obj) {

    var select = $(obj);

    /*Get option value from given object(<select>)*/
    /*
    var value = select.val();
    var option = select.children('option')[value];
    var text = option.innerText;
    */

    /*Get current chosen option*/
    var select_chosen = $('#'+select.attr('id')+ '_chosen');
    var text = select_chosen.find('>a>span').text();

    /*Extract resolution from option innner text*/
    var newResolution = text.split('x');
    var width = newResolution[0];
    var height = newResolution[1];

    setResolution(width, height);
}

function setResolution(width, height) {

    /*change preview size and remove old data*/
    var result = $('#result_frame');

    result.css({
        height: height,
        width: width
    });

    result.empty();

    /*reload camera*/
    Webcam.reset();
    attachWebcam(width, height);
}