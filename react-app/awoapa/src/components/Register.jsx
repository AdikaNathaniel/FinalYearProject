import React, { useState } from 'react';
import loginImg from '../assets/pregnancy.png';

export default function Register() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [type, setType] = useState('');
  const [card, setCard] = useState('');
  const [allowRelative, setAllowRelative] = useState(false);
  const [message, setMessage] = useState(null);
  const [loading, setLoading] = useState(false);

  const isValidEmail = (email) =>
    /^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$/.test(email);

  const isValidCard = (c) => /^\d{6,15}$/.test(c);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setMessage('');

    if (!name || !email || !password || !type || !card) {
      setMessage('All fields are required.');
      return;
    }
    if (!isValidEmail(email)) {
      setMessage('Please enter a valid email address.');
      return;
    }
    if (!isValidCard(card)) {
      setMessage('Ghana Card Number must be 6–15 digits.');
      return;
    }
    if (password.length < 6) {
      setMessage('Password must be at least 6 characters.');
      return;
    }
    const validTypes = ['patient', 'relative', 'doctor', 'nurse', 'wellness user', 'admin'];
    if (!validTypes.includes(type.toLowerCase())) {
      setMessage('Invalid user type.');
      return;
    }

    setLoading(true);
    try {
      const res = await fetch('https://patient-monitor-backend-patient.fly.dev/api/v1/users', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email: email.toLowerCase(), password, type: type.toLowerCase(), card }),
      });
      const data = await res.json();
      if (res.status === 201 && data.success) {
        setMessage('Registration successful! Please check your email for OTP.');
      } else {
        setMessage(data.message || `Registration failed (${res.status}).`);
      }
    } catch (err) {
      setMessage('Server error during registration.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="h-screen w-full relative">
      <img
        src={loginImg}
        alt="Background"
        className="absolute w-full h-full object-cover z-0"
      />
      <div className="absolute w-full h-full bg-black opacity-60 z-10"></div>

      <div className="flex justify-center items-center h-full z-20 relative">
        <form
          onSubmit={handleSubmit}
          className="max-w-lg w-full bg-cyan-600 text-white p-8 rounded-lg shadow-xl"
        >
          <h2 className="text-3xl font-bold text-center mb-6">Register On Awopa</h2>

          {message && (
            <p className="mb-4 text-center text-sm text-teal-100">{message}</p>
          )}

          <div className="flex flex-col mb-4">
            <label className="mb-2">Full Name</label>
            <input
              className="p-2 rounded-lg bg-white text-black focus:outline-none"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />
          </div>

          <div className="flex flex-col mb-4">
            <label className="mb-2">Email</label>
            <input
              type="email"
              className="p-2 rounded-lg bg-white text-black focus:outline-none"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          <div className="flex flex-col mb-4">
            <label className="mb-2">Password</label>
            <input
              type="password"
              className="p-2 rounded-lg bg-white text-black focus:outline-none"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          <div className="flex flex-col mb-4">
            <label className="mb-2">User Type</label>
            <select
              className="p-2 rounded-lg bg-white text-black focus:outline-none"
              value={type}
              onChange={(e) => setType(e.target.value)}
              required
            >
              <option value="">Select type...</option>
              <option>Doctor</option>
              <option>Pregnant Woman</option>
              <option>Family Relative</option>
              <option>Admin</option>
              <option>Wellness User</option>
            </select>
          </div>

          <div className="flex flex-col mb-4">
            <label className="mb-2">Ghana Card Number</label>
            <input
              className="p-2 rounded-lg bg-white text-black focus:outline-none"
              value={card}
              onChange={(e) => setCard(e.target.value)}
              required
            />
          </div>

          <div className="flex items-center mb-6">
            <input
              type="checkbox"
              checked={allowRelative}
              onChange={() => setAllowRelative(!allowRelative)}
              className="mr-2"
            />
            <label>Allow relative to view vitals</label>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-2 bg-teal-500 hover:bg-teal-600 rounded-lg font-semibold"
          >
            {loading ? 'Registering...' : 'Register'}
          </button>

          <p className="text-center text-sm mt-4">
            <button
              type="button"
              className="text-white hover:underline"
              onClick={() => window.location.reload()}
            >
              Already have an account? Login
            </button>
          </p>
        </form>
      </div>
    </div>
  );
}
