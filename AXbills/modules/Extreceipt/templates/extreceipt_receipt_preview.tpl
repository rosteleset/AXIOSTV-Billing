<div class='text-center' id='receipt_preview'>
  <div>
    <h1>%ERROR%</h1>
    <img src='%CHECK%'
         style='width: 100%;'
         alt='Check'/>
  </div>
  <div class='d-print-none m-2'>
    <a href='javascript:window.print();'><span class='fas fa-print fa-2x mr-2' title='_{PRINT}_'></span></a>
    <a href='javascript:window.close();'><span class='fas fa-times fa-2x text-danger' title='_{CLOSE}_'></span></a>
  </div>
</div>

<style>
  .wrapper > :not(#receipt_preview) {
    display: none;
  }

  @media print{
    @page {
      size: 7in 20in;
    }
  }
</style>

<script>
  window.print();
</script>