// ---------------------------
// API Base URL (your deployed API Gateway endpoint)
// ---------------------------
var API_BASE_URL = "https://q49n6rpeoh.execute-api.us-east-1.amazonaws.com/prod";

// Fallback voices when API is not available
var FALLBACK_VOICES = [
  {Id: "Joanna", Name: "Joanna", LanguageName: "US English"},
  {Id: "Matthew", Name: "Matthew", LanguageName: "US English"},
  {Id: "Amy", Name: "Amy", LanguageName: "British English"},
  {Id: "Brian", Name: "Brian", LanguageName: "British English"}
];

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
    var selectedVoice = voices.find(voice => voice.name === voiceName);
    if (selectedVoice) {
      utterance.voice = selectedVoice;
    }
    
    // Set up audio recording
    var audioChunks = [];
    var mediaRecorder;
    var audioContext;
    var destination;
    
    utterance.onstart = function() {
      document.getElementById("postIDreturned").textContent = "Playing and recording audio...";
      document.getElementById("audioSection").style.display = "block";
      
      // Try to set up audio recording
      try {
        audioContext = new (window.AudioContext || window.webkitAudioContext)();
        destination = audioContext.createMediaStreamDestination();
        mediaRecorder = new MediaRecorder(destination.stream);
        
        audioChunks = [];
        mediaRecorder.ondataavailable = function(event) {
          audioChunks.push(event.data);
        };
        
        mediaRecorder.onstop = function() {
          var audioBlob = new Blob(audioChunks, { type: 'audio/wav' });
          var audioUrl = URL.createObjectURL(audioBlob);
          
          document.getElementById("audioPlayer").innerHTML = `
            <div style="text-align: center; padding: 20px;">
              <h3>🎧 Audio Ready!</h3>
              <p><strong>Text:</strong> "${text}"</p>
              <p><strong>Voice:</strong> ${utterance.voice ? utterance.voice.name : 'Default'}</p>
              <audio controls style="width: 100%; margin: 15px 0;">
                <source src="${audioUrl}" type="audio/wav">
              </audio>
              <br>
              <button onclick="playAgain()" class="btn">Play Again</button>
              <a href="${audioUrl}" download="voicebox-audio.wav" class="btn" style="margin-left: 10px;">⬇️ Download Audio</a>
              <button onclick="speechSynthesis.cancel()" class="btn secondary" style="margin-left: 10px;">Stop</button>
            </div>
          `;
        };
        
        mediaRecorder.start();
        
        document.getElementById("audioPlayer").innerHTML = `
          <div style="text-align: center; padding: 20px;">
            <h3>🎧 Recording Audio...</h3>
            <p><strong>Text:</strong> "${text}"</p>
            <p><strong>Voice:</strong> ${utterance.voice ? utterance.voice.name : 'Default'}</p>
            <p>🔴 Recording in progress...</p>
            <button onclick="speechSynthesis.cancel()" class="btn secondary">Stop Audio</button>
          </div>
        `;
        
      } catch (error) {
        // Fallback without recording
        document.getElementById("audioPlayer").innerHTML = `
          <div style="text-align: center; padding: 20px;">
            <h3>🎧 Audio Playing!</h3>
            <p><strong>Text:</strong> "${text}"</p>
            <p><strong>Voice:</strong> ${utterance.voice ? utterance.voice.name : 'Default'}</p>
            <p><em>Note: Download not available - browser limitation</em></p>
            <button onclick="playAgain()" class="btn">Play Again</button>
            <button onclick="speechSynthesis.cancel()" class="btn secondary" style="margin-left: 10px;">Stop Audio</button>
          </div>
        `;
      }
    };
    
    utterance.onend = function() {
      document.getElementById("postIDreturned").textContent = "Audio playback complete!";
      
      // Stop recording when speech ends
      if (mediaRecorder && mediaRecorder.state === 'recording') {
        setTimeout(function() {
          mediaRecorder.stop();
          if (audioContext) {
            audioContext.close();
          }
        }, 500); // Small delay to capture the end
      }
    };
    
    speechSynthesis.speak(utterance);
  } else {
    document.getElementById("postIDreturned").textContent = "Speech synthesis not supported in this browser.";
    document.getElementById("postIDreturned").style.color = "red";
  }
};

// ---------------------------
// Play Again function
// ---------------------------
function playAgain() {
  var text = $("#postText").val();
  var voiceName = $("#voiceSelected option:selected").val();
  var utterance = new SpeechSynthesisUtterance(text);
  
  var voices = speechSynthesis.getVoices();
  var selectedVoice = voices.find(voice => voice.name === voiceName);
  if (selectedVoice) {
    utterance.voice = selectedVoice;
  }
  
  speechSynthesis.speak(utterance);
}

// ---------------------------
// Fetch voices dynamically
// ---------------------------
function loadVoices() {
  function populateVoices() {
    var voices = speechSynthesis.getVoices();
    $("#voiceSelected").empty();
    
    if (voices.length > 0) {
      // Group voices by language
      var languageGroups = {};
      voices.forEach(function(voice) {
        var langName = voice.lang;
        if (!languageGroups[langName]) {
          languageGroups[langName] = [];
        }
        languageGroups[langName].push(voice);
      });
      
      // Add voices grouped by language
      Object.keys(languageGroups).sort().forEach(function(lang) {
        var optgroup = $('<optgroup label="' + getLanguageName(lang) + '"></optgroup>');
        languageGroups[lang].forEach(function(voice) {
          optgroup.append('<option value="' + voice.name + '">' + voice.name + '</option>');
        });
        $("#voiceSelected").append(optgroup);
      });
    } else {
      // Fallback voices
      FALLBACK_VOICES.forEach(function (voice) {
        $("#voiceSelected").append('<option value="' + voice.Id + '">' + voice.Name + ' (' + voice.LanguageName + ')</option>');
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

// Helper function to get readable language names
function getLanguageName(langCode) {
  var languages = {
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'en-AU': 'English (Australia)',
    'es-ES': 'Spanish (Spain)',
    'es-MX': 'Spanish (Mexico)',
    'fr-FR': 'French (France)',
    'de-DE': 'German (Germany)',
    'it-IT': 'Italian (Italy)',
    'pt-BR': 'Portuguese (Brazil)',
    'ja-JP': 'Japanese (Japan)',
    'ko-KR': 'Korean (Korea)',
    'zh-CN': 'Chinese (Simplified)',
    'zh-TW': 'Chinese (Traditional)',
    'ru-RU': 'Russian (Russia)',
    'ar-SA': 'Arabic (Saudi Arabia)',
    'hi-IN': 'Hindi (India)',
    'nl-NL': 'Dutch (Netherlands)',
    'sv-SE': 'Swedish (Sweden)',
    'da-DK': 'Danish (Denmark)',
    'no-NO': 'Norwegian (Norway)',
    'fi-FI': 'Finnish (Finland)'
  };
  return languages[langCode] || langCode;
}

// ---------------------------
// Test API function
// ---------------------------
function testAPI() {
  console.log('Testing browser speech synthesis...');
  
  if ('speechSynthesis' in window) {
    var voices = speechSynthesis.getVoices();
    alert('✅ Speech Synthesis Available!\n- ' + voices.length + ' voices found\n- Multi-language support enabled');
  } else {
    alert('❌ Speech synthesis not supported in this browser');
  }
}

// ---------------------------
// Load voices on page ready
// ---------------------------
$(document).ready(function () {
  loadVoices();
});