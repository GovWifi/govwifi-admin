// app/javascript/timeout_warning.js

document.addEventListener("DOMContentLoaded", function() {
  const timeoutWarningTime = 1 * 60 * 1000; // 5 minutes before timeout
  const sessionTimeout = 2 * 60 * 1000; // 30 minutes total session

  let timeoutId;
  let modal;

  function createTimeoutModal() {
    modal = document.createElement('div');
    modal.id = 'timeoutModal';
    modal.style.display = 'none';  // Initially hidden
    modal.style.position = 'fixed';
    modal.style.top = '0';
    modal.style.left = '0';
    modal.style.width = '100%';
    modal.style.height = '100%';
    modal.style.backgroundColor = 'rgba(0, 0, 0, 0.5)'; // Semi-transparent background
    modal.style.zIndex = '1000'; // Ensure it's on top

    const modalContent = document.createElement('div');
    modalContent.style.position = 'absolute';
    modalContent.style.top = '50%';
    modalContent.style.left = '50%';
    modalContent.style.transform = 'translate(-50%, -50%)';
    modalContent.style.backgroundColor = 'white';
    modalContent.style.padding = '20px';
    modalContent.style.borderRadius = '5px';
    modalContent.style.textAlign = 'center';

    const message = document.createElement('p');
    message.textContent = 'Your session will time out soon. Click Continue to keep working.';
    modalContent.appendChild(message);

    const continueButton = document.createElement('button');
    continueButton.textContent = 'Continue';
    continueButton.addEventListener('click', continueSession);
    modalContent.appendChild(continueButton);

    modal.appendChild(modalContent);
    document.body.appendChild(modal);
  }



  function showTimeoutModal() {
    // Code to display the modal
    console.log("Show timeout warning modal!");
    modal.style.display = 'block'; // Make modal visible
  }

  function resetTimeout() {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(showTimeoutModal, sessionTimeout - timeoutWarningTime);
  }

  function continueSession() {
    // Call API to extend the session (if needed)
    fetch('/extend_session') //Adjust based on your backend route
      .then(response => {
        if (response.ok) {
          console.log("Session extended");
          modal.style.display = 'none'; // Hide modal
          resetTimeout(); // Restart the timer
        } else {
          console.error("Failed to extend session");
          // Handle error (e.g., display an error message)
        }
      })
      .catch(error => {
        console.error("Error extending session:", error);
        //Handle error
      });
  }

  //Initialize the modal on load
  createTimeoutModal();

  // Start the timer when the page loads
  resetTimeout();

  // Reset the timer on user activity
  document.addEventListener("mousemove", resetTimeout);
  document.addEventListener("keypress", resetTimeout);
});

