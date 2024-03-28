<form action=$SELF_URL METHOD=POST>

<input type='hidden' name='index' value=$index>
<input type='hidden' name='ID' value='%ID%'>

<div class='card card-primary card-outline box-form form-horizontal'>
<div class='card-header with-border text-primary'>$lang{DISCOUNT}</div>

 <div class='card-body'>
            <div class='form-group'>
                <label class='control-label'>_{NAME}_</label>
                <div>
                    <input class='form-control' type='text' name='NAME' value='%NAME%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label'>_{SIZE}_</label>
                <div>
                    <input class='form-control' type='number' name='SIZE' value='%SIZE%'>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label'>_{DISCOUNT_DESCRIPTION}_</label>
                <div>
                    <textarea class='form-control' name='DESCRIPTION'>%DESCRIPTION%</textarea>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label'>_{DISCOUNT_PCODE}_</label>
                <div>
                    <textarea class='form-control' name='PROMOCODE'>%PROMOCODE%</textarea>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label'>_{DISCOUNT_URL}_</label>
                <div>
                    <textarea class='form-control' name='URL'>%URL%</textarea>
                </div>
            </div>
            <div class='form-group'>
                <label class='control-label'>_{DISCOUNT_STATUS}_</label>
				%DISC_STAT%
            </div>
           <div class='form-group'>
                <label class='control-label'>_{DISCOUNT_LOGO}_</label>
                <div class="form-group">
                    <div class="row">
                        <div class="col-md-2">
                            <input type="file" id="imageInput" accept="image/*">
                        </div>
                        <div class="col-md-2">
                            <img id="previewImage" style="max-width: 300px; max-height: 300px;">
                        </div>
                        <div class="col-md-2">
                            <img id="previewEditImage" src="%LOGO%" alt="Изображение до редактирования" style="display: none; max-width: 300px; max-height: 300px;">
                        </div>
                    </div>
                    <input type="hidden" name="LOGO" id="imageData">
                </div>
            </div>
        </div>

<div class='card-footer'>
  <input type='submit' class='btn btn-primary' name=%ACTION% value='%ACTION_LANG%'>
</div>
</div>

</form>

<script>
    document.addEventListener('DOMContentLoaded', function() {
        const actionValue = '%ACTION%';
        if (actionValue == 'change') {
            document.getElementById('imageData').value = '%LOGO%';
            
            var previewEditImage = document.getElementById("previewEditImage");
            previewEditImage.style.display = "block";
        }
    });

    function submitForm() {
        const formData = new FormData(document.getElementById('discountForm'));
        formData.append('%ACTION%', '%ACTION_LANG%');
        fetch('$SELF_URL', {
            method: 'POST',
            body: formData
        })
        .then(response => response.json())
        .then(data => {
            console.log(data);
        })
        .catch(error => {
            console.error('Error:', error);
        });
    }

    document.getElementById('imageInput').addEventListener('change', function (e) {
            const file = e.target.files[0];

            if (file) {
                const maxSize = 1024 * 1024; // 1 MB

                if (file.size > maxSize) {
                    alert('Выберите изображение меньшего размера.');
                    return;
                }

                const reader = new FileReader();

                reader.onloadend = function () {
                    const base64Data = reader.result;

                    const previewImage = document.getElementById('previewImage');
                    previewImage.src = base64Data;

                    document.getElementById('imageData').value = base64Data;
                };

                reader.readAsDataURL(file);
            }
        });
</script>