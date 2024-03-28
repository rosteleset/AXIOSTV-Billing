
/*
  Purpose of this code for ABillS:
    1 Increasing and decreasing number of buttons in table header by resize and not
    2 Closing right sidebar if user clicked in overlay
    3 Sidebar search
    4 Clear sidebar search input by closing
    5 Result former activating fields on click
      Result former "activate" checked fields
    6 Result former field search
*/

var mybody = document.body;

const dropdownTemplate = jQuery(
  `<div class="btn-group" style="display: none;">
      <button class="btn btn-default btn-xs dropdown-toggle" aria-expanded="false" data-toggle="dropdown">
        <span class="caret"></span>
      </button>
      <div class="dropdown-menu dropdown-menu-right"></div>
   </div>`
  );

let rightSidebarButton = document.getElementById('right_menu_btn');
let rightSidebar = document.getElementsByClassName('control-sidebar')[0];

let axbillsBtnGroup = document?.getElementById('axbillsBtnGroup');
let axbillsDropdownGroup = (function () {
                            const element = axbillsBtnGroup?.children[axbillsBtnGroup?.children?.length - 1];
                            if(element?.classList[0] === 'btn-group') {
                              return jQuery(element);
                            } else {
                              return jQuery(axbillsBtnGroup)
                                        .append(dropdownTemplate)
                                        .children("div:last-child");
                            }
                          })();

let axbillsDropdownToggle = axbillsDropdownGroup?.children()[0];
let axbillsDropdown = axbillsDropdownGroup?.children()[1];

var myflag = 2;

/* 1 */
function calculateBtnGroup() {
  /* cf width for typical btn, maybe calculate dynamically by content, but so hard */
  const calculatedButtonWidth = 142;

  const parentWidth = axbillsBtnGroup.parentElement.clientWidth;
  const scrollWidth = axbillsBtnGroup.parentElement.parentElement.scrollWidth;
  const maybeWidth = (axbillsBtnGroup.children.length - 1) * calculatedButtonWidth;

  /* inserting items to dropdown list from btn-group */
  if (parentWidth < maybeWidth) {
    let needToAdd = parseInt((maybeWidth - parentWidth) / calculatedButtonWidth);

    // watching if buttons header bigger than parent at real
    if (scrollWidth > parentWidth) {
      needToAdd += 1;
    }

    if (needToAdd != 0) {
      [...axbillsBtnGroup.children].reverse().forEach(element => {
        if (element.classList[0] != 'btn-group') {
          if (needToAdd) {
            --needToAdd;
            if (element.classList.contains('active')) {
              element.className = 'dropdown-item active';
            } else {
              element.className = 'dropdown-item';
            }

            axbillsDropdown.prepend(element);
          }
        }
      });
      if (axbillsDropdown.children.length) {
        axbillsDropdownGroup.show();
      }
    }
  }  /* inserting items to btn-group from dropdown list */
  else if (parentWidth > maybeWidth) {
    let needToAdd = parseInt((parentWidth - maybeWidth) / calculatedButtonWidth);

    if (needToAdd != 0) {
      [...axbillsDropdown.children].forEach(element => {
        if (needToAdd) {
          --needToAdd;
          if(element.classList.contains('active')) {
            element.className = 'btn btn-default btn-xs active';
          } else {
            element.className = 'btn btn-default btn-xs';
          }
          axbillsDropdownGroup.before(element);
        }
      });
      let itemsLength = axbillsDropdown.children.length;
      if (needToAdd >= itemsLength) {
        axbillsDropdownGroup.hide();
      }
    }
  }

  if (myflag) {
    --myflag;
    calculateBtnGroup();
  }
}

window.addEventListener('resize', controlRightMenu, false);
if(axbillsBtnGroup) {
  calculateBtnGroup();
  window.addEventListener('resize', calculateBtnGroup, false);
  rightSidebar.addEventListener('transitionend', calculateBtnGroup, false);
}


/* 2 */
jQuery(() => {
  jQuery('#sidebar-overlay').on('click', () => {
    jQuery('body').removeClass('control-sidebar-slide-open')
  })
})

/* 3 */
function sidebarSearch() {
  const menuItems = jQuery('nav > .nav-sidebar li');
  const menuTrees = jQuery('nav > .nav-sidebar ul');

  jQuery('#Search_menus').on('input', function () {
    const searchValue = this.value.toLowerCase();
    const matchedTrees = [];

    if (!searchValue) {
      menuItems.removeAttr('style');
      menuTrees.removeAttr('style');
      return;
    }

    menuTrees.css('display', 'block');
    menuItems.css('display', 'none');

    menuItems.filter(function () {
      let item = this.children[0];
      let tree = this.children[1];
      let isMatched = item.textContent.toLowerCase().includes(searchValue);

      if (tree) {
        let isMatchedTree = tree.textContent.toLowerCase().includes(searchValue);
        if (isMatched && !isMatchedTree) {
          matchedTrees.push(this);
        }
        else if (isMatchedTree) {
          isMatched = true;
        }

      };

      return isMatched;
    }).css('display', 'block');

    matchedTrees.forEach(function(item) {
      let _this = jQuery(item);
      let tree = jQuery(_this.children()[1]);
      // Cleanup hardcoded css for smooth animation
      tree.css('display', '');
      _this.on('click', function() {
        tree.children().css('display', '');
        _this.off('click');
      })
    })
  });
}

/* 4 */
function sidebarButton() {
  const sidebarButton = document.getElementById('sidebar_button');
  const inputSearch = document.getElementById('Search_menus');

  sidebarButton.addEventListener('click', () => {
    const inputFill = sidebarButton
                        .parentElement
                        .parentElement
                        .parentElement.classList.contains("sidebar-search-open");
    if (inputFill) {
      inputSearch.value = '';
      inputSearch.dispatchEvent(new Event('input'));
    }
  })
}

/* 5 */
function resultFormerFillCheckboxes() {
  var $ = jQuery;
  const checkboxParents = $('.axbills-checkbox-parent');
  checkboxParents.children('input[type=checkbox][checked=checked]').parent().addClass('active');
  checkboxParents.click(function(event) {
    const _this = $(this);
    if (event.target.type !== 'checkbox') {
      const myCheckbox = _this.find('input[type=checkbox]');
      myCheckbox.click();
      const isChecked = myCheckbox.prop("checked");
      if(isChecked) {
        _this.addClass('active');
      } else {
        _this.removeClass('active');
      }
    }
  });
}

/* 6 */
function resultFormerCheckboxSearch() {
  var $ = jQuery;
  const checkboxParents = $('.axbills-checkbox-parent');

  $('#resultFormSearch').on('input', function () {
    const searchValue = this.value.toLowerCase();
    if (searchValue) {
      checkboxParents.css('display', 'none');
      checkboxParents.filter(function () {
        return this.textContent.toLowerCase().includes(searchValue)
      }).css('display', 'block');
    } else {
      checkboxParents.removeAttr('style');
    }
  });
}

sidebarSearch();
sidebarButton();
resultFormerFillCheckboxes();
resultFormerCheckboxSearch();
