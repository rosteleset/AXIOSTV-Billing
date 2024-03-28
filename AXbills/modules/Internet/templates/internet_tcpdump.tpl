<!DOCTYPE html>
<html>
  <head>
    <title>Tcpdump</title>
    <script>
      var eventSource = new EventSource('%URL%');
      eventSource.onopen = function(e) {
        console.log("Open connection");
      };

      eventSource.onerror = function(e) {
        if (this.readyState == EventSource.CONNECTING) {
          console.log("Connection error, reconnecting");
        } else {
          console.log("Error: " + this.readyState);
        }
      };

      eventSource.onmessage = function(e) {
        if ((window.innerHeight + window.pageYOffset) >= document.body.offsetHeight) {
          document.getElementById('tcpdump_pre').append(e.data + "\n");
          window.scrollTo(0,document.body.scrollHeight);
        }
        else {
          document.getElementById('tcpdump_pre').append(e.data + "\n");
        }
      };

      eventSource.addEventListener("close", function(event) {
        console.log("Close connection");
        eventSource.close();
      });
    </script>
  </head>
  <body>
    <pre id='tcpdump_pre'></pre>
  </body>
</html>
