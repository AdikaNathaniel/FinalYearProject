import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';


import LoginPage from './components/LoginPage';
import FaceRegister from './components/FaceRegister';
import OTPVerification from './components/OTP';

export default function App() {
  return (
    <Router>
      <Routes>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/register-face" element={<FaceRegister />} />
        <Route path="/otp-verify" element={<OTPVerification />} />

        {/* Optional fallback route */}
        <Route
          path="*"
          element={
            <div className="text-center mt-10 text-red-600 text-2xl">
              404 - Page Not Found
            </div>
          }
        />
      </Routes>
    </Router>
  );
}
