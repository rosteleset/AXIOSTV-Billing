<script src="/styles/default/js/cytoscape.min.js"></script>

<script src="/styles/default/js/cytoscape-popper.js"></script>

<script src="/styles/default/js/tippy.all.min.js"></script>
<link rel="stylesheet" href="/styles/default/css/tippy.css"/>

<div id="cy">
  <div class="info-table">
    <table class="table">
    </table>
  </div>

</div>
<div class="counters-wrap">
  <div class="node-count">_{COUNT}_:</div>
  <div class="time-count">_{TIME}_:</div>
</div>
<style>
  .info-table {
    position: absolute;
    z-index: 99;
    width: 400px;
    top: 20px;
    right: 20px;
    padding: 20px;
    background: rgba(0, 0, 0, 0.5);
    display: none;
  }

  .info-table table {
    margin-bottom: 0;
    color: white;
  }

  #cy {

    width: 100%;
    min-height: 800px;

  }

  #cy canvas {
    left: 0;
  }

  .tippy-popper {
    transition: none !important;
    z-index: 0 !important;
  }

  .counters-wrap {
    height: 50px;
    position: fixed;
    bottom: 10px;
  }

  .node-count, .time-count {
    display: inline-block;
    padding: 5px;
    height: 30px;
    vertical-align: middle;
    background: rgba(0, 0, 0, 0.7);
    color: white;
    text-align: left;
    line-height: 20px;
  }
</style>

<script>
  var data = JSON.parse('%DATA%');
  var nodes = [];
  var edges = [];
  var nodes_count = 0;
  var tippys = [];
  jQuery.each(data.nodes, function (k, v) {
    nodes.push({
      data: {
        id: 'n' + k,
        name: v.name,
        ip: v.ip,
        state: v.state,
        type: v.type_id,
        model: v.model,
        vendor: v.vendor,
        online: v.online || 0
      }
    });
    nodes_count += 1;
  });
  jQuery('.node-count').text('_{COUNT}_: ' + nodes_count);
  jQuery.each(data.edges, function (k, v) {
    edges.push({
      data: {
        id: v.source + ' -> ' + v.target,
        source: 'n' + v.source,
        target: 'n' + v.target,
        name: v.name
      }
    });
  });
  document.addEventListener('DOMContentLoaded', function () {

    var cy = window.cy = cytoscape({
      container: document.getElementById('cy'),

      style: [
        {
          selector: 'node',
          style: {
            'content': 'data(name)',
            'shape': 'roundrectangle',
            'background-image': function (e) {
              switch (parseInt(e.data().type)) {
                case 2:
                  return '/img/netmap/wifi.svg';
                case 3:
                  return '/img/netmap/router.svg';
                case 4:
                  return '/img/netmap/pon.svg';
                case 0:
                  return '/img/netmap/user.svg';
                default:
                  return '/img/netmap/switch.svg';
              }
            },
            'background-color': function (e) {
              switch (parseInt(e.data().state)) {
                case 0:
                  return 'rgb(0,175,0)';
                case 1:
                  return 'rgb(200,0,0)';
                case 2:
                  return 'rgba(100, 100, 100, 0.5)';
                case 3:
                  return 'rgb(0,0,200)';
                case 4:
                  return 'rgb(255, 162, 40)';
              }
            },
            'background-width': '70%',
            'background-height': '70%',
            'width': '70',
            'height': '70'
          }
        },

        {
          selector: 'edge',
          style: {
            'content': 'data(name)',
            'curve-style': 'bezier',
            'target-arrow-shape': 'triangle'
          }
        }
      ],

      elements: {
        nodes: nodes,
        edges: edges
      },

      layout: {
        name: 'concentric',
        fit: true,
        avoidOverlap: false,
        animate: false,
        padding: 100,
        spacingFactor: 10,
        nodeDimensionsIncludeLabels: true,
        startAngle: 0
      }
    });



    var makeTippy = function (node, text) {
      return tippy(node.popperRef(), {
        content: function () {
          var div = document.createElement('div');
          div.className = "tippy";
          div.innerHTML = text;

          return div;
        },
        arrow: true,
        placement: 'bottom',
        hideOnClick: false,
        sticky: true,
        flip: false
      });
    };

    if(nodes.length <= 50) {
      jQuery.each(nodes, function (k, v) {
        var n = cy.getElementById(v.data.id);
        var tippy = makeTippy(n, v.data.ip);
        tippy.show();
      });
    }

    cy.on('zoom', function (evt) {
      jQuery(".tippy").css("width", cy.nodes()[0].width()*cy.zoom());
      jQuery(".tippy").css("font-size", cy.zoom()+"vh");
    });
    cy.on('tap', function (evt) {
      jQuery('.info-table').css('display', 'none');
      jQuery.each(tippys, function (k, v) {
        if(v !== undefined) {
          v.destroy();
          v = undefined;
        }
      });
    });


    cy.on('tap', 'node', function (evt) {
      var node = evt.target;
      var html = '<tr>' +
        '<td>_{NAME}_</td>' +
        '<td>' + node.data().name + '</td>' +
        '</tr>' +
        '<tr>' +
        '<td>IP</td>' +
        '<td>' + node.data().ip + '</td>' +
        '</tr>' +
        '<tr>' +
        '<td>_{MODEL}_</td>' +
        '<td>' + node.data().model + '</td>' +
        '</tr>' +
        '</tr>' +
        '<tr>' +
        '<td>_{VENDOR}_</td>' +
        '<td>' + node.data().vendor + '</td>' +
        '</tr>'+
        '<tr>' +
        '<td>_{ONLINE}_</td>' +
        '<td>' + node.data().online + '</td>' +
        '</tr>';
      jQuery('.info-table').css('display', 'block');
      jQuery('.info-table table').html(html);
      if(nodes.length > 50) {
        jQuery.each(tippys, function (k, v) {
          if(v !== undefined) {
            v.destroy();
            var index = tippys.indexOf(v);
            if (index !== -1) {
              tippys.splice(v, 1);
            }
          }
        });
        showChildTippy(node, makeTippy);
        jQuery(".tippy").css("width", node.width()*cy.zoom());
        jQuery(".tippy").css("font-size", cy.zoom()+"vh");
      }
    });

    var time = (window.performance.timing.domContentLoadedEventStart - window.performance.timing.connectEnd) / 1000;
    jQuery('.time-count').text('_{TIME}_: ' + time);
  });

  function showChildTippy(node, makeTippy) {
    var n = cy.getElementById(node.id());
    var tippy = makeTippy(n, node.data().ip);
    tippys.push(tippy);
    tippy.show();

    edges = cy.edges('[source = "'+node.id()+'"]:visible"');
    jQuery.each(edges, function (k, v) {
      showChildTippy(v.target(), makeTippy);
    });
  }

</script>