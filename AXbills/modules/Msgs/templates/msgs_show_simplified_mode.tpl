<FORM action='$SELF_URL' METHOD='POST' enctype='multipart/form-data' name='add_message' id='add_message'>
  <input type='hidden' name='index' value='$index'/>
  <input type='hidden' name='UID' value='$FORM{UID}'/>
  <input type='hidden' name='ID' value='%ID%'/>
  <input type='hidden' name='PARENT' value='%PARENT%'/>
  <input type='hidden' name='CHAPTER' value='%CHAPTER%'/>
  <input type='hidden' name='INNER_MSG' value='%INNER_MSG%'/>

  <div class='card card-primary card-outline card-outline-tabs'>
    <div class='card-header p-0 border-bottom-0'>
      <ul class='nav nav-tabs'>
        <li class='nav-item %TAB1_ACTIVE%'><a class='nav-link' href='#tab1default' data-toggle='tab'>_{MESSAGE}_</a>
        </li>
        <li class='nav-item %TAB2_ACTIVE%'><a class='nav-link' href='#tab2default' data-toggle='tab'>_{REPLYS}_</a></li>
        <li class='nav-item %TAB3_ACTIVE%'><a class='nav-link' href='#tab3default' data-toggle='tab'>_{MANAGE}_</a></li>
      </ul>
    </div>
    <div class='card-body'>
      <div class='tab-content'>

        <div class='tab-pane %TAB1_ACTIVE%' id='tab1default'>
          <div class='card card-outline %MAIN_PANEL_COLOR%'>
            <div class='card-header with-border'>
              <div class='row'>
                <div class='col-md-12'>
                  <div class='card-title'>
                    <span class='badge badge-primary'>%ID%</span>
                    %SUBJECT% %CHANGE_SUBJECT_BUTTON%
                  </div>
                  <div class='card-tools pull-right'>
                    %RATING_ICONS% %PARENT_MSG% %INNER_MSG_TAG%
                  </div>
                </div>
              </div>
            </div>
            <div class='card-body text-left'>
              <div class='row'>
                <div class='col-md-3'><strong>_{STATUS}_:</strong></div>
                <div class='col-md-3'>%STATE_NAME%</div>
                <div class='col-md-3'><strong>_{PRIORITY}_:</strong></div>
                <div class='col-md-3'>%PRIORITY_TEXT%</div>
              </div>
              <div class='row'>
                <div class='col-md-3'><strong>_{CREATED}_:</strong></div>
                <div class='col-md-3'>%DATE%</div>
                <div class='col-md-3'><strong>_{CHAPTER}_:</strong></div>
                <div class='col-md-3'>%CHAPTER_NAME%</div>
              </div>
              <div class='row' style="display: %MSG_TAGS_DISPLAY_STATUS%">
                <div class='col-md-12'>%MSG_TAGS%</div>
              </div>
              %PROGRESSBAR%
            </div>

          </div>
          %WORKPLANNING%

        </div>


        <div class='tab-pane %TAB2_ACTIVE%' id='tab2default'>
          <div class='card card-primary card-outline'>
            <div class='card-header with-border'>
              <h4 class='card-title text-left'>%SUBJECT%</h4>
            </div>
            <div class='card-body'>
              <div class='row'>
                <div class='col-md-12'>
                  <div class='timeline'>
                    <div>
                      <i class='fa fa-user %COLOR%'></i>
                      <div class='timeline-item text-left'>
                        <span class='time'>%DATE%</span>
                        <h3 class='timeline-header'>%LOGIN%</h3>
                        <div class='timeline-body'>%MESSAGE%</div>
                        %ATTACHMENT%
                      </div>
                    </div>
                    %REPLY%
                  </div>
                </div>
              </div>
            </div>
          </div>

          %REPLY_FORM%

        </div>


        <div class='tab-pane %TAB3_ACTIVE%' id='tab3default'>

          %EXT_INFO%

        </div>
      </div>
    </div>
  </div>

  <!-- end of table -->
</form>

<div id='myModalImg' class='modal-img'>
  <span class='closeImageResize'>&times;</span>
  <img class='modal-content-img' id='img_resize'>
  <div id='caption'></div>
  <a id='download_btn' class='btn btn-success btn-large m-2'>_{DOWNLOAD}_</a>
</div>

