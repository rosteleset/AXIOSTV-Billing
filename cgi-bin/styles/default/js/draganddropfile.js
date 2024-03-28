var dropZone = document.querySelector("[data-action=drop-zone]");

dropZone.addEventListener("drop", function (e) {
  dropZone.style.border = "";
  e.preventDefault();

  var inputsList = document.querySelectorAll('input[type=file]');
  var inputLast = inputsList[inputsList.length - 1];

  inputLast.files = e.dataTransfer.files;

  var items = e.dataTransfer.items;
  [...items].forEach(item => {
    if (item.type.indexOf('image/') < 0) {
      var p = document.createElement("li");
      var t = document.createTextNode(escape(item.name));
      p.appendChild(t);
      dropZone.parentElement.appendChild(p);
    }
    else {
      var f = item.getAsFile();
      show_tumbnails(f);
    }
  });
});

dropZone.addEventListener("dragover", function (e) {
  dropZone.style.border = "medium solid #0000FF";
  e.preventDefault();
});

dropZone.addEventListener("paste", function (e) {
  var clipboard = e.clipboardData;
  if (clipboard && clipboard.items) {
    var item = clipboard.items[0];
    if (item && item.type.indexOf('image/') >= 0) {
      e.preventDefault();
      var inputsList = document.querySelectorAll('input[type=file]');
      var inputLast = inputsList[inputsList.length- 1];
      inputLast.files = clipboard.files;
      var f = inputLast.files[0];
      jQuery(inputLast).trigger('change');
      show_tumbnails(f);
    }
  }
});

function show_tumbnails(file) {
  var reader = new FileReader();
  reader.readAsDataURL(file);

  reader.onload = function(event) {
    var img = new Image();
    img.src = event.target.result;
    img.style.height  = "100px";
    dropZone.parentElement.appendChild(img);
  }
}
