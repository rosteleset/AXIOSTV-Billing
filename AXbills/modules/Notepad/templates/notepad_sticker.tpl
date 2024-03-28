<link rel="stylesheet" type="text/css" href="/styles/default/css/jquery-ui.min.css">

<script src="/styles/default/js/modules/notepad/sticker.js"></script>
<script>
    STICKIES.open()
</script>

<style>
    .sticky{
        width: 240px;
        height: 170px;
        z-index: 1090;
        box-shadow:3px 3px 10px rgba(0,0,0,0.45);
        -webkit-box-shadow:3px 3px 10px rgba(0,0,0,0.45);
        -moz-box-shadow:3px 3px 10px rgba(0,0,0,0.45);
        background: #FFED73;
        word-wrap: break-word;
        overflow: hidden;
    }
    .sticky-status{
        margin: auto;
    }
    .sticky-content {
        min-height:100px;
        max-width: 235px;
        padding:5px;
    }
    .sticky-header {
        padding:5px;
        background:#f3f3f3;
        border-bottom:2px solid #fefefe;
        box-shadow:0 3px 5px rgba(0,0,0,0.25);
        -webkit-box-shadow:0 3px 5px rgba(0,0,0,0.25);
        -moz-box-shadow:0 3px 5px rgba(0,0,0,0.25);
        cursor: move;
    }
    .sticky-status {
        color:#ccc;
        padding:5px;
    }
    .sticky .title{
        padding: 5px;
        font-weight: bold;
    }
    .sticky-edit {
        float:right;
        cursor: pointer;
        padding:1px 5px;
        border-radius:5px;
        -webkit-border-radius:5px;
        -moz-border-radius:5px;
    }
</style>
