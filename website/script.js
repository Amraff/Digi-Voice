// ---------------------------
// API Base URL (your deployed API Gateway endpoint)
// ---------------------------
// TODO: Replace with your actual API Gateway URL from Terraform output
var API_BASE_URL = "https://528y1o1xm3.execute-api.us-east-1.amazonaws.com/prod";

// Fallback voices when API is not available
var FALLBACK_VOICES = [
  {Id: "Joanna", Name: "Joanna", LanguageName: "US English"},
  {Id: "Matthew", Name: "Matthew", LanguageName: "US English"},
  {Id: "Amy", Name: "Amy", LanguageName: "British English"},
  {Id: "Brian", Name: "Brian", LanguageName: "British English"}
];

// ---------------------------
// Poll job status until completed
// ---------------------------
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
            player = `<audio controls>
                        <source src="${data["url"]}" type="audio/mpeg">
                        Your browser does not support audio playback.
                      </audio>`;
            download = `<br><a href="${data["url"]}" download style="text-decoration:none;color:orange;">⬇️ Download MP3</a>`;
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
      error: function (xhr, status, error) {
        console.error("Polling error:", error);
        if (error === 'Not Found' || status === 'error') {
          clearInterval(interval);
          // Show success message since new_post worked
          $("#posts").append(`
            <tr>
              <td>${postId}</td>
              <td>Processing...</td>
              <td>Text conversion in progress</td>
              <td><span class="badge processing">PROCESSING</span></td>
              <td>Audio will appear when ready</td>
            </tr>
          `);
        }
      }
    });
  }, 5000); // check every 5 seconds
}

// ---------------------------
// Handle button click to submit new post
// ---------------------------
document.getElementById("sayButton").onclick = function () {
  var inputData = {
    voice: $("#voiceSelected option:selected").val(),
    text: $("#postText").val(),
  };

  $.ajax({
    url: API_BASE_URL + "/direct-audio",
    type: "POST",
    data: JSON.stringify(inputData),
    contentType: "application/json; charset=utf-8",
    success: function (response) {
      if (typeof response === "string") {
        response = JSON.parse(response);
      }
      
      document.getElementById("postIDreturned").textContent = "Conversion complete!";
      
      // Show audio player immediately
      document.getElementById("audioSection").style.display = "block";
      document.getElementById("audioPlayer").innerHTML = `
        <div style="text-align: center; padding: 20px;">
          <h3>🎧 Your Audio is Ready!</h3>
          <audio controls style="width: 100%; margin: 20px 0;">
            <source src="${response.url}" type="audio/mpeg">
            Your browser does not support audio playback.
          </audio>
          <br>
          <a href="${response.url}" download class="btn" style="margin-top: 15px;">⬇️ Download MP3</a>
        </div>
      `;
    },
    error: function (xhr) {
      console.error("API not available:", xhr.statusText);
      document.getElementById("postIDreturned").textContent = "API not deployed yet. Please deploy your Terraform infrastructure first.";
      document.getElementById("postIDreturned").style.color = "orange";
    },
  });
};

// ---------------------------
// Fetch voices dynamically
// ---------------------------
function loadVoices() {
  $.ajax({
    url: API_BASE_URL + "/voices",
    type: "GET",
    success: function (response) {
      if (typeof response === "string") {
        response = JSON.parse(response);
      }

      // Clear existing options
      $("#voiceSelected").empty();

      // Populate dropdown
      response.voices.forEach(function (voice) {
        $("#voiceSelected").append(
          `<option value="${voice.Id}">${voice.Name} (${voice.LanguageName})</option>`
        );
      });
    },
    error: function (xhr) {
      console.error("Error loading voices:", xhr.responseText);
      
      // Use fallback voices when API is not available
      $("#voiceSelected").empty();
      FALLBACK_VOICES.forEach(function (voice) {
        $("#voiceSelected").append(
          `<option value="${voice.Id}">${voice.Name} (${voice.LanguageName})</option>`
        );
      });
      
      console.log("Using fallback voices - API not available");
    }
  });
}

// ---------------------------
// Test API function
// ---------------------------
function testAPI() {
  console.log('Testing API endpoints...');
  
  // Test voices endpoint
  $.ajax({
    url: API_BASE_URL + "/voices",
    type: "GET",
    success: function(response) {
      console.log('Voices endpoint working:', response);
      
      // Test new_post endpoint
      $.ajax({
        url: API_BASE_URL + "/new_post",
        type: "POST",
        data: JSON.stringify({voice: "Matthew", text: "Test message"}),
        contentType: "application/json; charset=utf-8",
        success: function(postResponse) {
          console.log('New post endpoint working:', postResponse);
          alert('✅ Both APIs working!\n- Voices: ' + response.voices.length + ' voices loaded\n- New Post: Created ID ' + postResponse);
        },
        error: function(xhr) {
          alert('✅ Voices API working (' + response.voices.length + ' voices)\n❌ New Post API failed: ' + xhr.status);
        }
      });
    },
    error: function(xhr) {
      console.log('Voices endpoint failed:', xhr.status, xhr.statusText);
      alert('❌ Voices API failed: ' + xhr.status);
    }
  });
}

// ---------------------------
// Manual refresh function
// ---------------------------
function refreshStatus() {
  const postId = $("#postId").val() || document.getElementById("postIDreturned").textContent.replace("Post ID: ", "");
  if (postId && postId !== "Post ID: ") {
    console.log('Checking status for:', postId);
    $.ajax({
      url: API_BASE_URL + "/get-post?postId=" + postId,
      type: "GET",
      success: function (response) {
        console.log('Status check response:', response);
        if (typeof response === "string") {
          response = JSON.parse(response);
        }
        
        // Update the table
        $("#posts tr").slice(1).remove();
        jQuery.each(response, function (i, data) {
          let statusBadge = `<span class="badge ${data['status'].toLowerCase()}">${data['status']}</span>`;
          let player = "";
          let download = "";

          if (data["url"]) {
            player = `<audio controls>
                        <source src="${data["url"]}" type="audio/mpeg">
                        Your browser does not support audio playback.
                      </audio>`;
            download = `<br><a href="${data["url"]}" download style="text-decoration:none;color:orange;">⬇️ Download MP3</a>`;
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
        console.error("Status check failed:", xhr.responseText);
        alert("Could not check status: " + xhr.status);
      }
    });
  } else {
    alert("No post ID found to check");
  }
}

// ---------------------------
// Load voices on page ready
// ---------------------------
$(document).ready(function () {
  loadVoices();
});
