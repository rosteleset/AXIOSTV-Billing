<div id='myCarousel' class='carousel slide' data-interval='3000' data-ride='carousel'>

  <div class='carousel-inner'>
    %ITEMS%
    <a class='carousel-control-prev' href='#myCarousel' role='button' data-slide='prev'>
      <span class='carousel-control-prev-icon' aria-hidden='true'></span>
      <span class='sr-only'>Previous</span>
    </a>
    <a class='carousel-control-next' href='#myCarousel' role='button' data-slide='next'>
      <span class='carousel-control-next-icon' aria-hidden='true'></span>
      <span class='sr-only'>Next</span>
    </a>

  </div>
</div>

<style>
	.carousel-control-next-icon,
	.carousel-control-prev-icon {
		filter: invert(1);
	}
	.carousel-item {
		background-repeat: no-repeat;
		background-size: 100%;
	}
</style>