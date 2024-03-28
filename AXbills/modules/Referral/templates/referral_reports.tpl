<div>
  %REFERRAL_TREE%
</div>

<script>
  if (window.location.search.includes('REFERRAL_DEL')) {
  var url = new URL(window.location.href);
  url.searchParams.delete('REFERRAL_DEL');
  window.location.href = url;
  }
</script>