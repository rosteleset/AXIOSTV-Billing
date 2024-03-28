var STICKIES = (function () {
    var openStickies = function openStickies() {

            let ajax_arr = [];

            $.ajax({
                url: '/admin/index.cgi?get_index=notepad_show_sticker&header=2&ajax=1&get_stickers=1',
                success: function(result){
                    if(result) {
                        ajax_arr = JSON.parse(result);
                        for (let i=0; i<ajax_arr.length; i++){
                            createSticky(ajax_arr[i]);
                        }
                    }
                }
            });
        },
        searchKey = function searchKey(array) {
            let sticky_array = [];
            for (let i=0; i<array.length; i++){
                if (array[i].match("sticky-")) sticky_array.push(array[i]) ;
            }
            if (sticky_array.length > 0) return sticky_array;
            return -1;
        },
        sticker_count = 0,
        createSticky = function createSticky(data) {
            sticker_count++;
            data.top  = data.top  || (80+sticker_count*25)+"px";
            data.left = data.left || ($(window).width()-500+sticker_count*25)+"px";


            if (data.status_st === 0){
                return null;
            }

            if (data.subject == null){
                data.subject = data.sticker_title;
            }
            if (data.text == null){
                data.text = data.sticker_text;
            }

            let arr = [];
            let temp_arr = [];

            for (let i = 0; i < localStorage.length; i++) {
                arr.push(localStorage.key(i));
            }
            temp_arr = searchKey(arr);

            data.id = "sticky-"+data.id;
            for (let i=0; i<temp_arr.length; i++){
                if (data.id===temp_arr[i]){
                    let temp = JSON.parse(localStorage.getItem(data.id));
                    data.top = temp.top;
                    data.left = temp.left;
                }
            }

            let background_color = (data.status == 0) ? "#B5D6A5" : "#FFE79C";

            return $("<div />", {
                "class" : "sticky",
                'id' : data.id
            })
		.css({
		  "background-color": background_color
		})
                .prepend($("<div />", { "class" : "sticky-header"} )
                    .append($("<span />", {
                        "class" : "sticky-status",
                        click : saveSticky
                    }))
                    .append($("<a />",{
                        href: '/admin/index.cgi?index='+data.index+'&chg='+data.id.slice(7)+'&MODULE=Notepad'
                    })
                        .append($("<span />", {
                            html : data.subject,
                            "class" : "title",
                            keypress : markUnsaved
                        })))
                )
                .append($("<div />", {
                    html : data.text,
                    "class" : "sticky-content",
                    keypress : markUnsaved
                }))
                .draggable({
                    handle : "div.sticky-header",
                    stack : ".sticky",
                    start : markUnsaved,
                    stop  : saveSticky
                })
                .css({
                    position: "absolute",
                    "top" : data.top,
                    "left": data.left
		})
                .focusout(saveSticky)
                .resizable({
                    maxHeight: 260,
                    maxWidth: 245,
                    minHeight: 170,
                    minWidth: 240
                })
                .appendTo(document.body);
        },
        saveSticky = function saveSticky() {
            let that = $(this), sticky = (that.hasClass("sticky-status") || that.hasClass("sticky-content")) ? that.parents('div.sticky'): that,
                obj = {
                    id: sticky.attr("id"),
                    top: sticky.css("top"),
                    left: sticky.css("left")
                };
            localStorage.setItem(obj.id, JSON.stringify(obj));
        },
        markUnsaved = function markUnsaved() {
            var that = $(this), sticky = that.hasClass("sticky-content") ? that.parents("div.sticky") : that;
        };
    return {
        open   : openStickies,
        "new"  : createSticky
    };

}());
