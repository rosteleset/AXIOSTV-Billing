<div id='open_popup_block_middle'>
    <div class='modal-content'>
        <div class='modal-header'>
            <button type='button' class='close' data-dismiss='modal' aria-label='Close'>
                <span aria-hidden="true">&times;</span>
            </button>
            <div class='row'>
                <div class='text-center'>
                    <input type='button' class='btn' data-toggle='dropdown' onclick='enableSearchPill();'
                           value='Search'/>
                    <input type='button' class='btn' data-toggle='dropdown' onclick='enableResultPill();'
                           value='Result'/>
                </div>
            </div>
        </div>
        %SUB_TEMPLATE%
        <div class='modal-footer'>
            <div class="text-center">
                <button type='button' class='btn btn-primary form-control' id='search' onclick='getData();'>Search</button>
            </div>
        </div>
    </div>
</div>

