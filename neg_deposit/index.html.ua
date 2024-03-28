<html>
<head>
    <title>Доступ заборонено</title>
  <meta name='viewport' content='width=device-width, initial-scale=1'>
  <meta http-equiv='X-UA-Compatible' content='IE=edge'>

  <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
  <meta HTTP-EQUIV='Cache-Control' content='no-cache,no-cache,no-store,must-revalidate,private, max-age=5'/>
  <meta HTTP-EQUIV='Expires' CONTENT='-1'/>
  <meta HTTP-EQUIV='Pragma' CONTENT='no-cache'/>
  <meta HTTP-EQUIV='Content-Type' CONTENT='text/html; charset=utf-8'/>
  <meta HTTP-EQUIV='Content-Language' content='ua'/>
    <style>
        body {
            background-color: #232020;
            text-align: center;
        }

        #page-wrapper {
            height: 100%;
            width: 100%;
            position: relative;

            margin-top: 2em;

            font-family: Tahoma, serif;
        }

        #alert-wrapper {
            display: block;
            position: relative;

            margin-left: auto;
            margin-right: auto;

            max-width: 500px;
            font-size: 20px;
        }

        .alert-header {
            font-size: 32px;
            color: #ffffff;
            text-align: center;
        }

        .text-orange {
            color: #FF8000
        }

        .alert-text {
            color: #9b9a9a;
            text-align: center;
            margin-top: 35px;
        }

        .alert-btn{
            display: inline-block;
            padding: 6px 12px;
            margin-bottom: 0;
            font-size: 14px;
            font-weight: 400;
            line-height: 1.42857143;
            text-align: center;
            white-space: nowrap;
            vertical-align: middle;

            cursor: pointer;

            border-radius: 4px;
            color: #333;
            background-color: #fff;
            border-color: #ccc;
            text-decoration: none;
        }


    </style>
</head>
<body>
<script>
    function ReloadPage() {
        location.reload(true);
    }
</script>
<div id='page-wrapper'>

    <div id='alert-wrapper'>

        <p class='alert-header'> На Вашому рахунку <span class='text-orange'>0</span> грн </p>

        <p class='alert-text'> Для подальшого користування послугою Інтернет в повному обсязі,<br>
            будь ласка,
            <a href='CHANGE_ME/index.cgi'>поповніть Ваш рахунок</a>
        </p>

        <p class='alert-text'>Для роботи у режимі мінімальної пропускної
            спроможності активуйте обмежений режим</p>
        <a href='https://CHANGE_ME:9443/skip_warning.cgi?redirect=' class='alert-btn'>Активувати обмежений режим роботи</a>
        <br>
        <br>
        <button onclick="ReloadPage()">Продовжити</button>
    </div>

</div>

</body>
</html>
