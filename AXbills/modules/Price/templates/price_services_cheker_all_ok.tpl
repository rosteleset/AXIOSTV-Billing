<script>
    // function calc(e) {
    //     var id = e.getAttribute("id");
    //     var price = e.getAttribute("data-price");
    //     var sum = 0;
    //
    //     if (document.getElementById(id).checked) {
    //         TotalSum += +price;
    //     }
    //     else if (TotalSum) {
    //         TotalSum -= +price;
    //     }
    //
    //     sum = TotalSum + Sum;
    //
    //     document.getElementById('total_sum').innerHTML = sum + " <span class='fa fa-usd'></span>";
    // }
</script>

<div class="row table table-bordered">
    <div class="col-xs-6"><h4><strong>%NAME%</strong></h4></div>
    <div class="col-xs-3"><h4 class="price" id="price"><strong>%PRICE%</strong></h4></div>
    <div class="col-xs-3"><input type='checkbox' %CHECK% name='%ID%' data-price="%PRICE%" id="%ID%"></div>
    <div class="col-xs-7">%COMMENTS%</div>
</div>

