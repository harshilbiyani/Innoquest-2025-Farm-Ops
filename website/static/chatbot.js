(function () {
  const API_URL = "/chat";
  // Select already existing elements by their IDs or classes
  const chatbot = document.getElementById("chatbot");
  const toggleBtn = document.getElementById("chatbotToggle");
  const minimizeButton = chatbot.querySelector(".minimize-btn");
  const messagesContainer = document.getElementById("chatMessages");
  const inputField = document.getElementById("messageInput");
  const sendButton = chatbot.querySelector(".send-button");

  function formatTime() {
    const now = new Date();
    return now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  }

  function appendBubble(text, who = "bot") {
    const container = document.createElement("div");
    container.className = "message " + (who === "you" ? "user" : "bot");
    container.innerHTML = `
      <div>${text}</div>
      <div class="chat-time">${formatTime()}</div>
    `;
    messagesContainer.appendChild(container);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }

  async function sendMessage() {
    const message = inputField.value.trim();
    if (!message) return;
    appendBubble(message, "you");
    inputField.value = "";

    // Show typing indicator
    const typing = document.createElement("div");
    typing.className = "message bot typing-indicator";
    typing.innerHTML = `
      AgriBot is typing... <div class="typing-dots"><span></span><span></span><span></span></div>
    `;
    messagesContainer.appendChild(typing);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;

    try {
      const res = await fetch(API_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message }),
      });
      const data = await res.json();
      typing.remove();
      appendBubble(data.answer || data.error || "❌ Error", "bot");
    } catch {
      typing.remove();
      appendBubble("❌ Server error", "bot");
    }
  }

  // Minimize/maximize functions
  function toggleChatbot() {
    if (chatbot.style.display === "none" || chatbot.style.display === "") {
      chatbot.style.display = "flex";
      toggleBtn.style.display = "none";
      chatbot.classList.add("slide-up");
      inputField.focus();
    } else {
      chatbot.style.display = "none";
      toggleBtn.style.display = "flex";
    }
  }

  // Event listeners
  sendButton.onclick = sendMessage;
  inputField.addEventListener("keypress", (e) => {
    if (e.key === "Enter") sendMessage();
  });
  minimizeButton.onclick = toggleChatbot;
  toggleBtn.onclick = toggleChatbot;

  // Quick suggestion buttons
  document.querySelectorAll(".suggestion-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      inputField.value = btn.textContent;
      sendMessage();
    });
  });

  // Show the chatbot initially minimized
  chatbot.style.display = "none";
  toggleBtn.style.display = "flex";
})();
