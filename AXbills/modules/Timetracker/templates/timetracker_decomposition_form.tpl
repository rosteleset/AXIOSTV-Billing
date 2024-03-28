<style type="text/css">
  .material-switch > input[type="checkbox"] {
    display: none;
}

.material-switch > label {
    cursor: pointer;
    height: 0px;
    position: relative;
    width: 40px;
}

.material-switch > label::before {
    background: rgb(0, 0, 0);
    box-shadow: inset 0px 0px 10px rgba(0, 0, 0, 0.5);
    border-radius: 8px;
    content: '';
    height: 16px;
    margin-top: -8px;
    position:absolute;
    right: 0px;
    opacity: 0.3;
    transition: all 0.4s ease-in-out;
    width: 40px;
}
.material-switch > label::after {
    background: rgb(255, 255, 255);
    border-radius: 16px;
    box-shadow: 0px 0px 5px rgba(0, 0, 0, 0.3);
    content: '';
    height: 24px;
    left: -4px;
    margin-top: -8px;
    position: absolute;
    top: -4px;
    transition: all 0.3s ease-in-out;
    width: 24px;
}
.material-switch > input[type="checkbox"]:checked + label::before {
    background: inherit;
    opacity: 0.5;
}
.material-switch > input[type="checkbox"]:checked + label::after {
    background: inherit;
    left: 20px;
}
</style>

<div class='card card-primary card-outline card-form'>
    <div class='card-header with-border'><h4 class='card-title'>_{IT_DECOMPOSITION}_</h4></div>
    <form name='DECOMPOSITION' id='form_DECOMPOSITION' method='post' class='form form-horizontal'>
        <input type='hidden' name='index' value='$index' />
        <input type='hidden' name='submit' value='1' />
        <div class='list-group-flush'>
            %CHECKBOXES%
        </div>
            <button type="submit" form='form_DECOMPOSITION' class="btn btn-primary btn-md btn-block" name='submit'>_{RESULT}_</button>
    </form>
    </div>
</div>







