<div class='col-lg-12 grid-margin stretch-card'>
  <div class='card card-weather'>
    <div class='card-header pb-2'>
      <div>
        %CITY_SELECT%
      </div>
      <div>
        <h3><a href='%WEATHER_LINK%' target=blank>%DATA% </a></h3>
      </div>
      <div class='d-flex flex-row'>
        <img src='https://openweathermap.org/img/wn/%ICON%@2x.png'
             alt='%ICON%'>
        <div>
          <h1 class='mt-2'>
            %DEG%<span class='symbol'>&deg;</span>C
          </h1>
          <p class='text-gray'>
            <span>%DESC%&deg;C</span>
          </p>
        </div>
        <div>
          <h5 class='text-danger'>
            <span>%TODAY_WARNINGS%</span>
          </h5>
        </div>
      </div>
    </div>
    <div class='card-footer p-0'>
      <div class='d-flex weakly-weather'></div>
    </div>
  </div>
</div>

<script>

  jQuery(document).ready(function () {
    //find Select
    var typeSelect = jQuery('#COORDINATES_SEL');

    typeSelect.on('change', function () {
    var selected = typeSelect.val();

     let arr = selected.split(':');
     let latitude = arr[0];
     let longitude = arr[1];

     document.cookie = "latitude=" + latitude;
     document.cookie = "longitude=" + longitude;
     location.reload();

    });
  });

</script>

<script>
  try {
    var arr = JSON.parse('%JSON_LIST%');
  } catch (err) {
    console.log('JSON parse error');
    console.log(err);
  }

  arr.map((item) => {
    let element = `<div class='weakly-weather-item'>
            <h5 class='mb-0'>
              ` + item.TIME + `
            </h5>
            <img src='https://openweathermap.org/img/wn/` + item.ICON + `.png'>
            <h5 class='mb-0'>
              ` + item.TEMP_MAX + `&deg; <span class='text-gray'>` + item.TEMP_MIN + `</span>&deg;` + `
            </h5>
            <p class='text-gray'>
              <span>` + item.DESC + `</span>
            </p>
          </div>`;

    jQuery('.weakly-weather').append(element);
  });
</script>

<style>
  .card-weather .card-header:first-child {
    background: #e4f2fb;
  }

  .text-gray {
    color: #969696;
  }

  .card-weather .weakly-weather .weakly-weather-item {
    flex: 0 0 25%;
    border-right: 2px solid #f2f2f2;
    background: white;
    padding-top: 10px;
    text-align: center;
  }
</style>
