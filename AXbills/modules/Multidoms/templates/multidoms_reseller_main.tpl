<!-- Header Navbar -->
<nav class='navbar navbar-static-top' role='navigation'>
    <!-- Sidebar toggle button-->
    <a href='#' class='sidebar-toggle' data-toggle='offcanvas' role='button'>
        <span class='sr-only'>Toggle navigation</span>
    </a>
    <a href='$SELF_URL' class='header-btn-link' role='button'>
        <span class='fa fa-home'></span>
    </a>
</nav>
</header>


<!-- menu -->
<aside id='main-sidebar' class='main-sidebar sidebar'>
    %MENU%
</aside>

<div class='content-wrapper'>
    <section class='content' id='main-content'>
        %BODY%
    </section>

</div>

</div>

<!-- client_start End -->

<script>
    if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {
        jQuery('#language_mobile').on('change', selectLanguage);
    } else {
        jQuery('#language').on('change', selectLanguage);
    }
</script>
%PUSH_SCRIPT%
</body>