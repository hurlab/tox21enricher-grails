<%--
  Created by IntelliJ IDEA.
  User: Larson
  Date: 7/28/2016
  Time: 7:17 PM
--%>

<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
    <script>
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
                    (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
                m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

        ga('create', 'UA-102767915-1', 'auto');
        ga('send', 'pageview');

    </script>

    <script src="https://use.fontawesome.com/34dd79a67d.js"></script>
    <!--<script defer src="https://use.fontawesome.com/releases/v5.0.8/js/all.js"></script>-->
<!-- jquery 2.2.4 -->
    <!-- <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.4/jquery.min.js"></script> -->
    <script
        src="https://code.jquery.com/jquery-3.5.1.min.js"
        integrity="sha256-9/aliU8dGd2tb6OSsuzixeV4y/faTqgFtohetphbbj0="
        crossorigin="anonymous">
    </script> 
    
    <!-- foundation-float.min.css: Compressed CSS with legacy Float Grid -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/foundation-sites@6.6.3/dist/css/foundation-float.min.css" integrity="sha256-4ldVyEvC86/kae2IBWw+eJrTiwNEbUUTmN0zkP4luL4=" crossorigin="anonymous">
    <!-- Compressed JavaScript -->
    <script src="https://cdn.jsdelivr.net/npm/foundation-sites@6.6.3/dist/js/foundation.min.js" integrity="sha256-pRF3zifJRA9jXGv++b06qwtSqX1byFQOLjqa2PTEb2o=" crossorigin="anonymous"></script>

    <link rel="stylesheet" href="${resource(dir: 'css', file: 'application.css')}" />
    <script type="text/javascript">

    </script>
    <g:layoutHead/>
</head>

<body>

<div class="top-bar">
    <div style="text-align: center; border: 0px">
        <a href="/tox21enricher"><h1>Tox21 Enricher</h1></a>
    </div>

    <%--
    <div class="top-bar-right">
        
        <a class="button">Sign up</a>
        <a class="button">Log in</a>
        <a class="button">About</a>
        
    </div>
    --%>
    
</div>
<div class="row">
    <g:layoutBody />
</div>

</body>
</html>
