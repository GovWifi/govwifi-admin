// import '@testing-library/jest-dom';
// import { fireEvent } from '@testing-library/dom';
// import '../app/assets/javascripts/timeout_warning';
//
//
// describe('Session Timeout Functionality', () => {
//
//
//   beforeEach(() => {
//     jest.useFakeTimers();
//     document.body.innerHTML = '<main><div id="timeoutModal" style="display: none;"></div></main>';
//     require('../app/assets/javascripts/timeout_warning');
//     document.dispatchEvent(new Event('DOMContentLoaded'));
//   });
//
//   afterEach(() => {
//     jest.clearAllTimers();
//     jest.useRealTimers();
//   });
//
//   it('Modal is created and initially hidden', () => {
//     const modal = document.getElementById('timeoutModal');
//     expect(modal).toBeTruthy();
//     expect(modal.style.display).toBe('none');
//   });
//
//   it('Modal appears after timeout warning time', () => {
//     jest.advanceTimersByTime(60000); // 60 seconds
//     const modal = document.getElementById('timeoutModal');
//     expect(modal.style.display).toBe('block');
//   });
//
//   it('Session resets when "Stay signed in" is clicked', () => {
//     jest.advanceTimersByTime(60000);
//     const continueButton = document.querySelector('button');
//     fireEvent.click(continueButton);
//     const modal = document.getElementById('timeoutModal');
//     expect(modal.style.display).toBe('none');
//   });
//
//   it('Redirects to sign in page after session timeout', () => {
//     const originalLocation = window.location;
//     delete window.location;
//     window.location = { href: jest.fn() };
//
//     jest.advanceTimersByTime(90000); // 90 seconds
//     expect(window.location.href).toBe('/users/sign_in');
//
//     window.location = originalLocation;
//   });
//
//   it('Modal closes when Escape key is pressed', () => {
//     jest.advanceTimersByTime(60000);
//     fireEvent.keyDown(document, { key: 'Escape' });
//     const modal = document.getElementById('timeoutModal');
//     expect(modal.style.display).toBe('none');
//   });
//
//   it('Focus is trapped inside modal', () => {
//     jest.advanceTimersByTime(60000);
//     const focusableElements = document.querySelectorAll('button, a');
//     const firstElement = focusableElements[0];
//     const lastElement = focusableElements[focusableElements.length - 1];
//
//     // Focus should move to first element when tabbing from last
//     lastElement.focus();
//     fireEvent.keyDown(lastElement, { key: 'Tab' });
//     expect(document.activeElement).toBe(firstElement);
//
//     // Focus should move to last element when shift+tabbing from first
//     firstElement.focus();
//     fireEvent.keyDown(firstElement, { key: 'Tab', shiftKey: true });
//     expect(document.activeElement).toBe(lastElement);
//   });
// });
// {
//
//
//   beforeEach(() => {
//     jest.useFakeTimers();
//     document.body.innerHTML = '<main><div id="timeoutModal" style="display: none;"></div></main>';
//     require('../app/assets/javascripts/timeout_warning');
//     document.dispatchEvent(new Event('DOMContentLoaded'));
//   });
//
//   afterEach(() => {
//     jest.clearAllTimers();
//     jest.useRealTimers();
//   });
//
//   it('Modal is created and initially hidden', () => {
//     const modal = document.getElementById('timeoutModal');
//     expect(modal).toBeTruthy();
//     expect(modal.style.display).toBe('none');
//   });
//
//   it('Modal appears after timeout warning time', () => {
//     jest.advanceTimersByTime(60000); // 60 seconds
//     const modal = document.getElementById('timeoutModal');
//     expect(modal.style.display).toBe('block');
//   });
//
//   it('Session resets when "Stay signed in" is clicked', () => {
//     jest.advanceTimersByTime(60000);
//     const continueButton = document.querySelector('button');
//     fireEvent.click(continueButton);
//     const modal = document.getElementById('timeoutModal');
//     expect(modal.style.display).toBe('none');
//   });
//
//   it('Redirects to sign in page after session timeout', () => {
//     const originalLocation = window.location;
//     delete window.location;
//     window.location = { href: jest.fn() };
//
//     jest.advanceTimersByTime(90000); // 90 seconds
//     expect(window.location.href).toBe('/users/sign_in');
//
//     window.location = originalLocation;
//   });
//
//   it('Modal closes when Escape key is pressed', () => {
//     jest.advanceTimersByTime(60000);
//     fireEvent.keyDown(document, { key: 'Escape' });
//     const modal = document.getElementById('timeoutModal');
//     expect(modal.style.display).toBe('none');
//   });
//
//   it('Focus is trapped inside modal', () => {
//     jest.advanceTimersByTime(60000);
//     const focusableElements = document.querySelectorAll('button, a');
//     const firstElement = focusableElements[0];
//     const lastElement = focusableElements[focusableElements.length - 1];
//
//     // Focus should move to first element when tabbing from last
//     lastElement.focus();
//     fireEvent.keyDown(lastElement, { key: 'Tab' });
//     expect(document.activeElement).toBe(firstElement);
//
//     // Focus should move to last element when shift+tabbing from first
//     firstElement.focus();
//     fireEvent.keyDown(firstElement, { key: 'Tab', shiftKey: true });
//     expect(document.activeElement).toBe(lastElement);
//   });
// });
import '@testing-library/jest-dom';
import { fireEvent } from '@testing-library/dom';
import '../app/assets/javascripts/timeout_warning';
import Timecop from 'timecop';

