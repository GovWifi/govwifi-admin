document.addEventListener("DOMContentLoaded", function () {
  const config = {
    timeoutWarningTime: 60 * 1000, // Show warning at 60 seconds
    sessionTimeout: 90 * 1000, // Logout at 90 seconds
    signOutUrl: "/users/sign_out",
    signInUrl: "/users/sign_in"
  };

  let timeoutId;
  let logoutId;
  let modal;
  let lastFocusedElement;

  function createTimeoutModal() {
    modal = document.createElement("div");
    modal.id = "timeoutModal";
    modal.setAttribute("role", "dialog");
    modal.setAttribute("aria-labelledby", "session-heading");
    modal.setAttribute("aria-describedby", "session-description");
    modal.setAttribute("aria-modal", "true");
    modal.setAttribute("aria-live", "assertive");
    modal.style.cssText = `
      display: none; position: fixed; top: 0; left: 0;
      width: 100%; height: 100%; background-color: rgba(0, 0, 0, 0.5);
      z-index: 1000;
    `;

    const modalContent = document.createElement("div");
    modalContent.classList.add("govuk-panel", "govuk-panel--confirmation");
    modalContent.style.cssText = `
      position: absolute; top: 50%; left: 50%;
      transform: translate(-50%, -50%); padding: 20px;
      text-align: center; background-color: #fff; outline: none;
    `;

    const heading = document.createElement("h1");
    heading.classList.add("govuk-heading-l");
    heading.id = "session-heading";
    heading.textContent = "Your session is about to expire";

    const message = document.createElement("p");
    message.classList.add("govuk-body");
    message.id = "session-description";
    message.textContent = "For your security, please advise if you would like to continue your session?";

    const buttonWrapper = document.createElement("div");
    buttonWrapper.classList.add("govuk-button-group", "govuk-!-text-align-center");
    buttonWrapper.style.cssText = "padding: 20px; text-align: center;";

    const continueButton = document.createElement("button");
    continueButton.classList.add("govuk-button", "govuk-!-margin-right-2");
    continueButton.textContent = "Stay signed in";
    continueButton.setAttribute("aria-label", "Stay signed in and continue session");
    continueButton.addEventListener("click", resetSessionTimeout);

    const signOutButton = document.createElement("a");
    signOutButton.classList.add("govuk-link");
    signOutButton.textContent = "Sign out";
    signOutButton.href = config.signOutUrl;
    signOutButton.setAttribute("aria-label", "Sign out and end session");

    buttonWrapper.append(continueButton, signOutButton);
    modalContent.append(heading, message, buttonWrapper);
    modal.appendChild(modalContent);
    document.body.appendChild(modal);
  }

  function openModal() {
    lastFocusedElement = document.activeElement;
    modal.style.display = "block";
    modal.setAttribute("aria-hidden", "false");
    document.querySelector("main").setAttribute("aria-hidden", "true");

    const focusableElements = modal.querySelectorAll("button, a");
    focusableElements[0]?.focus();

    modal.addEventListener("keydown", trapFocus);
  }

  function closeModal() {
    modal.style.display = "none";
    modal.setAttribute("aria-hidden", "true");
    document.querySelector("main").setAttribute("aria-hidden", "false");
    lastFocusedElement?.focus();
  }

  function trapFocus(event) {
    if (event.key !== "Tab") return;

    const focusableElements = modal.querySelectorAll("button, a");
    const firstElement = focusableElements[0];
    const lastElement = focusableElements[focusableElements.length - 1];

    if (event.shiftKey && document.activeElement === firstElement) {
      lastElement.focus();
      event.preventDefault();
    } else if (!event.shiftKey && document.activeElement === lastElement) {
      firstElement.focus();
      event.preventDefault();
    }
  }

  function startSessionTimeout() {
    timeoutId = setTimeout(openModal, config.timeoutWarningTime);
    logoutId = setTimeout(() => {
      window.location.href = config.signInUrl;
    }, config.sessionTimeout);
  }

  function resetSessionTimeout() {
    clearTimeout(timeoutId);
    clearTimeout(logoutId);
    closeModal();
    startSessionTimeout();
  }

  function resetOnUserActivity() {
    ["mousedown", "keypress", "scroll", "touchstart"].forEach(evt =>
      document.addEventListener(evt, resetSessionTimeout, { passive: true })
    );
  }

  try {
    createTimeoutModal();
    startSessionTimeout();
    resetOnUserActivity();
  } catch (error) {
    console.error("Error initializing session timeout:", error);
  }

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && modal.style.display === "block") {
      closeModal();
    }
  });
});


