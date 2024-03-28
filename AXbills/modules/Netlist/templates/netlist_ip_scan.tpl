<div class='card card-primary card-outline box-form'>
    <div class='card-header with-border'><h4 class='card-title'>IP _{SCAN}_</h4></div>
    <div class='card-body'>

        <form name='ip_scan' id='form_ip_scan' method='post' class='form form-horizontal'>
            <input type='hidden' name='index' value='$index'/>
            <input type='hidden' name='DO_SCAN' value='1'/>

            <div class='form-group'>
                <label class='control-label col-md-3 ip-input required' for='IP_id'>IP</label>

                <div class='col-md-9'>
                    <input type='text' class='form-control' required name='IP' value='$FORM{IP}' id='IP_id'/>
                </div>
            </div>

            <div class='form-group'>
                <label class='control-label col-md-3 required' for='MASK_BITS_id'>_{PREFIX}_</label>

                <div class='col-md-9'>
                    <input type='text' class='form-control' required name='MASK_BITS' value='$FORM{MASK_BITS}' id='MASK_BITS_id'/>
                </div>
            </div>
        </form>

    </div>
    <div class='card-footer'>
        <input type='submit' form='form_ip_scan' class='btn btn-primary' name='action' value='_{DO_SCAN}_'>
    </div>
</div>

<script>
    //fa fa-sort-up IP address table
    function ip_address_pre(a) {
        var i, item;
        var m = a.split("."),
                n = a.split(":"),
                x = "",
                xa = "";

        if (m.length == 4) {
            // IPV4
            for (i = 0; i < m.length; i++) {
                item = m[i];

                if (item.length == 1) {
                    x += "00" + item;
                }
                else if (item.length == 2) {
                    x += "0" + item;
                }
                else {
                    x += item;
                }
            }
        }
        else if (n.length > 0) {
            // IPV6
            var count = 0;
            for (i = 0; i < n.length; i++) {
                item = n[i];

                if (i > 0) {
                    xa += ":";
                }

                if (item.length === 0) {
                    count += 0;
                }
                else if (item.length == 1) {
                    xa += "000" + item;
                    count += 4;
                }
                else if (item.length == 2) {
                    xa += "00" + item;
                    count += 4;
                }
                else if (item.length == 3) {
                    xa += "0" + item;
                    count += 4;
                }
                else {
                    xa += item;
                    count += 4;
                }
            }

            // Padding the ::
            n = xa.split(":");
            var paddDone = 0;

            for (i = 0; i < n.length; i++) {
                item = n[i];

                if (item.length === 0 && paddDone === 0) {
                    for (var padding = 0; padding < (32 - count); padding++) {
                        x += "0";
                        paddDone = 1;
                    }
                }
                else {
                    x += item;
                }
            }
        }

        return x;
    }

    function ip_ascending(a, b) {
        console.log(a + ", " + b);
        return ((a < b) ? -1 : ((a > b) ? 1 : 0));
    }

    function ip_descending(a, b) {
        return ((a < b) ? 1 : ((a > b) ? -1 : 0));
    }

    jQuery(function () {
        //cache DOM
        var table = jQuery('#NETLIST_IP_SCAN_LIST_').find('tbody');
        var trs = table.find('tr');

        var table_image = {};
        var table_ip_keys = [];

        jQuery.each(trs, function (i, tr) {
//            console.log(jQuery(e).find('td'));
            var tds = jQuery(tr).find('td');
            var td = jQuery(tds[1]);

            var ip_pre = ip_address_pre(td.text());
            td.attr('ip-pre', ip_pre);
            table_ip_keys.push(ip_pre);
            table_image[ip_pre] = jQuery(tr);
        });

        table_ip_keys.sort(ip_ascending);

        table.empty();
        jQuery.each(table_ip_keys, function(i , e){
            table.append(table_image[e]);
        });
    });
</script>