describe('Session Timeout Functionality', () => {
  beforeEach(() => {
    Timecop.install();
    document.body.innerHTML = '<main><div id="timeoutModal" style="display: none;"></div></main>';
    require('../app/assets/javascripts/timeout_warning');
    document.dispatchEvent(new Event('DOMContentLoaded'));
  });

  afterEach(() => {
    Timecop.uninstall();
  });

  it('Modal is created and initially hidden', () => {
    const modal = document.getElementById('timeoutModal');
    expect(modal).toBeTruthy();
    expect(modal.style.display).toBe('none');
  });

  it('Modal appears after timeout warning time', () => {
    Timecop.travel(Date.now() + 60000); // Travel 60 seconds into the future
    const modal = document.getElementById('timeoutModal');
    expect(modal.style.display).toBe('block');
  });

  it('Session resets when "Stay signed in" is clicked', () => {
    Timecop.travel(Date.now() + 60000);
    const continueButton = document.querySelector('button');
    fireEvent.click(continueButton);
    const modal = document.getElementById('timeoutModal');
    expect(modal.style.display).toBe('none');
  });

  it('Redirects to sign in page after session timeout', () => {
    const originalLocation = window.location;
    delete window.location;
    window.location = { href: jest.fn() };

    Timecop.travel(Date.now() + 90000); // Travel 90 seconds into the future
    expect(window.location.href).toBe('/users/sign_in');

    window.location = originalLocation;
  });

  it('Modal closes when Escape key is pressed', () => {
    Timecop.travel(Date.now() + 60000);
    fireEvent.keyDown(document, { key: 'Escape' });
    const modal = document.getElementById('timeoutModal');
    expect(modal.style.display).toBe('none');
  });

  it('Focus is trapped inside modal', () => {
    Timecop.travel(Date.now() + 60000);
    const focusableElements = document.querySelectorAll('button, a');
    const firstElement = focusableElements[0];
    const lastElement = focusableElements[focusableElements.length - 1];

    // Focus should move to first element when tabbing from last
    lastElement.focus();
    fireEvent.keyDown(lastElement, { key: 'Tab' });
    expect(document.activeElement).toBe(firstElement);

    // Focus should move to last element when shift+tabbing from first
    firstElement.focus();
    fireEvent.keyDown(firstElement, { key: 'Tab', shiftKey: true });
    expect(document.activeElement).toBe(lastElement);
  });
});
