<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' class='form-inline'>
    <input type='hidden' name='index' value='$index'>
    <input type='hidden' name='NAS_GID' value='$FORM{NAS_GID}'>


    <div class='form-group'>
        <label class='sr-only' for='FILE_UPLOAD'>_{ADD}_ _{FILE}_</label>
        <div class='form-group mb-3 p-1'>
            <input id='FILE_UPLOAD' name='FILE_UPLOAD' value='%FILE_UPLOAD%' placeholder='_{FILE}_'
                   class='input-file form-control p-1' type='file'>
        </div>
    </div>
    <input type='submit' name='UPLOAD' value='_{ADD}_' class='btn btn-secondary btn-success mb-3'>
</FORM>


