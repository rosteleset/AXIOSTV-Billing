<script src='https://api-maps.yandex.ru/2.1/?lang=ru_RU' type='text/javascript'></script>

<div id='map' style='width: 100%; height: 600px'></div>

<script type='text/javascript'>
    ymaps.ready(init);

var myMap;

function init () {
  myMap = new ymaps.Map('map', {
    center: [%YANDEX_0%, %YANDEX_1%],
    11
  }, {
        200
    }
)

<
    !--content-- >
%PLACE_MARKS%
<!-- content end -->


    // Обработка события, возникающего при щелчке
    // левой кнопкой мыши в любой точке карты.
    // При возникновении такого события откроем балун.
    myMap.events.add('click', function (e) {
        if (!myMap.balloon.isOpen()) {
            var coords = e.get('coords');
            myMap.balloon.open(coords, {
                contentHeader:'Івент!',
                contentBody:'<p>клік по карті</p>' +
                    '<p>Коорд. ' + [
                    coords[0].toPrecision(6),
                    coords[1].toPrecision(6)
                    ].join(', ') + '</p>',
                contentFooter:'<sup>клікай ще</sup>'
                
            });
        }
        else {
            myMap.balloon.close();
        }
        
        var placemark = new ymaps.Placemark(coords, {
    balloonContent: 'HTML content <br> BR <br> BR',
    iconContent: '333'
}, {
    preset: 'twirl#yellowStretchyIcon',
     
    hideIconOnBalloonOpen: false
});
myMap.geoObjects.add(placemark);

    \$('#YANDEX_0').val(coords[0].toPrecision(6));     
         \$('#YANDEX_1').val(coords[1].toPrecision(6));     
    });

    // Обработка события, возникающего при щелчке
    // правой кнопки мыши в любой точке карты.
    // При возникновении такого события покажем всплывающую подсказку
    // в точке щелчка.
    myMap.events.add('contextmenu', function (e) {
        myMap.hint.open(e.get('coords'), 'ага канєшна');
        
        var myPlacemark = new ymaps.Placemark(e.get('coords'));
        myMap.geoObjects.add(myPlacemark);
    });
    
    // Скрываем хинт при открытии балуна.
    myMap.events.add('balloonopen', function (e) {
        myMap.hint.close();
    });
};
    
</script>

<form action=$SELF_URL class='form-inline'>
<input type=hidden name=index value=$index>
<input type=text id=YANDEX_0 name=YANDEX_0 value='%YANDEX_0%' class='form-control'>
<input type=text id=YANDEX_1 name=YANDEX_1 value='%YANDEX_1%' class='form-control'>
<input type=text name=ID value='%ID%' class='form-control'>
<input type=submit name=%ACTION% value='%ACTION_LNG%' class='btn btn-primary'>
</form>