<style type='text/css'>
  .portal .carousel-caption p {
    height: 52px;
  }

  .portal .carousel-caption h4 {
    // Place your style here
  }

  .portal .carousel-item {
    height: 256px !important;
  }

  .portal.carousel {
    width: 100%;
  }

  .important {
    background: #f78345;
  }

  .portal.slide {
    background: rgb(168, 168, 167);
    margin-bottom: 1rem;
    border-radius: .25rem;
  }

  .portal .carousel-item img {
    filter: brightness(40%);
    border-radius: .25rem;
    height: 256px !important;
    object-fit: cover;
  }

</style>


<div id='myPortalCarousel' class='carousel portal slide' data-interval='3000' data-ride='carousel'>
  <ol class='carousel-indicators'>
    %INDICATORS%
  </ol>
  <div class='carousel-inner'>
    %CONTENT%
  </div>

  <a class='carousel-control-prev' href='#myPortalCarousel' data-slide='prev'>
    <span class='carousel-control-prev-icon' aria-hidden='true'></span>
    <span class='sr-only'>Previous</span>
  </a>
  <a class='carousel-control-next' href='#myPortalCarousel' data-slide='next'>
    <span class='carousel-control-next-icon' aria-hidden='true'></span>
    <span class='sr-only'>Next</span>
  </a>
</div>