document.addEventListener("DOMContentLoaded", function () {
  const timeoutWarningTime = 60 * 1000; // Show warning at 60 seconds
  const sessionTimeout = 90 * 1000; // Logout at 90 seconds

  let timeoutId;
  let logoutId;
  let modal;
  let lastFocusedElement;

  function createTimeoutModal() {
    // Create the modal overlay
    modal = document.createElement("div");
    modal.id = "timeoutModal";
    modal.setAttribute("role", "dialog");
    modal.setAttribute("aria-labelledby", "session-heading");
    modal.setAttribute("aria-describedby", "session-description");
    modal.setAttribute("aria-modal", "true");
    modal.style.display = "none";
    modal.style.position = "fixed";
    modal.style.top = "0";
    modal.style.left = "0";
    modal.style.width = "100%";
    modal.style.height = "100%";
    modal.style.backgroundColor = "rgba(0, 0, 0, 0.5)";
    modal.style.zIndex = "1000";

    const modalContent = document.createElement("div");
    modalContent.classList.add("govuk-panel", "govuk-panel--confirmation");
    modalContent.style.position = "absolute";
    modalContent.style.top = "50%";
    modalContent.style.left = "50%";
    modalContent.style.transform = "translate(-50%, -50%)";
    modalContent.style.padding = "20px";
    modalContent.style.textAlign = "center";
    modalContent.style.backgroundColor = "#fff";
    modalContent.style.outline = "none";

    // Modal heading
    const heading = document.createElement("h1");
    heading.classList.add("govuk-heading-l");
    heading.id = "session-heading";
    heading.textContent = "Your session is about to expire";

    // Modal message
    const message = document.createElement("p");
    message.classList.add("govuk-body");
    message.id = "session-description";
    message.textContent =
      "For your security, please advise if you would like to continue your session?";

    // Buttons wrapper
    const buttonWrapper = document.createElement("div");
    buttonWrapper.classList.add("govuk-button-group", "govuk-!-text-align-center");
    buttonWrapper.style.padding = "20px";
    buttonWrapper.style.textAlign = "center";

    // Continue session button
    const continueButton = document.createElement("button");
    continueButton.classList.add("govuk-button", "govuk-!-margin-right-2");
    continueButton.textContent = "Stay signed in";
    continueButton.setAttribute("aria-label", "Stay signed in and continue session");
    continueButton.addEventListener("click", () => {
      resetSessionTimeout();
      modal.style.display = "none";
      // closeModal();
    });

    const signOutButton = document.createElement("a");
    signOutButton.classList.add("govuk-link");
    signOutButton.textContent = "Sign out";
    signOutButton.href = "/users/sign_out";
    signOutButton.setAttribute("aria-label", "Sign out and end session");

    // Append buttons inside the wrapper
    buttonWrapper.appendChild(continueButton);
    buttonWrapper.appendChild(signOutButton);

    // Append elements
    modalContent.appendChild(heading);
    modalContent.appendChild(message);
    modalContent.appendChild(buttonWrapper);
    modal.appendChild(modalContent);
    document.body.appendChild(modal);

  document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" && modal.style.display === "block") {
      closeModal();
    }
  });
}
  function openModal() {
    lastFocusedElement = document.activeElement; // Store last focused element
    modal.style.display = "block";
    modal.setAttribute("aria-hidden", "false");

    // Disable background elements
    document.querySelector("main").setAttribute("aria-hidden", "true");

    // Trap focus inside modal
    const focusableElements = modal.querySelectorAll("button, a");
    focusableElements[0].focus();

    modal.addEventListener("keydown", function (event) {
      if (event.key === "Tab") {
        const firstElement = focusableElements[0];
        const lastElement = focusableElements[focusableElements.length - 1];

        if (event.shiftKey) {
          // Shift + Tab: Move focus backwards
          if (document.activeElement === firstElement) {
            lastElement.focus();
            event.preventDefault();
          }
        } else {
          // Tab: Move focus forward
          if (document.activeElement === lastElement) {
            firstElement.focus();
            event.preventDefault();
          }
        }
      }
    });
  }

  function closeModal() {
    modal.style.display = "none";
    modal.setAttribute("aria-hidden", "true");
    document.querySelector("main").setAttribute("aria-hidden", "false");

    if (lastFocusedElement) {
      lastFocusedElement.focus(); // Restore focus to last element
    }
  }

  function startSessionTimeout() {
    timeoutId = setTimeout(() => {
      modal.style.display = "block";
    }, timeoutWarningTime);

    logoutId = setTimeout(() => {
      window.location.href = "/users/sign_in";
    }, sessionTimeout);
  }

  function resetSessionTimeout() {
    clearTimeout(timeoutId);
    clearTimeout(logoutId);
    startSessionTimeout();
  }

  createTimeoutModal();
  startSessionTimeout();
});
