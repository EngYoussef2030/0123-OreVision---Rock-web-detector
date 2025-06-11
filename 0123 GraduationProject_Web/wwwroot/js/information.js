document.getElementById("info").addEventListener("click", function () {
    const name = this.getAttribute("data-name");

    fetch(`/Rock/DisplayMoreInformation?name=${encodeURIComponent(name)}`)
        .then(response => {
            if (!response.ok) {
                throw new Error("Data not found.");
            }
            return response.json();
        })
        .then(data => {
            document.getElementById("Name").textContent = data.name;
            document.getElementById("Formula").textContent = data.formula;
            document.getElementById("Color").textContent = data.color;
            document.getElementById("Hardness").textContent = data.hardness;
            document.getElementById("Density").textContent = data.density;

            document.getElementById("Content").style.display = "block";
/*            document.getElementById("entable").style.display = "block";*/
            document.getElementById("translate").style.display = "block";
            document.getElementById("ContentAr").style.display = "none";
            document.getElementById("infoo").style.display = "table";
        })
        .catch(error => {
            alert(error.message);
        });
});


function ttranslate() {
    const AR = document.getElementById("ContentAr");
    const EN = document.getElementById("Content");
    const IsArVisible = AR.style.display == "block"; 
    EN.style.display = IsArVisible ? "block" : "none";
    AR.style.display = IsArVisible ? "none" : "block";
    // هل اللعة العربية ظاهرة ولا لأ
    //لو ظاهرة كده انا هترجم من العربية للانجليزيه
    //فالأول هخفي ظهر العربية و اظهر الانجليزيه

    //const tableAR = document.getElementById("artable");
    //const tableEN = document.getElementById("entable");
    //const artablevisability = tableAR.style.display == "block";
    //tableAR.style.display = artablevisability ? "block" : "none";
    //tableEN.style.display = artablevisability ? "none" : "block";
}