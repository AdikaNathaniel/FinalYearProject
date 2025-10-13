import React, { useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import axios from 'axios';
import pregnancyImg from '../assets/pregnancy.png';

export default function OTPVerification() {
  const navigate = useNavigate();
  const { email } = useParams(); // if you're passing email as a route param
  const [otp, setOtp] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleOtpChange = (e) => {
    const value = e.target.value;
    if (/^\d{0,6}$/.test(value)) {
      setOtp(value);
    }
  };

  const handleVerify = async () => {
    if (otp.length !== 6) {
      alert('Please enter a valid 6-digit OTP');
      return;
    }

    setIsLoading(true);
    try {
      const response = await axios.get(
        `https://patient-monitor-backend-patient.fly.dev/api/v1/users/verify-email/${otp}/${email}`
      );
      const data = response.data;

      if (
        response.status === 200 &&
        data.message === 'Email verified successfully. You can log in now.'
      ) {
        alert('✅ Email verified successfully. You can log in now.');
        navigate('/login');
      } else {
        alert(data.message || 'Verification failed');
      }
    } catch (err) {
      alert('❌ An error occurred. Please try again.');
    }
    setIsLoading(false);
  };

  return (
    <div className="relative w-full h-screen">
      {/* Background Image */}
      <img
        src={pregnancyImg}
        alt="Background"
        className="absolute w-full h-full object-cover z-0"
      />
      <div className="absolute w-full h-full bg-black opacity-60 z-10"></div>

      {/* Content */}
      <div className="relative z-20 flex justify-center items-center h-full">
        <div className="bg-gradient-to-br from-blue-600 to-red-500 p-8 rounded-xl shadow-lg w-full max-w-md">
          <h2 className="text-white text-3xl font-bold mb-4 text-center">
            Verify Your Email
          </h2>
          <p className="text-white text-center mb-6">
            Enter the 6-digit OTP sent to <span className="font-semibold">{email}</span>
          </p>

          <input
            type="text"
            value={otp}
            onChange={handleOtpChange}
            maxLength={6}
            className="w-full text-center text-xl tracking-widest bg-white text-black p-3 rounded-lg mb-6"
            placeholder="Enter OTP"
          />

          <button
            onClick={handleVerify}
            disabled={isLoading}
            className="w-full py-3 bg-white text-blue-600 font-bold rounded hover:bg-blue-100"
          >
            {isLoading ? 'Verifying...' : 'VERIFY'}
          </button>

          <div className="text-center mt-6">
            <a href="/login" className="text-sm text-white underline">
              Back to Login
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
