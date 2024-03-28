<div class='form-group'>
    <div class='col-md-12'>
        <nav class="navbar navbar-expand-lg">
            <div class="container-fluid">
                <div class="collapse navbar-collapse">
                    <div class="navbar-nav">
                        <a href='$SELF_URL?index=$index&new=1&processed=1&status=0' class='nav-link %LI_ACTIVE_2%'
                            role='button'>_{NEW}_</a>
                        <a href='$SELF_URL?index=$index&processed=2&status=1' class='nav-link %LI_ACTIVE_3%'
                            role='button'>_{PROCESSED}_</a>
                        <a href='$SELF_URL?index=$index&archive=1&status=2' class='nav-link %LI_ACTIVE_4%'
                            role='button'>_{ARCHIVE}_</a>
                        <a href='$SELF_URL?index=$index&all=1' class='nav-link %LI_ACTIVE_1%'
                                role='button'>_{ALL}_</a>
                    </div>
                </div>
            </div>
        </nav>
    </div>
    <div class='form-group'>
        <!-- <div class="row"> -->
            %CONTENT%
        <!-- </div> -->
    </div>
</div>