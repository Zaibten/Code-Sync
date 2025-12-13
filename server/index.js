// Very 1st script of node js
console.log('');
console.log("******* Code Sync Server Side *******");
console.log('');

// External Packages
require('dotenv').config();  // <--- Load .env
const express = require('express');
const { default: mongoose } = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const OpenAI = require('openai');
const User = require('./models/user'); // import the model

const bcrypt = require('bcryptjs'); // for hashing passwords
// Internal Routes
const authRouter = require('./routes/auth.js');

// INIT
const app = express();
const PORT = process.env.PORT || 9000;
const DB = process.env.MONGO_URI;

// Middle ware
app.use(express.json());
app.use(authRouter);

// Serve Static Assets (FIX)
app.use("/assets", express.static("assets"));



// Connections
mongoose.connect(DB)
  .then(() => {
    console.log('MongoDB connection successful');
  })
  .catch((e) => {
    console.log("MongoDB Error:", e);
  });

app.use(cors());
app.use(bodyParser.json({ limit: "10mb" }));


// -------------------- Reset Password --------------------
app.post('/reset-password', async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    if (!email || !newPassword) {
      return res.status(400).json({ success: false, error: "Email and new password are required" });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ success: false, error: "User not found" });

    const hashedPassword = await bcrypt.hash(newPassword, 10); // hash new password
    user.password = hashedPassword;
    await user.save();

    res.json({ success: true, message: "Password updated successfully" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: "Server error" });
  }
});



// -------------------- Profile Route --------------------
app.post('/profile', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: "Email is required" });

    const user = await User.findOne({ email }).select('-password'); // exclude password
    if (!user) return res.status(404).json({ error: "User not found" });

    res.json({ success: true, user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
});






  // -------------------- OpenAI Init --------------------
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// Fix code route
app.post('/fix-code', async (req, res) => {
  try {
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({ error: 'Code is required' });
    }

    // Prompt to OpenAI
    const prompt = `
You are an expert developer and code reviewer. 
1. Detect any errors in the following code.
2. Highlight the errors in a readable format.
3. Correct the code.
4. Identify the programming language/framework.

Code:
${code}

Format your response as JSON:
{
  "correctedCode": "<corrected code here>",
  "errors": "<highlighted errors here>",
  "language": "<language/framework here>"
}
`;

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [{ role: "user", content: prompt }],
      temperature: 0,
    });

    const resultText = completion.choices[0].message.content;

    // Try to parse JSON
    let parsed;
    try {
      parsed = JSON.parse(resultText);
    } catch (err) {
      parsed = {
        correctedCode: resultText,
        errors: "Unable to parse errors",
        language: "Unknown",
      };
    }

    res.json(parsed);

  } catch (err) {
    console.error(err.message);
    res.status(500).json({ error: 'Server error' });
  }
});

