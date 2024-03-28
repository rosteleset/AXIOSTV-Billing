<div class='panel with-nav-tabs panel-default'>
  <nav class='axbills-navbar navbar navbar-expand-sm navbar-light'>
    <a class='navbar-brand d-sm-none pl-3'>_{MENU}_</a>
    <button
      class='navbar-toggler'
      type='button'
      data-toggle='collapse'
      data-target='#navbarPanelContent'
      aria-controls='navbarPanelContent'
      aria-expanded='false'
      aria-label='_{INTERNET}_ _{MAP}_'
    >
      <span class='navbar-toggler-icon'></span>
    </button>
    <div id='navbarPanelContent' class='collapse navbar-collapse'>
      <ul class='nav nav-tabs navbar-nav'>
        <li class='nav-item'>
          <a class='nav-link %TAB1_ACTIVE% active' href='#tab1default' data-toggle='tab'>
            _{INTERNET}_
          </a>
        </li>
        <li class='nav-item'>
          <a class='nav-link %TAB2_ACTIVE%' href='#tab2default' data-toggle='tab'>
            _{MAP}_
          </a>
        </li>
      </ul>
    </div>
  </nav>
  <div class='panel-body'>
    <div class='tab-content'>
      <div class='active tab-pane %TAB1_ACTIVE%' id='tab1default'>
        <div class='form-group'>
          %FILTERS%
        </div>
        <div class='form-group'>
          %TABLE%
        </div>
      </div>

      <div class='tab-pane %TAB2_ACTIVE%' id='tab2default'>
        %MAPS%
      </div>
    </div>
  </div>
</div>