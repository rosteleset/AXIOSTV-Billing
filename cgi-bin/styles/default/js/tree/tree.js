function make_tree(data, keys) {
  jQuery('#show_tree').on("click", ".children-toggle" , function() {
    jQuery(this).siblings('.ul-list').slideToggle();
    jQuery(this).children().toggleClass("fa-minus-circle");
    jQuery(this).children().toggleClass("fa-plus-circle");
  });

  var keysArray = keys.split(',');
  var TreeHash = [];
  data.forEach(function(e) {
    var branch = TreeHash;
    for (var i = 0 ; i < keysArray.length; i++) {
      if (!branch[e[keysArray[i]]]) {
        if (i == keysArray.length-1 ) {
          branch[e[keysArray[i]]] = 1;
        }
        else {
          branch[e[keysArray[i]]] = [];
        }
      }
      branch = branch[e[keysArray[i]]];
    }
  });
  jQuery.when(drawTree(TreeHash, true)).then(jQuery('#show_tree').html(htmlTree));
  htmlTree = "";
}

var _EMPTY_FIELD;
function drawTree(treeData, start = false) {
  htmlTree += start ? "<ul class='ul-list'>" : "<ul class='ul-list' style='display: none'>";

  for (const key of Object.keys(treeData)) {
    if (key === "") continue;

    if (treeData[key] && treeData[key] != 1) {
      htmlTree += "<li class='ul-item '><a class='children-toggle' class='btn btn-lg'><i class='fa fa-plus-circle mn'></i>" +
        "</a><span class='parent'>" + (key !== 'undefined' ? key : _EMPTY_FIELD) + "</span>";
      drawTree(treeData[key]);
    } else {
      htmlTree += "<li class='ul-item'><span class='parent'>" + key + "</span>";
    }
    htmlTree += "</li>";
  }
  htmlTree += "</ul>";
}