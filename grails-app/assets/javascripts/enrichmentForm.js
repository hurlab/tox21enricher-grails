

function renderCheckboxes() {

    $.get("/tox21enricher/init/getAnnoClassAsJson", function(data) {
        //alert("Data: " + data)
        var checkboxGroups = {"PubChem Compound Annotation":[], "DrugMatrix Annotation":[], "DrugBank Annotation":[], "CTD Annotation":[], "Other Annotations":[]};
        var stringMap = {"CTD Annotation":"CTD Annotation","DrugMatrix Annotation":"DrugMatrix Annotation","PubChem Compound Annotation":"PubChem Compound Annotation","DrugBank Annotation":"DrugBank Annotation"};
        //var stringMap = {"CTD Annotation":"CTD","DrugMatrix Annotation":"DrugMatrix","PubChem Compound Annotation":"PubChem","DrugBank Annotation":"DrugBank"};

        for (var annoclassid in data) {
            var record = data[annoclassid];
            var annotype = record.annotype;
            var annodesc = record.annodesc; //annotation descriptions for tooltips
            var name = "Other Annotations";
            if (stringMap.hasOwnProperty(annotype)) {
                name = stringMap[annotype];
            }
            if (record.annoclassname == "CTD_CHEMICALS_GOENRICH_BIOPROCESS") {
                checkboxGroups[name].push(["CTD_GO_BP (new) <sub>Very Slow</sub>", record.annogroovyclassname, record.annodesc, false]);
            }
            else if (record.annoclassname == "ZERO_CLASS" || 
                     //record.annoclassname == "CTD_GO_BP" || 
                     record.annoclassname == "CTD_SF" || 
                     record.annoclassname == "ENZYMES_NOT_VALIDATED" ||
                     record.annoclassname == "ENZYMES_VALIDATED" ||
                     record.annoclassname == "TARGET_GENES_NOT_VALIDATED" ||
                     record.annoclassname == "TARGET_GENES_VALIDATED" ||
                     record.annoclassname == "TRANSPORTER_NOT_VALIDATED" ||
                     record.annoclassname == "TRANSPORTER_VALIDATED" ||
                     record.annoclassname == "ATC_NOT_VALIDATED" ||
                     record.annoclassname == "ATC_VALIDATED" ||
                     record.annoclassname == "CARRIER_NOT_VALIDATED" ||
                     record.annoclassname == "CARRIER_VALIDATED" ||
                     record.annoclassname == "MESH_LEVEL_1" ||
                     record.annoclassname == "MESH_LEVEL_2" ||
                     record.annoclassname == "MESH_LEVEL_3") {
                //do nothing, we aren't using these. We can get rid of this else if after the next database update when we remove these altogether
            }
            else {
                checkboxGroups[name].push([record.annoclassname, record.annogroovyclassname, record.annodesc]);
            }
        }

        var totalContainer = $("<ul>").addClass("accordion");
        $(totalContainer).attr("data-multi-expand", true);
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

                //Tooltips for each annotation class
                $(wrapperDiv).attr("data-tooltip", "");
                $(wrapperDiv).attr("aria-haspopup", true);
                $(wrapperDiv).addClass("has-tip");
                $(wrapperDiv).attr("data-disable-hover", false);
                $(wrapperDiv).attr("tabindex", 0);
                //$(wrapperDiv).attr("data-position", "right");
                //$(wrapperDiv).attr("data-alignment", "center");
                $(wrapperDiv).attr("title", el[2]);

                $(wrapperDiv).prepend($("<label>").addClass("finger").prop("for", el[1]).html(el[0]));
                $(rowDiv).append(wrapperDiv);
                $(accordionContent).append(rowDiv);
            }
            $(accordionBox).append(accordionContent);
            $(totalContainer).append(accordionBox);
        }
        $("#checkboxes").append(totalContainer);
        $(document).foundation();
    } );


}

$(document).ready(function() { renderCheckboxes();
$(document).foundation();
});
