<%--
  Created by IntelliJ IDEA.
  User: Larson
  Date: 7/19/2016
  Time: 6:30 PM
--%>
<!DOCTYPE html>
<%@ page import="tox21_test.ResultSetModel" contentType="text/html;charset=UTF-8" %>
<html>
    <head>
        <meta name="layout" content="main" />

        <style>
        .loader {
            border: 16px solid #f3f3f3;
            border-radius: 50%;
            border-top: 16px solid #3498db;
            width: 120px; 
            height: 120px;
            -webkit-animation: spin 2s linear infinite;
            animation: spin 2s linear infinite;
            align-content: center;
        }

        @-webkit-keyframes spin {
            0% { -webkit-transform: rotate(0deg); }
            100% { -webkit-transform: rotate(360deg); }
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .column.small-centered {
            margin-left: auto;
            margin-right: auto;
            float: none !important;
        }
        </style>

        <script>
            setInterval(function(){
                self.location = "http://localhost:8080/tox21enricher/analysis/success?resultSet=${success}&nodeCutoff=${nodeCutoff}";
                //change depending on environment
                //self.location = "http://134.129.166.26:8080/tox21enricher/analysis/success?resultSet=${success}&nodeCutoff=${nodeCutoff}";
                return false;
            }, 1000);
        </script>

        <title>Waiting...</title>
    </head>

    <body>
        <br />
        <h3>Enrichment in Progress...</h3>

        <p>You will be directed to the results page shortly. Please do not use your browser's back button.</p>
        <br />

        <div id="waittable" class="table-scroll"> 
            <table class="hover">
                <thead>
                    <tr>
                    <th width="150">Transaction ID</th>
                    <th width="150">Queue Position</th>
                    <th width="150">Status</th>
                    <th width="150">Enrichment Analysis Type</th>
                    <th width="150">Items Submitted</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                    <td>${tid}</td>
                    <td>${pos}</td>
                    <td>
                        <g:if test="${pos >= 5}">
                            Waiting
                        </g:if>
                        <g:elseif test="${pos < 5 && pos >= 0 && success == "waiting..."}">
                            Running
                        </g:elseif>
                        <g:else>
                            Complete
                        </g:else>
                    </td>
                    <td>${type}</td>
                    <td>${items}</td>
                    </tr>
                </tbody>
            </table>
        </div>
        <br />
    
    <script type="text/javascript">
        $(document).foundation();
    </script>
    </body>
</html>
