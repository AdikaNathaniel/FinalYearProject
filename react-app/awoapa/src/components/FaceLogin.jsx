import React, { useState } from 'react';
import loginImg from '../assets/pregnancy.png';
import FaceRegister from './FaceRegister'; // ✅ Import the register component

export default function FaceLogin() {
  const [image, setImage] = useState(null);
  const [previewURL, setPreviewURL] = useState(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const [showFaceRegister, setShowFaceRegister] = useState(false); // ✅ Toggle flag

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setImage(file);
      setPreviewURL(URL.createObjectURL(file));
    }
  };

  const handleFaceAuth = async () => {
    if (!image) {
      setMessage('Please select an image.');
      return;
    }

    setLoading(true);
    setMessage('');

    const formData = new FormData();
    formData.append('image', image);

    try {
      const res = await fetch('http://localhost:3100/api/v1/face/detect', {
        method: 'POST',
        body: formData,
      });

      const data = await res.json();
      setLoading(false);

      if (res.status === 201 && data.success) {
        const result = data.result;
        if (!result.faces || result.faces.length === 0 || !result.match) {
          alert('Invalid user');
          return;
        }

        const confidence = parseFloat(result.match.confidence) || 0;
        if (confidence > 0.40) {
          alert('Low confidence. Use email and password instead.');
          window.location.href = '/login';
          return;
        }

        const userId = result.match.userId || '';
        const faceGender = result.faces[0].gender || '';

        if (userId) {
          const confirmed = window.confirm(`Are you ${userId}?`);
          if (confirmed) {
            handleRedirect(userId, faceGender);
          } else {
            alert('Kindly upload a new Image for Access');
          }
        } else {
          alert('Unable to verify identity');
        }
      } else {
        setMessage(data.message || 'Authentication failed');
      }
    } catch (err) {
      console.error(err);
      setMessage('Error connecting to the server');
      setLoading(false);
    }
  };

  const handleRedirect = (userId, gender) => {
    if (userId === 'Einsteina Owoh') {
      alert('Logging In As Pregnant Woman');
      window.location.href = `/calculator?user=${encodeURIComponent(userId)}`;
    } else if (userId === 'Dr.George Anane') {
      alert('Logging In As Medic');
      window.location.href = `/predictions?user=${encodeURIComponent(userId)}`;
    } else {
      alert('Invalid user');
      window.location.href = '/login';
    }
  };

  // ✅ Render FaceRegister directly if user clicked the register link
  if (showFaceRegister) {
    return <FaceRegister />;
  }

  return (
    <div className="h-screen w-full relative">
      <img
        src={loginImg}
        alt="Background"
        className="absolute w-full h-full object-cover z-0"
      />
      <div className="absolute w-full h-full bg-black opacity-60 z-10"></div>

      <div className="flex flex-col justify-center items-center h-full z-20 relative text-white">
        <div className="bg-cyan-600 rounded-lg shadow-xl p-8 w-full max-w-lg">
          <h2 className="text-3xl font-bold text-center mb-6">Face Login AwoaPa</h2>

          {previewURL && (
            <div className="mb-4 flex justify-center">
              <img
                src={previewURL}
                alt="Selected"
                className="w-48 h-48 object-cover rounded-lg border-2 border-white"
              />
            </div>
          )}

          <div className="flex flex-col mb-4">
            <label className="mb-2">Upload Your Face Image</label>
            <input
              type="file"
              accept="image/*"
              onChange={handleFileChange}
              className="p-2 bg-white text-black rounded-lg"
            />
          </div>

          {message && <p className="text-center text-sm mb-4 text-red-200">{message}</p>}

          <button
            onClick={handleFaceAuth}
            disabled={loading}
            className="w-full py-2 bg-teal-500 hover:bg-teal-600 rounded-lg font-semibold"
          >
            {loading ? 'Authenticating...' : 'Login with Face'}
          </button>

          <p className="text-center text-sm mt-4">
            <a href="/login" className="text-white hover:underline">
              Use Email/Password Instead
            </a>
          </p>

          <p className="text-center text-sm mt-2 italic">
            <span
              onClick={() => setShowFaceRegister(true)} // ✅ Toggle component render
              className="text-white hover:underline cursor-pointer"
            >
              Click Here to Register Your Face on AwoaPa
            </span>
          </p>
        </div>
      </div>
    </div>
  );
}
