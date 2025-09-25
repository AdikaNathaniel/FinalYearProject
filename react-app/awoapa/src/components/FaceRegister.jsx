import React, { useState } from 'react';
import pregnancyImg from '../assets/pregnancy.png';
import axios from 'axios';

export default function FaceRegister() {
  const [userId, setUserId] = useState('');
  const [selectedImage, setSelectedImage] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setSelectedImage(file);
      setPreviewUrl(URL.createObjectURL(file));
    }
  };

  const handleSubmit = async () => {
    if (!userId || !selectedImage) {
      alert('User ID and image are required');
      return;
    }

    setIsLoading(true);

    const formData = new FormData();
    formData.append('userId', userId);
    formData.append('image', selectedImage);

    try {
      const response = await axios.post('http://localhost:3100/api/v1/face/register', formData);
      if (response.status === 201) {
        alert('Registration successful. You can now log in with your face.');
      } else {
        alert('Registration failed.');
      }
    } catch (error) {
      alert(`Error: ${error.response?.data || error.message}`);
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

      {/* Centered Card */}
      <div className="relative z-20 flex justify-center items-center h-full">
        <div className="bg-cyan-600 p-8 rounded-xl shadow-lg w-full max-w-md">
          <h2 className="text-white text-3xl font-bold mb-6 text-center">Register Face</h2>

          <input
            type="text"
            placeholder="Enter Username"
            value={userId}
            onChange={(e) => setUserId(e.target.value)}
            className="w-full p-3 rounded-lg mb-4 focus:outline-none text-black"
          />

          <input
            type="file"
            accept="image/*"
            onChange={handleImageChange}
            className="w-full p-2 mb-4 bg-white rounded"
          />

          {previewUrl ? (
            <img
              src={previewUrl}
              alt="Preview"
              className="w-full h-48 object-contain rounded-lg border mb-4"
            />
          ) : (
            <div className="w-full h-48 flex items-center justify-center text-white border border-white rounded mb-4">
              No image selected
            </div>
          )}

          <button
            onClick={handleSubmit}
            disabled={isLoading}
            className="w-full py-2 bg-teal-500 hover:bg-teal-600 rounded-lg font-semibold text-white"
          >
            {isLoading ? 'Registering...' : 'REGISTER'}
          </button>

          <div className="text-center mt-6">
            <a href="/login" className="text-sm text-white hover:underline">
              Back to Login
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
