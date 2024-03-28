function build_construct(Param_flors, Param_entrances, Param_rooms, elem_id, user_info, lang_pack, min_height, flats_sum, build_schema, numbering_direction, start_numbering_flat) {

  var status_colors = ['#00a65a', "#747372", '#f39c12', '#dd4b39', '#FF8000', '#9b9b9b'];
  var status_colors_window = ["#0000FF", '#0000FF', '#824227', '#009D00', '#FF8000'];
//Primitiv param
  var scale = 60;
  var room_width = scale;
  var room_height = scale * 0.6;
  var window_width = scale * 0.3;
  var window_height = scale * 0.3;
  var door_width = scale * 0.5;
  var door_height = scale * 0.5;
//Primitiv
  var build_window;
  var invis;
  var dor;
  var floor;
  var build_line;

  var tip = jQuery("#tip").hide();
  var tipText = "";
  var over = false;

  var padding = +scale * 2;
  var rooms = Param_rooms * room_width;
  var line_width = 6;
  var entrances_width = Param_rooms * room_width / 2 - room_width;
  var dor_num = 0;
  var flat_score = start_numbering_flat;
  console.log(flat_score);
  var d = 0;
  var timeeqel;
  var canvas_width = jQuery('#canvas_container').prop("clientWidth");
  var paper_height = (Param_flors * room_height + padding) < min_height ? min_height : Param_flors * room_height + padding;
  var paper_width = (room_width * Param_rooms * Param_entrances + padding) < canvas_width ? canvas_width : (room_width * Param_rooms * Param_entrances + padding);
  var build_x = 0;
  var user_info = JSON.parse(user_info);
  var lang_pack = JSON.parse(lang_pack);
  var build_schema = JSON.parse(build_schema);

  if ((room_width * Param_rooms * Param_entrances + padding) < canvas_width) {
    build_x = canvas_width / 2 - ((rooms * Param_entrances) / 2) - room_width;
  }
  else {
    build_x = room_width * Param_rooms * Param_entrances + padding / 2 - (rooms * Param_entrances) - room_width;
  }
  var build_y = paper_height;
  var paper = new Raphael(
    document.getElementById(elem_id),
    paper_width,
    paper_height
  );
  jQuery('#canvas_container').height(paper_height + 40);
  var background = paper
    .rect(0, 0, paper_width, paper_height)
    .attr({
      fill: '#42a5f5',
      stroke: 'none'
    });

// Hover function
  var hoverIn = function () {
    this.attr({
      'fill-opacity': 0.5,
      fill: 'yellow',
      'stroke-width': 1,
      'stroke': 'white'
    });
  };

  var hoverOut = function () {
    this.attr({
      'fill-opacity': 0.0,
      fill: 'yellow',
      cursor: 'pointer',
      'stroke': 'none'
    });
  };

  jQuery(document).mousemove(function (e) {
    if (over) {
      tip.css("left", e.clientX - 70).css("top", e.clientY - (52 + tip.height() / 2));
      tip.html(tipText);
    }
  });

  function addTip(node, txt) {
    jQuery(node).mouseenter(function () {
      tipText = txt;
      tip.show();
      over = true;
    }).mouseleave(function () {
      tip.hide();
      over = false;
    });
  }

  for (dom in build_schema.dom) {
    var f = 2;
    var x_d = (room_width * Param_rooms) * dom;
    if (parseInt(numbering_direction)) {
      x_d = (room_width * Param_rooms) * (build_schema.dom.length - dom - 1);
    }
    for (var r = 0; r <= Param_rooms - 1; r++) {

      floor = paper.rect(build_x + x_d + room_width + (room_width * r), build_y - room_height, room_width, room_height).attr({
        fill: '#7c7977',
        stroke: 'none'
      });
    }

    for (data in build_schema.dom[dom].data) {

      var y_d = room_height * (f++);

      for (var r = 0; r < Param_rooms; r++) {
        var r1 = r;
        if (parseInt(numbering_direction)) {
          r1 = Param_rooms - r - 1;
        }
        if (r >= build_schema.dom[dom].data[data].flats) {
          var addTipStroukc = lang_pack['FLAT'] + ' ' + flat_score;

          floor = paper
            .rect(build_x + x_d + room_width + (room_width * r1), build_y - y_d, room_width, room_height)
            .attr({
              fill: '#e1e2e1',
              stroke: 'none'
            });
          if (invis) {
            invis.hover(hoverIn, hoverOut, invis, invis);
            addTip(invis.node, addTipStroukc);
          }
          continue;
        }
        flat_score++;

        if (typeof (user_info[flat_score]) !== 'undefined') {

          let color = user_info[flat_score]['color'];
          addTipStroukc = user_info[flat_score]['info'];
          floor = paper
            .rect(build_x + x_d + room_width + (room_width * r1), build_y - y_d, room_width, room_height)
            .attr({
              fill: color,
              stroke: 'none'
            });

          if (user_info[flat_score]['quick_info']) {
            paper.text(build_x + x_d + room_width + window_width + room_width * r1 - 5,
              build_y - y_d + 5, user_info[flat_score]['quick_info']).attr({
              'font-size': 10,
              'font-weight': 500,
              'fill': 'black'
            });
          }
        }
        else {
          addTipStroukc = lang_pack['FLAT'] + ' ' + flat_score;
          floor = paper
            .rect(build_x + x_d + room_width + (room_width * r1), build_y - y_d, room_width, room_height)
            .attr({
              fill: 'white',
              stroke: 'none'
            });

        }
        timeeqel = room_width * r1;
        var window_status_color;
        if (flats_sum < (d - 1)) {
          window_status_color = status_colors[5];
        }
        else {
          window_status_color = '#f4faff  ';
        }

        build_window = paper.rect(build_x + x_d + room_width + window_width + timeeqel + (window_height / 5), build_y - y_d + window_height / 2, window_width, window_height).attr({
          fill: window_status_color,
          stroke: 'none'
        });

        var flat_num = paper.text(build_x + x_d + room_width + window_width + timeeqel + (window_height / 1.5),
          build_y - y_d + window_height, flat_score).attr({
          'font-size': 12,
          'font-weight': 900,
          'fill': 'black'
        });

        invis = paper.rect(build_x + x_d + room_width + (room_width * r1), build_y - y_d, room_width, room_height).attr({
          'fill-opacity': 0.0,
          fill: 'yellow',
          cursor: 'pointer',
          'stroke': 'none'
        });

        invis.hover(hoverIn, hoverOut, invis, invis);
        addTip(invis.node, addTipStroukc);
      }
    }

    dor_num++;

    dor = paper.rect(build_x + (x_d - (entrances_width + door_width / 2) + room_width * Param_rooms), build_y - door_height, door_width, door_height).attr({
      fill: '#42a5f5',
      stroke: 'none'
    });

    build_line = paper.path("M" + (build_x + x_d + room_width + room_width * Param_rooms) + "," + (build_y - Param_flors * room_height - room_height) + " L" + (build_x + x_d + room_width + room_width * Param_rooms) + "," + (build_y) + " z").attr({
      'stroke': '#42a5f5',
      'stroke-width': line_width + 'px'
    });

    paper.text(build_x + x_d - (entrances_width) + room_width * Param_rooms, build_y - door_height / 2, dor_num).attr({
      'font-size': 14,
      'font-weight': 900,
      'fill': 'white'
    });
  }
}
