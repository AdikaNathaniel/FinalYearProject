import React, { useState } from 'react';
import loginImg from '../assets/pregnancy.png';
import ForgotPassword from './ForgotPassword';
import Register from './Register';
import FaceLogin from './FaceLogin'; // 👈 Make sure this file exists

export default function Login() {
  const [showForgotPassword, setShowForgotPassword] = useState(false);
  const [showRegister, setShowRegister] = useState(false);
  const [showFaceLogin, setShowFaceLogin] = useState(false); // 👈 New state

  if (showForgotPassword) {
    return <ForgotPassword goBack={() => setShowForgotPassword(false)} />;
  }

  if (showRegister) {
    return <Register goBack={() => setShowRegister(false)} />;
  }

  if (showFaceLogin) {
    return <FaceLogin />;
  }

  return (
    <div className='grid grid-cols-1 sm:grid-cols-2 h-screen w-full'>
      {/* Left side image */}
      <div className='hidden sm:block'>
        <img className='w-full h-full object-cover' src={loginImg} alt="Pregnancy" />
      </div>

      {/* Right side */}
      <div className='bg-gradient-to-br from-blue-500 to-red-500 flex flex-col justify-center items-center'>
        <form className='max-w-[400px] w-full mx-auto rounded-lg bg-cyan-600 p-8 px-8 shadow-xl'>
          <h2 className="text-4xl text-white font-bold text-center">SIGN IN</h2>

          {/* Email */}
          <div className='flex flex-col py-2'>
            <label className='text-white'>Email</label>
            <input 
              className='rounded-lg bg-white mt-2 p-2 focus:border-blue-500 focus:outline-none text-black' 
              type="text" 
            />
          </div>

          {/* Password */}
          <div className='flex flex-col py-2'>
            <label className='text-white'>Password</label>
            <input 
              className='p-2 rounded-lg bg-white mt-2 focus:border-blue-500 focus:outline-none text-black' 
              type="password" 
            />
          </div>

          {/* User Type */}
          <div className='flex flex-col py-2'>
            <label className='text-white'>User Type</label>
            <select className='mt-2 p-2 rounded-lg bg-white text-black focus:border-blue-500 focus:outline-none'>
              <option>Doctor</option>
              <option>Pregnant Woman</option>
              <option>Family Relative</option>
              <option>Admin</option>
              <option>Wellness User</option>
            </select>
          </div>

          {/* Remember Me + Forgot */}
          <div className='flex justify-between text-white py-2 text-sm'>
            <p className='flex items-center'>
              <input className='mr-2' type="checkbox" /> Remember Me
            </p>
            <p 
              className='hover:underline cursor-pointer'
              onClick={() => setShowForgotPassword(true)}
            >
              Forgot Password
            </p>
          </div>

          {/* Login Button */}
          <button className='w-full my-5 py-2 bg-teal-500 shadow-lg shadow-teal-500/50 hover:shadow-teal-500/40 text-white font-semibold rounded-lg'>
            LOGIN
          </button>

          {/* Extra Links */}
          <p 
            className='text-center text-white text-sm mt-4 hover:underline cursor-pointer'
            onClick={() => setShowRegister(true)}
          >
            Don't have an account? Register here
          </p>

          {/* 👇 Facial Recognition Redirect */}
          <p 
            className='text-center text-white text-sm italic mt-2 hover:underline cursor-pointer'
            onClick={() => setShowFaceLogin(true)}
          >
            Tap here to log in with facial recognition.
          </p>
        </form>
      </div>
    </div>
  );
}
