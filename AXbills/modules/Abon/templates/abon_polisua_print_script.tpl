<script>
  jQuery(document).ready(function () {
    jQuery('#%ID%').on('click', function(){
      fetch('/api.cgi/abon/plugin/%SERVICE_ID%/print?CONTRACT_ID=%CONTRACT_ID%')
        .then((response) => {
          if (!response.ok) {
            throw new Error('Network response was not ok');
          }
          return response.blob();
        })
        .then((pdfBlob) => {
          const pdfUrl = URL.createObjectURL(pdfBlob);

          const anchor = document.createElement('a');
          anchor.href = pdfUrl;
          anchor.download = 'file.pdf';
          anchor.style.display = 'none';
          document.body.appendChild(anchor);
          anchor.click();

          URL.revokeObjectURL(pdfUrl);
        })
        .catch((error) => {
          console.error('Error downloading PDF:', error);
        });
    });
  });
</script>