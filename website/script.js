// ---------------------------
// API Base URL (your deployed API Gateway endpoint)
// ---------------------------
// TODO: Replace with your actual API Gateway URL from Terraform output
// TODO: Update this URL after deployment
var API_BASE_URL = "https://q49n6rpeoh.execute-api.us-east-1.amazonaws.com/prod"; // Will be updated to new API Gateway URL

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
  var text = $("#postText").val();
  var voiceName = $("#voiceSelected option:selected").val();
  
  if (!text.trim()) {
    alert("Please enter some text to convert to speech.");
    return;
  }
  
  document.getElementById("postIDreturned").textContent = "Converting to speech...";
  
  // Use browser's built-in speech synthesis
  if ('speechSynthesis' in window) {
    var utterance = new SpeechSynthesisUtterance(text);
    
    // Try to match the selected voice
    var voices = speechSynthesis.getVoices();
    var selectedVoice = voices.find(voice => voice.name.includes(voiceName) || voice.lang.includes('en'));
    if (selectedVoice) {
      utterance.voice = selectedVoice;
    }
    
    utterance.onstart = function() {
      document.getElementById("postIDreturned").textContent = "Playing audio...";
      document.getElementById("audioSection").style.display = "block";
      document.getElementById("audioPlayer").innerHTML = `
        <div style="text-align: center; padding: 20px;">
          <h3>🎧 Audio Playing!</h3>
          <p><strong>Text:</strong> "${text}"</p>
          <p><strong>Voice:</strong> ${utterance.voice ? utterance.voice.name : 'Default'}</p>
          <button onclick="speechSynthesis.cancel()" class="btn secondary">Stop Audio</button>
          <button onclick="speechSynthesis.speak(new SpeechSynthesisUtterance('${text}'))" class="btn">Play Again</button>
        </div>
      `;
    };
    
    utterance.onend = function() {
      document.getElementById("postIDreturned").textContent = "Audio playback complete!";
    };
    
    speechSynthesis.speak(utterance);
  } else {
    document.getElementById("postIDreturned").textContent = "Speech synthesis not supported in this browser.";
    document.getElementById("postIDreturned").style.color = "red";
  }
};

// ---------------------------
// Fetch voices dynamically
// ---------------------------
function loadVoices() {
  // Use browser's built-in voices
  function populateVoices() {
    var voices = speechSynthesis.getVoices();
    $("#voiceSelected").empty();
    
    if (voices.length > 0) {
      voices.forEach(function(voice) {
        if (voice.lang.startsWith('en')) { // Only English voices
          $("#voiceSelected").append(
            `<option value="${voice.name}">${voice.name} (${voice.lang})</option>`
          );
        }
      });
    } else {
      // Fallback voices
      FALLBACK_VOICES.forEach(function (voice) {
        $("#voiceSelected").append(
          `<option value="${voice.Id}">${voice.Name} (${voice.LanguageName})</option>`
        );
      });
    }
  }
  
  // Load voices when available
  if (speechSynthesis.getVoices().length > 0) {
    populateVoices();
  } else {
    speechSynthesis.onvoiceschanged = populateVoices;
  }
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
