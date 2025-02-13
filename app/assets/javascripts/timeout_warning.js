document.addEventListener("DOMContentLoaded", function() {
  const timeoutWarningTime = 60 * 1000;
  const sessionTimeout = 90 * 1000;

  let timeoutId;
  let modal;

  function createTimeoutModal() {
    modal = document.createElement('div');
    modal.id = 'timeoutModal';
    modal.style.display = 'none';
    modal.style.position = 'fixed';
    modal.style.top = '0';
    modal.style.left = '0';
    modal.style.width = '100%';
    modal.style.height = '100%';
    modal.style.backgroundColor = 'rgba(0, 0, 0, 0.5)';
    modal.style.zIndex = '1000';

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

    console.log("Show timeout warning modal!");
    modal.style.display = 'block';
  }

  function resetTimeout() {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(showTimeoutModal, sessionTimeout - timeoutWarningTime);
  }

  function continueSession() {

    fetch('/extend_session')
      .then(response => {
        if (response.ok) {
          console.log("Session extended");
          modal.style.display = 'none';
          resetTimeout();
        } else {
          console.error("Failed to extend session");

        }
      })
      .catch(error => {
        console.error("Error extending session:", error);

      });
  }

  createTimeoutModal();

  resetTimeout();

  document.addEventListener("mousemove", resetTimeout);
  document.addEventListener("keypress", resetTimeout);
});

