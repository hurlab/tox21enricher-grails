

function renderCheckboxes() {

    $.get("/tox21enricher/init/getAnnoClassAsJson", function(data) {
        //alert("Data: " + data)
        var checkboxGroups = {"PubChem Compound Annotation":[], "DrugMatrix Annotation":[], "CTD Annotation":[], "Other Annotations":[]};
        var stringMap = {"CTD":"CTD Annotation", "DrugMatrix":"DrugMatrix Annotation","Compound PubChem":"PubChem Compound Annotation"};
        for (var annoClass in data) {
            var record = data[annoClass];
            var annoType = record.annoType;
            var name = "Other Annotations";
            if (stringMap.hasOwnProperty(annoType)) {
                name = stringMap[annoType];
            }
            if (record.annoClassName == "CTD_GO_BP") {
                checkboxGroups[name].push(["GO BIOP <sub>Very Slow</sub>", record.annoGroovyClassName, record.annoDesc, false]);
            }
            else if (record.annoClassName == "ZERO_CLASS") {
                //this is just here so ZERO_CLASS isn't populated as a checkbox option
            }
            else {
                checkboxGroups[name].push([record.annoClassName, record.annoGroovyClassName, record.annoDesc]);
            }
        }

        var totalContainer = $("<ul>").addClass("accordion");
        $(totalContainer).attr("data-multi-expand", false);
        $(totalContainer).attr("data-allow-all-closed", true);
        $(totalContainer).attr("data-accordion", "");
        for (var group in checkboxGroups) {
            var ckGroup = checkboxGroups[group];
            var accordionBox = $("<li>").addClass("accordion").attr("data-accordion-item", "");
            var header = $("<a>").addClass("accordion-title").text(group);
            var accordionContent = $("<div>").addClass("accordion-content")
            $(accordionContent).attr("data-tab-content", "");
            var rowDiv = $("<div>").addClass("row");
            $(accordionBox).append(header)
            for (var box in ckGroup) {
                var el = ckGroup[box];
                var wrapperDiv = $("<div>").addClass("column").addClass("small-3");
                var switchDiv = $("<div>").addClass("switch").addClass("radius").addClass("tiny");
                var checkbox = $("<input>").addClass("switch-input").prop("id", el[1]).prop("type", "checkbox").prop("name", el[1]).val("on");
                if (el.length < 4 || el[3] !== false) {
                    checkbox.prop("checked", true);
                }
                var label = $("<label>").addClass("switch-paddle").prop("for", el[1]);
                label.append($("<span>").addClass("switch-active").text("On"));
                label.append($("<span>").addClass("switch-inactive").text("Off"));
                $(switchDiv).append(checkbox);
                $(switchDiv).append(label);
                $(wrapperDiv).append(switchDiv);
                $(wrapperDiv).addClass("end");

                //$(wrapperDiv).attr("data-tooltip", "");
                //$(wrapperDiv).attr("aria-haspopup", true);
                //$(wrapperDiv).addClass("has-tip");
                //$(wrapperDiv).attr("data-disable-hover", false);
                //$(wrapperDiv).attr("tabindex", 1);
                //$(wrapperDiv).attr("title", el[2]);

                $(wrapperDiv).prepend($("<label>").addClass("finger").prop("for", el[1]).html(el[0]));
                $(rowDiv).append(wrapperDiv);
                $(accordionContent).append(rowDiv);

                //var tooltip = '<a href="#" data-tooltip aria-haspopup="true" class="has-tip" data-disable-hover="false" tabindex="1"><span class="fas fa-question-circle"></span></a>';
                //$(wrapperDiv).append($("<span>").addClass("fas fa-question-circle"))
                //$(wrapperDiv).append(tooltip).attr("title", el[2]);
            }
            $(accordionBox).append(accordionContent);
            $(totalContainer).append(accordionBox);
        }
        $("#checkboxes").append(totalContainer);
        $(document).foundation();
    } );


}

$(document).ready(function() { renderCheckboxes();
    //$("#thresholdSelect").hide();
    //$("#substructureRadio").click(function(){
    //    $("#thresholdSelect").hide();
        //alert("Test");
    //});
    //$("#similarityRadio").click(function(){
    //    $("#thresholdSelect").show();
        //alert("Test again");
    //}); 
    //$("#thresholdSelectValueManual").hide();
    //$("#thresholdSelectValue").show();
    
    $(document).foundation();
});
