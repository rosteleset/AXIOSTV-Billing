<div class='card card-primary card-outline box-form'>
  <div class='card-header with-border'><h4 class='card-title'>_{OPTIONS}_</h4></div>
  <div class='card-body'>

    <form name='WORDPRESS_OPTIONS' id='form_WORDPRESS_OPTIONS' method='post' class='form form-horizontal'>
      <input type='hidden' name='index' value='$index'/>
      %HIDDEN_INPUTS%

      <div class='form-group'>
        <label class='control-label col-md-5 required' for='BLOG_TAGLINE_ID'>Billing URL</label>
        <div class='col-md-7'>
          <input type='text' class='form-control' required name='axbills_billing_url' id="ABILLS_BILLING_URL"
                 value='%axbills_billing_url%'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-5 required' for='BLOG_TITLE_ID'>%BLOG_TITLE_DESC%</label>
        <div class='col-md-7'>
          <input type='text' class='form-control' required name='blog_title' id="BLOG_TITLE_ID"
                 placeholder='%BLOG_TITLE_DESC%' value='%BLOG_TITLE%'/>
        </div>
      </div>

      <div class='form-group'>
        <label class='control-label col-md-5 required' for='BLOG_TAGLINE_ID'>%BLOG_TAGLINE_DESC%</label>
        <div class='col-md-7'>

          <input type='text' class='form-control' required name='blog_tagline' id="BLOG_TAGLINE_ID"
                 placeholder='%BLOG_TAGLINE_DESC%' value='%BLOG_TAGLINE%'/>
        </div>
      </div>

      <hr/>

      <div class='form-group'>
        <label class='control-label col-md-3'>_{STYLE}_</label>
        <div class='col-md-9'>
          %THEMES_SELECT%
        </div>
      </div>

      <hr/>

      <div class='checkbox'>
        <label>
          <input type='checkbox' class='control-element' %HAS_COA_CHECKED%
                 name='axbills_has_coa'
                 value='1' data-return='1'
                 data-input-enables='ABILLS_COA_ADDRESS,ABILLS_COA_WORK_DAYS,ABILLS_COA_WORK_HOURS,ABILLS_COA_HOLIDAY_HOURS,ABILLS_COA_HOLIDAY_DAYS'>
          <strong>Есть центр обслуживания абонентов</strong>
        </label>
      </div>

      <br/>

      <fieldset id='coa_params'>
        <div class='form-group'>
          <label class='control-label col-md-3' for='BLOG_TAGLINE_ID'>Адрес</label>
          <div class='col-md-9'>
            <input type='text' class='form-control' name='axbills_coa_address' id="ABILLS_COA_ADDRESS"
                   value='%axbills_coa_address%'/>
          </div>
        </div>
        <div class="col-md-6">
          <div class='form-group'>
            <label class='control-label col-md-5' for='BLOG_TAGLINE_ID'>Рабочие дни</label>
            <div class='col-md-7'>
              <input type='text' class='form-control' name='axbills_coa_work_days' id="ABILLS_COA_WORK_DAYS"
                     value='%axbills_coa_work_days%'/>
            </div>
          </div>
          <div class='form-group'>
            <label class='control-label col-md-5' for='BLOG_TAGLINE_ID'>Время работы в рабочие дни</label>
            <div class='col-md-7'>
              <input type='text' class='form-control' name='axbills_coa_work_hours' id="ABILLS_COA_WORK_HOURS"
                     value='%axbills_coa_work_hours%'/>
            </div>
          </div>
        </div>
        <div class="col-md-6">
          <div class='form-group'>
            <div class='form-group'>
              <label class='control-label col-md-5' for='BLOG_TAGLINE_ID'>Выходные дни</label>
              <div class='col-md-7'>
                <input type='text' class='form-control' name='axbills_coa_holiday_days' id="ABILLS_COA_HOLIDAY_DAYS"
                       value='%axbills_coa_holiday_days%'/>
              </div>
            </div>
            <label class='control-label col-md-5' for='BLOG_TAGLINE_ID'>Время работы в выходные</label>
            <div class='col-md-7'>
              <input type='text' class='form-control' name='axbills_coa_holiday_hours'
                     id="ABILLS_COA_HOLIDAY_HOURS"
                     value='%axbills_coa_holiday_hours%'/>
            </div>
          </div>
        </div>

      </fieldset>

      <hr/>

      <div class='form-group'>
        <label class='control-label col-md-5 required' for='BLOG_TAGLINE_ID'>E-Mail провайдера</label>
        <div class='col-md-7'>
          <input type='text' class='form-control' required name='axbills_provider_mail' id="ABILLS_PROVIDER_MAIL"
                 value='%axbills_provider_mail%'/>
        </div>


      </div>

      <hr/>

      <div class='checkbox-block'>
        <div class='checkbox'>
          <label>
            <input type='checkbox' class='control-element' %DEFAULT_COMMENT_STATUS_CHECKED%
                   name='default_comment_status' value='open' data-return='1'>
            <strong>%DEFAULT_COMMENT_STATUS_DESC%</strong>
          </label>
        </div>


        <div class='checkbox'>
          <label>
            <input type='checkbox' class='control-element' %USERS_CAN_REGISTER_CHECKED%
                   name='users_can_register' value='1' data-return='1'/>
            <strong>%USERS_CAN_REGISTER_DESC%</strong>
          </label>
        </div>


        <div class='checkbox'>
          <label>
            <input type='checkbox' class='control-element' %ABILLS_SLIDESHOW_ON_CHECKED%
                   name='axbills_slideshow_on' value='1' data-return='1'/>
            <strong>_{GALLERY_ON}_</strong>
          </label>
        </div>
      </div>


    </form>

  </div>
  <div class='card-footer'>
    <input type='submit' form='form_WORDPRESS_OPTIONS' class='btn btn-primary' name='action' value='_{SAVE}_'>
  </div>
</div>

