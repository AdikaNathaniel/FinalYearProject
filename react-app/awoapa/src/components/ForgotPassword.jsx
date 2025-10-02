import React, { useState } from 'react';
import loginImg from '../assets/pregnancy.png';

export default function ForgotPassword() {
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [messageColor, setMessageColor] = useState('text-teal-100');
  const [loading, setLoading] = useState(false);

  const handleReset = async (e) => {
    e.preventDefault();

    if (!email) {
      setMessage('Please enter your email');
      setMessageColor('text-red-300');
      return;
    }

    setLoading(true);
    try {
      const response = await fetch(`http://localhost:3100/api/v1/users/forgot-password/${email}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      const data = await response.json();
      console.log('Forgot password response:', data);

      if (response.status === 200 && data.success) {
        setMessage('Password reset link sent to your email.');
        setMessageColor('text-green-200');
      } else {
        setMessage(data.message || 'Failed to send reset email.');
        setMessageColor('text-red-300');
      }
    } catch (error) {
      console.error('Error during forgot password:', error);
      setMessage('Server error. Please try again.');
      setMessageColor('text-red-300');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="h-screen w-full relative">
      {/* Background image */}
      <img 
        src={loginImg} 
        alt="Background" 
        className="absolute w-full h-full object-cover z-0" 
      />

      {/* Dark overlay */}
      <div className="absolute w-full h-full bg-black opacity-50 z-10"></div>

      {/* Forgot Password Form Card */}
      <div className="flex justify-center items-center h-full z-20 relative">
        <form 
          onSubmit={handleReset} 
          className="max-w-[400px] w-full bg-cyan-600 text-white p-8 rounded-lg shadow-xl"
        >
          <h2 className="text-3xl font-bold text-center mb-6">Forgot Password</h2>

          <div className="flex flex-col mb-4">
            <label className="mb-2">Email</label>
            <input 
              type="email" 
              placeholder="Enter your email" 
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="p-2 rounded-lg bg-white text-black focus:outline-none focus:ring-2 focus:ring-blue-300"
              required
            />
          </div>

          <button 
            type="submit"
            className="w-full py-2 mt-4 bg-teal-500 hover:bg-teal-600 rounded-lg font-semibold"
            disabled={loading}
          >
            {loading ? 'Sending...' : 'Send Reset Link'}
          </button>

          {message && (
            <p className={`text-center text-sm mt-4 ${messageColor}`}>
              {message}
            </p>
          )}

          <div className="text-center mt-6">
            <a href="/login" className="text-sm text-white hover:underline">
              Back to Login
            </a>
          </div>
        </form>
      </div>
    </div>
  );
}
