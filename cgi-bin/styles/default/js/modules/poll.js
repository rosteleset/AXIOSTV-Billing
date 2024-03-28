$(function () {
  var answerCounter = 2;

  var $wrapper = $('#extraAnswerWrapper');
  var $controls = $('#extraAnswerControls');
  var $addBtn = $controls.find('#addAnswerBtn');
  var $remBtn = $controls.find('#removeAnswerBtn');

  var labelText = $('#answerLabel').text();

  //bind Events
  $addBtn.on('click', function (e) {
    e.preventDefault();
    addNewAnswer();
  });

  $remBtn.on('click', function (e) {
    e.preventDefault();
    removeLastAnswer();
  });

  fillExistingAnswers($('#extra_answers').val());

  function addNewAnswer() {
    $wrapper.append(getNewAnswer(++answerCounter));

    function getNewAnswer(number) {
      var $inputDiv = $('<div class="form-group" id="EXTRA_ANSWER_' + number + '""><label class="col-md-3 control-label">'+ labelText +' ' + number + '</label>' +
                        '<div class="col-md-9">' +
                        '<input type="text" class="form-control" name="EXTRA_ANSWER" value="" placeholder="' + labelText + '">' +
                        '</div>' +
                        '</div>');

    console.log($inputDiv);

    return $inputDiv;
    }
  }

  function removeLastAnswer() {
    $('#EXTRA_ANSWER_' + answerCounter--).remove();
  }

  function fillExistingAnswers(jsonString) {
    try {
      if (typeof(jsonString) !== 'undefined' && jsonString.length > 0) {
        var answer_rows = JSON.parse(jsonString);
        console.log(answer_rows)
        $.each(answer_rows, function (i, answer) {
          appendRow(i, answer);
        })
      }

    } catch (Error) {
      console.log(jsonString);
      alert("[ Poll.js ] Error parsing existing answers : " + Error);
    }

    function appendRow(number, answer) {
      console.log("Number - " + number, "Answer - " + answer);
      $wrapper.append(getFilledExtraPortGroup(number, answer));
    }

    function getFilledExtraPortGroup(number, answer) {
      var $inputDiv = $('<div class="form-group" id="EXTRA_ANSWER_' + number + '""><label class="col-md-3 control-label">'+ labelText +' ' + number + '</label>' +
                        '<div class="col-md-9">' +
                        '<input type="text" class="form-control" disabled name="EXTRA_ANSWER" value="' + answer + '" placeholder="' + labelText + '">' +
                        '</div>' +
                        '</div>');
      answerCounter++;
      return $inputDiv;
    }

  }

});
