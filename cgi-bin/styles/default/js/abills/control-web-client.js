
/*
  Control-web for Client side
  Purpose of this code for ABillS:
    1 Increasing and decreasing number of buttons in table header by resize and not
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
  const calculatedButtonWidth = 160;

  const parentWidth = axbillsBtnGroup.parentElement.clientWidth;
  const maybeWidth = (axbillsBtnGroup.children.length - 1) * calculatedButtonWidth;

  /* inserting items to dropdown list from btn-group */
  if (parentWidth < maybeWidth) {
    let needToAdd = parseInt((maybeWidth - parentWidth) / calculatedButtonWidth);

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
      const itemsLength = axbillsDropdown.children.length;
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

if (axbillsBtnGroup) {
  calculateBtnGroup();
  window.addEventListener('resize', calculateBtnGroup, false);
}
