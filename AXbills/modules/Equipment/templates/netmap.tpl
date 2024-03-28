<div class="row">
  <div id = "for_canvas" class="col-md-10">
    <canvas id="viewport" width="600" height="600"></canvas>
  </div>
  <div class="col-md-2" id="node_info"></div>
</div>
<script>
  function show_node_info(node) {
    var status_hash = JSON.parse('%STATUS_LANG_HASH%');
    var info_table = '';
	if (node.data.type == 'server') {
	  info_table = 
        "<table border=\"1\">"    + 
        "<tr><td>Name</td><td>"   + node.data.name  + "</td></tr>" +
	    "<tr><td>IP</td><td>"     + node.data.ip    + "</td></tr>" +
	    "<tr><td>Status</td><td>" + status_hash[node.data.state] + "</td></tr>" +
	    ((node.data.online)?("<tr><td>Online</td><td>"  + node.data.online + "</td></tr>"):'') +
		((node.data.zapped)?("<tr><td>Zapped</td><td>"  + node.data.zapped + "</td></tr>"):'') +
	    "</table>"
	};
	if (node.data.type == 'user') {
	  info_table = node.data.name;
	}
	jQuery('#node_info').html(info_table);
  }
  
  (function(jQuery){
    DeadSimpleRenderer = function(canvas){
	  var canvas = jQuery(canvas).get(0)
      var ctx = canvas.getContext("2d");
      var particleSystem = null
      ctx.font="12px Georgia";
	  var show_info = null

      var that = {
        init:function(system){
          particleSystem = system
          particleSystem.screenSize(canvas.width, canvas.height)
          particleSystem.screenPadding(100)
		  that.initMouseHandling()
        },

        redraw:function(){
          ctx.clearRect(0,0, canvas.width, canvas.height)

          particleSystem.eachEdge(function(edge, pt1, pt2){
            ctx.strokeStyle = "black"
            ctx.lineWidth = 2
            ctx.beginPath()
            ctx.moveTo(pt1.x, pt1.y)
            ctx.lineTo(pt2.x, pt2.y)
            ctx.stroke()
          })

          particleSystem.eachNode(function(node, pt){
            var w = 40
			if (node.data.type == 'server') {
			  if (node.data.state != 0) {ctx.strokeStyle="#FF0000"}
			  else {ctx.strokeStyle="#000000"}
              ctx.clearRect(pt.x-w*1.5, pt.y-w/2, w*3, w)
              ctx.strokeRect(pt.x-w*1.5, pt.y-w/2, w*3, w)
			  if (node.data.name) {
				ctx.font = "bold 14px Arial"
                ctx.fillText(node.data.name.substring(0,14),pt.x-node.data.name.substring(0,14).length*4,pt.y-3)
              }
              if (node.data.ip) {
				ctx.font = "14px Arial"
                ctx.fillText(node.data.ip,pt.x-node.data.ip.length*3.5,pt.y+14)
              }

/*			  var img = new Image();
			  img.src = "/img/network.gif";
			  ctx.drawImage(img, pt.x-w/2, pt.y-w/2, w, w);
			  if (node.data.name) {
                ctx.fillText(node.data.name,pt.x-node.data.name.length*3,pt.y + w/2 + 10)
              }
*/
			}
			if (node.data.type == 'user') {
			  var img = new Image();
			  img.src = "/img/user.png";
			  ctx.drawImage(img, pt.x-w/2, pt.y-w/2, w, w);
            }
          })
        },
		
		initMouseHandling:function(){
          var dragged = null;
          var handler = {
            clicked:function(e){
              var pos = jQuery(canvas).offset();
              _mouseP = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)
              dragged = particleSystem.nearest(_mouseP);

              if (dragged && dragged.node !== null){
				dragged.node.fixed = true
				if (dragged.node.data.name !== show_info) {
			      show_node_info(dragged.node);
				  show_info = dragged.node.data.name
				}
              }

              jQuery(canvas).bind('mousemove', handler.dragged)
              jQuery(window).bind('mouseup', handler.dropped)

              return false
            },
            dragged:function(e){
              var pos = jQuery(canvas).offset();
              var s = arbor.Point(e.pageX-pos.left, e.pageY-pos.top)

              if (dragged && dragged.node !== null){
                var p = particleSystem.fromScreen(s)
                dragged.node.p = p
              }

              return false
            },

            dropped:function(e){
              if (dragged===null || dragged.node===undefined) return
              if (dragged.node !== null) dragged.node.fixed = false
              dragged.node.tempMass = 1000
              dragged = null
              jQuery(canvas).unbind('mousemove', handler.dragged)
              jQuery(window).unbind('mouseup', handler.dropped)
              _mouseP = null
              return false
            }
          }
          jQuery(canvas).mousedown(handler.clicked);
		}
      }
      return that
    }

  jQuery(function(){
    document.getElementById('viewport').width = jQuery('#for_canvas').width();
	document.getElementById('viewport').height = jQuery('#for_canvas').height();
    var sys = arbor.ParticleSystem(100, 600, 0);
    sys.renderer = DeadSimpleRenderer("#viewport")
    var data = JSON.parse('%DATA%')
    sys.graft({nodes:data.nodes, edges:data.edges})
  })
})
(this.jQuery)

</script>
<script src="/styles/default_adm/js/arbor.js"></script>
