var API_BASE_URL = "https://qbya30xwka.execute-api.us-east-1.amazonaws.com/prod";

function pollStatus(postId) {
  let interval = setInterval(function () {
    $.ajax({
      url: API_BASE_URL + "/get-post?postId=" + postId,
      type: "GET",
      success: function (response) {
        if (typeof response === "string") {
          response = JSON.parse(response);
        }

        // Clear old rows
        $("#posts tr").slice(1).remove();

        jQuery.each(response, function (i, data) {
          let statusBadge = `<span class="badge ${data['status'].toLowerCase()}">${data['status']}</span>`;
          let player = "";
          let download = "";

          if (data["url"]) {
            player = "<audio controls><source src='" + data["url"] + "' type='audio/mpeg'></audio>";
            download = "<br><a href='" + data["url"] + "' download style='text-decoration:none;color:orange;'>⬇️ Download MP3</a>";
            clearInterval(interval); // ✅ Stop polling once done
          }

          $("#posts").append(`
            <tr>
              <td>${data['id']}</td>
              <td>${data['voice']}</td>
              <td>${data['text']}</td>
              <td>${statusBadge}</td>
              <td>${player}${download}</td>
            </tr>
          `);
        });
      },
      error: function (xhr) {
        console.error("Polling error:", xhr.responseText);
        clearInterval(interval);
      }
    });
  }, 5000); // check every 5 seconds
}

document.getElementById("sayButton").onclick = function () {
  var inputData = {
    voice: $("#voiceSelected option:selected").val(),
    text: $("#postText").val(),
  };

  $.ajax({
    url: API_BASE_URL + "/new_post",
    type: "POST",
    data: JSON.stringify(inputData),
    contentType: "application/json; charset=utf-8",
    success: function (response) {
      document.getElementById("postIDreturned").textContent = "Post ID: " + response;
      $("#postId").val(response);

      // Start polling for job status
      pollStatus(response);
    },
    error: function (xhr) {
      alert("Error: " + xhr.responseText);
    },
  });
};
