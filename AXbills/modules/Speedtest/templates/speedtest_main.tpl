<script src="https://cdnjs.cloudflare.com/ajax/libs/raphael/2.1.4/raphael-min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/justgage/1.2.2/justgage.min.js"></script>
<script type="text/javascript">
    var w = null;
    var ggdl, ggul, ggping;

    function runTest() {
        w = new Worker('/speedtest_api/speedtest_worker.js')
        var interval = setInterval(function () {
            w.postMessage('status')
        }, 100)
        document.getElementById('abortBtn').style.display = ''
        document.getElementById('startBtn').style.display = 'none'
        w.onmessage = function (event) {
            var data = event.data.split(';')
            var status = Number(data[0])
            var dlStatus = data[1];
            var ulStatus = data[2];
            var pingStatus = data[3];
            console.log(data[4]);
            document.getElementById('ip').textContent = '%YOUR_IP%: ' + data[4]
            var jitterStatus = data[5];
            if (status >= 4) {
                clearInterval(interval)
                document.getElementById('abortBtn').style.display = 'none'
                document.getElementById('startBtn').style.display = ''
                w = null
            }
            updateGauge(ggdl, dlStatus);
            updateGauge(ggul, ulStatus);
            updateGauge(ggping, pingStatus);
            updateGauge(ggjitter, jitterStatus);

            console.log(data);
        }
        w.postMessage('start {"time_ul": "10", "time_dl": "10", "count_ping": "50", "url_dl": "garbage.cgi", "url_ul": "empty.cgi", "url_ping": "empty.cgi", "url_getIp": "get_ip.cgi"}')
    }

    function abortTest() {
        if (w) w.postMessage('abort')
    }

    document.addEventListener('DOMContentLoaded', function (event) {
        ggdl = new JustGage({
            id: 'ggdl',
            title: 'DOWNLOAD',
            label: 'Mbit/s',
            titleFontFamily: 'Sans',
            valueFontFamily: 'Sans',
            refreshAnimationTime: 300,
            value: 0,
            min: 0,
            max: 10,
            decimals: 2,
            formatNumber: true,
            humanFriendly: false,
            levelColors: [
                '#FF0000',
                '#FF0000'
            ]
        })

        ggul = new JustGage({
            id: 'ggul',
            title: 'UPLOAD',
            label: 'Mbit/s',
            titleFontFamily: 'Sans',
            valueFontFamily: 'Sans',
            refreshAnimationTime: 300,
            value: 0,
            min: 0,
            max: 10,
            decimals: 2,
            formatNumber: true,
            humanFriendly: false,
            levelColors: [
                '#008ab7',
                '#008ab7'
            ]

        })

        ggping = new JustGage({
            id: 'ggping',
            title: 'PING',
            label: 'ms',
            titleFontFamily: 'Sans',
            valueFontFamily: 'Sans',
            refreshAnimationTime: 300,
            value: 0,
            min: 0,
            max: 100,
            decimals: 2,
            formatNumber: true,
            humanFriendly: false,
            levelColors: [
                '#17cd6a',
                '#17cd6a'
            ]
        })
        ggjitter = new JustGage({
            id: 'ggjitter',
            title: 'JITTER',
            label: 'ms',
            titleFontFamily: 'Sans',
            valueFontFamily: 'Sans',
            refreshAnimationTime: 300,
            value: 0,
            min: 0,
            max: 100,
            decimals: 2,
            formatNumber: true,
            humanFriendly: false,
            levelColors: [
                '#17cd6a',
                '#17cd6a'
            ]
        })
    })

    function updateGauge(gauge, value) {
        // Alway use next power of 2 as maximum
        var max = Math.max(Math.pow(2, Math.ceil(Math.log2(value))), gauge.config.max)
        // Refresh the gauge
        gauge.refresh(value, max)
    }
</script>


<div class="container-fluid">
    <div class="row text-center">
      <div class="col-12 col-sm-10 col-md-6 col-lg-6" id="ggdl"></div>
      <div class="col-12 col-sm-10 col-md-6 col-lg-6" id="ggul"></div>
      <div class="col-12 col-sm-10 col-md-6 col-lg-6" id="ggping"></div>
      <div class="col-12 col-sm-10 col-md-6 col-lg-6" id="ggjitter"></div>
    </div>
    <div>
      <div class="row text-center">
        <div id="ip" class="h4"></div> <!--%YOUR_IP%: <span>%IP%</span>-->
            <a href="javascript:runTest()" id="startBtn" class="btn btn-primary btn-lg" style="width:140px">%BTN_START%</a>
            <a href="javascript:abortTest()" id="abortBtn" class="btn btn-primary btn-lg" style="display:none; width:140px">%BTN_STOP%</a>
        </div>
    </div>

</div>