// Home Route (Dashboard UI)
app.get("/home", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Code Sync Server</title>
<link rel="icon" type="image/x-icon" href="assets/images/logo.png" />
      <script src="https://cdn.jsdelivr.net/particles.js/2.0.0/particles.min.js"></script>
      <style>
        @import url('https://fonts.googleapis.com/css2?family=Montserrat:wght@400;500;700&display=swap');
        body {
          margin: 0;
          font-family: 'Montserrat', sans-serif;
          background-color: #1e1e2f;
          color: #e4e4e4;
          display: flex;
          flex-direction: column;
          min-height: 100vh;
          overflow-x: hidden;
          position: relative;
        }
        .particle-container {
          position: absolute;
          top: 0;
          left: 0;
          width: 100%;
          height: 100%;
          z-index: -1;
        }
        .dashboard-container {
          width: 90%;
          max-width: 1200px;
          padding: 30px;
          background-color: #2b2b3d;
          border-radius: 15px;
          box-shadow: 0 10px 30px rgba(0, 0, 0, 0.4);
          margin: 30px auto;
          flex-grow: 1;
          animation: fadeIn 1.2s ease-in-out;
          z-index: 1;
        }
        @keyframes fadeIn {
          0% { opacity: 0; transform: translateY(20px); }
          100% { opacity: 1; transform: translateY(0); }
        }
        .header {
          display: flex;
          align-items: center;
          justify-content: space-between;
          margin-bottom: 30px;
        }
        .header img {
          height: 100px;
          width: 100px;
          border-radius: 50%;
          box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }
        .header h1 {
          font-size: 36px;
          color: #fff;
          font-weight: 700;
          margin: 0;
        }
        .header p {
          font-size: 18px;
          color: #bbb;
          margin-top: 5px;
          text-align: center;
        }
        .main-content {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 30px;
          margin-bottom: 40px;
        }
        .cards {
          display: flex;
          flex-direction: column;
          gap: 20px;
        }
        .card {
          background: linear-gradient(145deg, #3b3b4f, #242435);
          padding: 20px;
          border-radius: 10px;
          box-shadow: inset 0 4px 8px rgba(0, 0, 0, 0.3), 0 5px 15px rgba(0, 0, 0, 0.3);
          transition: transform 0.3s ease, box-shadow 0.3s ease;
          border-left: 5px solid #ff7f50;
        }
        .card:hover {
          transform: translateY(-5px) scale(1.02);
          box-shadow: 0 8px 20px rgba(0, 0, 0, 0.4);
        }
        .card h3 {
          font-size: 24px;
          color: #ffcc00;
          margin-bottom: 10px;
        }
        .card p {
          font-size: 16px;
          color: #ddd;
        }
        .recent-activities {
          background: linear-gradient(145deg, #41415b, #2c2c3d);
          padding: 20px;
          border-radius: 10px;
          box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
        }
        .recent-activities h2 {
          font-size: 28px;
          margin-bottom: 15px;
          color: #ffcc00;
        }
        .recent-activities ul {
          padding-left: 20px;
        }
        .recent-activities li {
          font-size: 16px;
          color: #ddd;
          margin-bottom: 10px;
        }
        footer {
          background-color: #282836;
          color: #999;
          padding: 20px;
          text-align: center;
          font-size: 14px;
          border-top: 2px solid #444;
        }
        footer p {
          margin: 0;
        }
        footer a {
          color: #ff7f50;
          text-decoration: none;
          font-weight: 500;
        }
      </style>
    </head>
    <body>
      <div id="particle-container" class="particle-container"></div>
      <div class="dashboard-container">
        <div class="header">
          <img src="/assets/images/logo.png" alt="App Logo" />
          <div>
            <h1>Code Sync Server Dashboard</h1>
            <p>3D Virtually Perfect</p>
          </div>
        </div>

        <footer>
          <p>&copy; 2025 Anatomy. All rights reserved. 
          <a href="#">Terms</a> | <a href="#">Privacy Policy</a></p>
        </footer>
      </div>

      <script>
        particlesJS("particle-container", {
          particles: {
            number: { value: 80, density: { enable: true, value_area: 800 } },
            shape: { type: "circle" },
            opacity: { value: 0.5 },
            size: { value: 3 },
            line_linked: { enable: true, color: "#fff", opacity: 0.5, width: 2 },
          },
          interactivity: {
            events: {
              onhover: { enable: true, mode: "repulse" },
            },
          },
        });
      </script>
    </body>
    </html>
  `);
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running at:`);
  console.log(`➡️ http://localhost:${PORT}`);
  console.log(`➡️ http://0.0.0.0:${PORT}`);
});

























// // index.js
// console.log("******* Code Sync Server *******");

// // -------------------- Packages --------------------
// require('dotenv').config();
// const express = require('express');
// const bodyParser = require('body-parser');
// const cors = require('cors');
// const OpenAI = require('openai');

// // -------------------- App Init --------------------
// const app = express();
// const PORT = process.env.PORT || 5000;

// app.use(cors());
// app.use(bodyParser.json({ limit: "10mb" }));

// // -------------------- OpenAI Init --------------------
// const openai = new OpenAI({
//   apiKey: process.env.OPENAI_API_KEY,
// });

// // -------------------- API ROUTES --------------------

// // Homepage
// app.get('/', (req, res) => {
//   res.send({ message: 'Welcome to Code Sync API' });
// });

// // Fix code route
// app.post('/fix-code', async (req, res) => {
//   try {
//     const { code } = req.body;

//     if (!code) {
//       return res.status(400).json({ error: 'Code is required' });
//     }

//     // Prompt to OpenAI
//     const prompt = `
// You are an expert developer and code reviewer. 
// 1. Detect any errors in the following code.
// 2. Highlight the errors in a readable format.
// 3. Correct the code.
// 4. Identify the programming language/framework.

// Code:
// ${code}

// Format your response as JSON:
// {
//   "correctedCode": "<corrected code here>",
//   "errors": "<highlighted errors here>",
//   "language": "<language/framework here>"
// }
// `;

//     const completion = await openai.chat.completions.create({
//       model: "gpt-4",
//       messages: [{ role: "user", content: prompt }],
//       temperature: 0,
//     });

//     const resultText = completion.choices[0].message.content;

//     // Try to parse JSON
//     let parsed;
//     try {
//       parsed = JSON.parse(resultText);
//     } catch (err) {
//       parsed = {
//         correctedCode: resultText,
//         errors: "Unable to parse errors",
//         language: "Unknown",
//       };
//     }

//     res.json(parsed);

//   } catch (err) {
//     console.error(err.message);
//     res.status(500).json({ error: 'Server error' });
//   }
// });

// // -------------------- Start Server --------------------
// app.listen(PORT, () => {
//   console.log(`Server running on port ${PORT}`);
// });
