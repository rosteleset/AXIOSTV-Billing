<style>

    @-webkit-keyframes bg-scrolling-reverse {
        100% {
            background-position: 350px 350px;
        }
    }

    @-moz-keyframes bg-scrolling-reverse {
        100% {
            background-position: 350px 350px;
        }
    }

    @-o-keyframes bg-scrolling-reverse {
        100% {
            background-position: 350px 350px;
        }
    }

    @keyframes bg-scrolling-reverse {
        100% {
            background-position: 350px 350px;
        }
    }

    @-webkit-keyframes bg-scrolling {
        50% {
            background-position: 350px 350px;
        }
    }

    @-moz-keyframes bg-scrolling {
        50% {
            background-position: 350px 350px;
        }
    }

    @-o-keyframes bg-scrolling {
        50% {
            background-position: 350px 350px;
        }
    }

    @keyframes bg-scrolling {
        50% {
            background-position: 350px 350px;
        }
    }

    .animated-bg {
        background: url("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAIAAACRXR/mAAAACXBIWXMAAAsTAAALEwEAmpwYAAAAIGNIUk0AAHolAACAgwAA+f8AAIDpAAB1MAAA6mAAADqYAAAXb5JfxUYAAABnSURBVHja7M5RDYAwDEXRDgmvEocnlrQS2SwUFST9uEfBGWs9c97nbGtDcquqiKhOImLs/UpuzVzWEi1atGjRokWLFi1atGjRokWLFi1atGjRokWLFi1af7Ukz8xWp8z8AAAA//8DAJ4LoEAAlL1nAAAAAElFTkSuQmCC") repeat 0 0;

        -webkit-animation: bg-scrolling-reverse 15s infinite;
        -moz-animation: bg-scrolling-reverse 15s infinite;
        -o-animation: bg-scrolling-reverse 15s infinite;
        animation: bg-scrolling-reverse 15s infinite;
        -webkit-animation-timing-function: linear;
        -moz-animation-timing-function: linear;
        -o-animation-timing-function: linear;
        animation-timing-function: linear;
    }
</style>

<div class="card card-primary collapsed-card">
    <div class="card-header">
        <h3 class="card-title">_{DISCOUNT_CARD}_</h3>
        <div class="card-tools">
            <button type="button" class="btn btn-tool" data-card-widget="collapse">
                <i class="fa fa-plus"></i>
            </button>
        </div>
    </div>
    <div class="card-body" style="display: none;">
            <div class='panel panel-danger animated-bg text-center'>
                <div class='card-body'>
                    <div class='row'>
                        <div align="center" class="col-md-12 col-sm-12">
                            <h1>%FIO%</h1>
							</br>
                            <div align="center">%CODE_SCAN%</div>
							</br>
							<h4>ID дисконтной карты: %UID%</h4>
							</br>
							<h1>%INFO_BOX%</h1>
                        </div>
                    </div>
                </div>
            </div>
    </div>
</div>

<script>
function copyToBuffer(value){

    try {
    var $textarea = $('<textarea></textarea>').text(value);
  
    $('div.wrapper').after($textarea);
  
    $textarea.select();
      document.execCommand('copy');
      document.getSelection().removeAllRanges();
    }
    catch (err) {
      alert('Oops, unable to copy');
    }
    finally {
      $textarea.remove();
    }
  }

</script>
