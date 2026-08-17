require('dotenv').config();
const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const session = require('express-session');
const methodOverride = require('method-override');

// connect-mongo v5+ exports the class directly with a static .create().
// Some interop/older-version situations expose it under `.default` instead —
// this fallback covers both so a version mismatch doesn't crash the app.
const connectMongoImport = require('connect-mongo');
const MongoStore = connectMongoImport.create ? connectMongoImport : connectMongoImport.default;

const app = express();
const PORT = process.env.PORT || 3000;
const MONGO_URI = process.env.MONGO_URI;
const SESSION_SECRET = process.env.SESSION_SECRET || 'code-sync-please-change-this-secret';

/* =========================================================
   DB CONNECTION (cached — safe for serverless / Vercel)
   ========================================================= */
let isConnected = false;
async function connectDB() {
  if (isConnected || mongoose.connection.readyState === 1) return;
  await mongoose.connect(MONGO_URI);
  isConnected = true;
  console.log('MongoDB connected');
}
connectDB().catch(err => console.error('MongoDB connection error:', err));

/* =========================================================
   SCHEMAS (guarded against model re-registration on Vercel)
   ========================================================= */
const userSchema = new mongoose.Schema({
  name: String,
  email: String,
  password: String,
  otp: Number,
  otpExpiry: Date,
});
const User = mongoose.models.User || mongoose.model('User', userSchema);

const adminSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true, trim: true },
  password: { type: String, required: true }, // bcrypt hash
  isEnvAdmin: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});
const Admin = mongoose.models.Admin || mongoose.model('Admin', adminSchema);

/* =========================================================
   Seed the env admin into MongoDB so the panel can log in
   directly from the DB (kept in sync with .env on boot)
   ========================================================= */
async function seedEnvAdmin() {
  try {
    await connectDB();
    const envUser = process.env.ADMIN_USERNAME;
    const envPass = process.env.ADMIN_PASSWORD;
    if (!envUser || !envPass) return;

    const hashed = await bcrypt.hash(envPass, 10);
    await Admin.findOneAndUpdate(
      { username: envUser },
      { username: envUser, password: hashed, isEnvAdmin: true },
      { upsert: true, new: true, setDefaultsOnInsert: true },
    );
    console.log(`Env admin "${envUser}" synced to MongoDB`);
  } catch (err) {
    console.error('Failed to seed env admin:', err);
  }
}
seedEnvAdmin();

/* =========================================================
   MIDDLEWARE
   ========================================================= */
app.use('/assets', express.static(path.join(__dirname, 'assets')));
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.json());
app.use(methodOverride('_method'));

app.use(
  session({
    secret: SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    store: MONGO_URI
      ? MongoStore.create({ mongoUrl: MONGO_URI, collectionName: 'admin_sessions' })
      : undefined,
    cookie: {
      httpOnly: true,
      maxAge: 1000 * 60 * 60 * 8, // 8 hours
      sameSite: 'lax',
    },
  }),
);

function requireAuth(req, res, next) {
  if (req.session && req.session.loggedIn) return next();
  return res.redirect('/');
}

function escapeHtml(str) {
  if (str === undefined || str === null) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/* =========================================================
   SHARED HEAD (fonts, libs, base animated theme)
   ========================================================= */
const sharedHead = `
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1, user-scalable=no">
  <link rel="icon" href="/assets/logo.png">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
  <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>
  <script src="https://unpkg.com/aos@2.3.4/dist/aos.js"></script>
  <link href="https://unpkg.com/aos@2.3.4/dist/aos.css" rel="stylesheet">
  <style>
    :root{
      --bg-1:#0b0f1a; --bg-2:#111729; --panel:#151c30; --panel-2:#1b2338;
      --accent:#6c5ce7; --accent-2:#00d2ff; --accent-3:#00e5a0;
      --danger:#ff5f6d; --warn:#ffc857; --text:#eef1f8; --muted:#8b93a7;
      --border:rgba(255,255,255,.08); --radius:16px;
      --shadow:0 10px 30px rgba(0,0,0,.35);
    }
    *{margin:0;padding:0;box-sizing:border-box;}
    body{font-family:'Inter',sans-serif;background:var(--bg-1);color:var(--text);}
    ::-webkit-scrollbar{width:8px;height:8px;}
    ::-webkit-scrollbar-thumb{background:var(--accent);border-radius:8px;}
    ::-webkit-scrollbar-track{background:transparent;}
    a{color:inherit;text-decoration:none;}
    .grad-text{background:linear-gradient(90deg,var(--accent),var(--accent-2));-webkit-background-clip:text;background-clip:text;color:transparent;}
    .btn{cursor:pointer;border:none;border-radius:10px;font-family:inherit;font-weight:600;transition:.25s;}
    .btn:active{transform:scale(.96);}
    .btn-primary{background:linear-gradient(135deg,var(--accent),var(--accent-2));color:#fff;padding:12px 20px;box-shadow:0 6px 20px rgba(108,92,231,.35);}
    .btn-primary:hover{filter:brightness(1.1);transform:translateY(-2px);}
    .btn-danger{background:linear-gradient(135deg,#ff5f6d,#c0392b);color:#fff;padding:8px 14px;font-size:.8rem;}
    .btn-danger:hover{filter:brightness(1.1);}
    .btn-ghost{background:transparent;border:1px solid var(--border);color:var(--text);padding:10px 16px;}
    .btn-ghost:hover{background:rgba(255,255,255,.06);}
  </style>
`;

/* =========================================================
   LOGIN PAGE
   ========================================================= */
app.get('/', (req, res) => {
  if (req.session && req.session.loggedIn) return res.redirect('/home');
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <title>Code Sync Admin Panel — Login</title>
      ${sharedHead}
      <style>
        body{
          font-family:'Poppins',sans-serif;
          min-height:100vh;display:flex;align-items:center;justify-content:center;
          background:radial-gradient(1200px 600px at 10% 10%, #1a2140 0%, transparent 60%),
                     radial-gradient(1000px 500px at 90% 90%, #24123f 0%, transparent 60%),
                     var(--bg-1);
          overflow:hidden;position:relative;
        }
        .blob{position:absolute;border-radius:50%;filter:blur(90px);opacity:.35;animation:float 10s ease-in-out infinite;}
        .blob1{width:380px;height:380px;background:var(--accent);top:-100px;left:-100px;}
        .blob2{width:320px;height:320px;background:var(--accent-2);bottom:-100px;right:-80px;animation-delay:2s;}
        .blob3{width:260px;height:260px;background:var(--accent-3);top:40%;right:20%;animation-delay:4s;}
        @keyframes float{0%,100%{transform:translateY(0) scale(1);}50%{transform:translateY(-30px) scale(1.08);}}

        .login-card{
          position:relative;z-index:2;width:100%;max-width:420px;margin:20px;
          background:rgba(21,28,48,.75);backdrop-filter:blur(18px);
          border:1px solid var(--border);border-radius:24px;padding:44px 34px;
          box-shadow:var(--shadow);text-align:center;
          animation:cardRise .7s cubic-bezier(.4,0,.2,1) both;
        }
        @keyframes cardRise{from{opacity:0;transform:translateY(28px) scale(.97);}to{opacity:1;transform:translateY(0) scale(1);}}
        .logo-wrap{width:86px;height:86px;margin:0 auto 18px;border-radius:50%;padding:3px;
          background:linear-gradient(135deg,var(--accent),var(--accent-2));animation:pulse 2.2s infinite;}
        .logo-wrap img{width:100%;height:100%;border-radius:50%;object-fit:cover;background:#0b0f1a;}
        @keyframes pulse{0%,100%{box-shadow:0 0 0 0 rgba(108,92,231,.5);}50%{box-shadow:0 0 0 14px rgba(108,92,231,0);}}
        h1{font-size:26px;font-weight:700;margin-bottom:6px;}
        p.sub{color:var(--muted);font-size:14px;margin-bottom:28px;}
        .field{position:relative;margin-bottom:18px;text-align:left;}
        .field i.left-icon{position:absolute;left:14px;top:50%;transform:translateY(-50%);color:var(--muted);transition:color .2s;}
        .field input{
          width:100%;padding:13px 14px 13px 42px;border-radius:12px;border:1px solid var(--border);
          background:rgba(255,255,255,.04);color:var(--text);font-size:15px;transition:.25s;
        }
        .field input:focus{outline:none;border-color:var(--accent);background:rgba(255,255,255,.07);box-shadow:0 0 0 4px rgba(108,92,231,.15);}
        .field input:focus ~ i.left-icon, .field:focus-within i.left-icon{color:var(--accent-2);}
        .toggle-eye{position:absolute;right:14px;top:50%;transform:translateY(-50%);color:var(--muted);cursor:pointer;transition:.2s;}
        .toggle-eye:hover{color:var(--accent-2);transform:translateY(-50%) scale(1.15);}
        .btn{position:relative;overflow:hidden;}
        .ripple{position:absolute;border-radius:50%;background:rgba(255,255,255,.5);transform:scale(0);animation:rippleAnim .55s ease-out;pointer-events:none;}
        @keyframes rippleAnim{to{transform:scale(3);opacity:0;}}
        button.submit-btn{width:100%;padding:14px;font-size:16px;margin-top:6px;}
        .foot-note{margin-top:22px;font-size:12px;color:var(--muted);}
      </style>
    </head>
    <body>
      <div class="blob blob1"></div><div class="blob blob2"></div><div class="blob blob3"></div>
      <div class="login-card" data-aos="zoom-in">
        <div class="logo-wrap"><img src="/assets/logo.png" alt="Code Sync" onerror="this.style.display='none'"></div>
        <h1>Welcome <span class="grad-text">Back</span></h1>
        <p class="sub">Sign in to the Code Sync Admin Panel</p>
        <form id="loginForm">
          <div class="field">
            <i class="fa-solid fa-user left-icon"></i>
            <input type="text" name="username" id="username" placeholder="Username" required autocomplete="username">
          </div>
          <div class="field">
            <i class="fa-solid fa-lock left-icon"></i>
            <input type="password" name="password" id="password" placeholder="Password" required autocomplete="current-password">
            <i class="fa-solid fa-eye toggle-eye" onclick="togglePw()"></i>
          </div>
          <button type="submit" class="btn btn-primary submit-btn">
            <i class="fa-solid fa-right-to-bracket"></i> Login
          </button>
        </form>
        <div class="foot-note">Code Sync &copy; ${new Date().getFullYear()} — Secure Admin Access</div>
      </div>
      <script>
        AOS.init({ duration: 700, once: true });
        function togglePw(){
          const pw = document.getElementById('password');
          pw.type = pw.type === 'password' ? 'text' : 'password';
        }
        document.addEventListener('click', (e) => {
          const btn = e.target.closest('.btn');
          if (!btn) return;
          const rect = btn.getBoundingClientRect();
          const ripple = document.createElement('span');
          const size = Math.max(rect.width, rect.height);
          ripple.className = 'ripple';
          ripple.style.width = ripple.style.height = size + 'px';
          ripple.style.left = (e.clientX - rect.left - size / 2) + 'px';
          ripple.style.top = (e.clientY - rect.top - size / 2) + 'px';
          btn.appendChild(ripple);
          setTimeout(() => ripple.remove(), 550);
        });
        document.getElementById('loginForm').addEventListener('submit', async (e) => {
          e.preventDefault();
          const username = document.getElementById('username').value;
          const password = document.getElementById('password').value;
          const btn = e.target.querySelector('button');
          btn.disabled = true;
          btn.innerHTML = '<i class="fa-solid fa-spinner fa-spin"></i> Signing in...';
          try {
            const res = await fetch('/login', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ username, password }),
            });
            const data = await res.json();
            if (data.success) {
              window.location.href = '/home';
            } else {
              Swal.fire({ icon: 'error', title: 'Login failed', text: data.message || 'Invalid credentials', background: '#151c30', color: '#eef1f8' });
              btn.disabled = false;
              btn.innerHTML = '<i class="fa-solid fa-right-to-bracket"></i> Login';
            }
          } catch (err) {
            Swal.fire({ icon: 'error', title: 'Error', text: 'Something went wrong.', background: '#151c30', color: '#eef1f8' });
            btn.disabled = false;
            btn.innerHTML = '<i class="fa-solid fa-right-to-bracket"></i> Login';
          }
        });
      </script>
    </body>
    </html>
  `);
});

/* =========================================================
   LOGIN (checks MongoDB — which is kept in sync with .env)
   ========================================================= */
app.post('/login', async (req, res) => {
  try {
    await connectDB();
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ success: false, message: 'Username and password required' });
    }

    const admin = await Admin.findOne({ username });
    if (!admin) {
      return res.status(401).json({ success: false, message: 'Invalid Username or Password' });
    }

    const match = await bcrypt.compare(password, admin.password);
    if (!match) {
      return res.status(401).json({ success: false, message: 'Invalid Username or Password' });
    }

    req.session.loggedIn = true;
    req.session.username = admin.username;
    return res.json({ success: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

/* =========================================================
   ADD NEW ADMIN (new feature) — saved to MongoDB, hashed
   ========================================================= */
app.post('/add-admin', requireAuth, async (req, res) => {
  try {
    await connectDB();
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ success: false, message: 'Username and password are required' });
    }
    if (password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters' });
    }
    const existing = await Admin.findOne({ username });
    if (existing) {
      return res.status(409).json({ success: false, message: 'That username already exists' });
    }
    const hashed = await bcrypt.hash(password, 10);
    await Admin.create({ username, password: hashed, isEnvAdmin: false });
    return res.json({ success: true, message: 'Admin account created' });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

/* Delete an admin (cannot delete the env-seeded admin or yourself) */
app.post('/delete-admin/:id', requireAuth, async (req, res) => {
  try {
    await connectDB();
    const target = await Admin.findById(req.params.id);
    if (!target) return res.status(404).json({ success: false, message: 'Admin not found' });
    if (target.isEnvAdmin) {
      return res.status(403).json({ success: false, message: 'Cannot delete the primary env admin' });
    }
    if (target.username === req.session.username) {
      return res.status(403).json({ success: false, message: 'You cannot delete your own account' });
    }
    await Admin.findByIdAndDelete(req.params.id);
    return res.json({ success: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
});

/* =========================================================
   DELETE USER (unchanged behavior, now AJAX + protected)
   ========================================================= */
app.post('/delete-user/:id', requireAuth, async (req, res) => {
  try {
    await connectDB();
    await User.findByIdAndDelete(req.params.id);
    return res.json({ success: true });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Failed to delete user' });
  }
});

/* =========================================================
   DASHBOARD
   ========================================================= */
app.get('/home', requireAuth, async (req, res) => {
  try {
    await connectDB();
    const users = await User.find().sort({ _id: -1 });
    const totalUsers = users.length;

    const admins = await Admin.find().sort({ createdAt: -1 });
    const totalAdmins = admins.length;
    const envAdminCount = admins.filter(a => a.isEnvAdmin).length;
    const dbAdminCount = totalAdmins - envAdminCount;

    const chartData1 = {
      labels: ['Total Users', 'Total Admins'],
      datasets: [{
        label: 'Counts',
        data: [totalUsers, totalAdmins],
        backgroundColor: ['rgba(0,210,255,.65)', 'rgba(108,92,231,.65)'],
        borderColor: ['#00d2ff', '#6c5ce7'],
        borderWidth: 2,
        borderRadius: 10,
      }],
    };
    const chartData2 = {
      labels: ['.env Admins', 'Database Admins'],
      datasets: [{
        label: 'Admin Source',
        data: [envAdminCount, dbAdminCount],
        backgroundColor: ['rgba(255,200,87,.7)', 'rgba(0,210,255,.7)'],
        borderColor: ['#ffc857', '#00d2ff'],
        borderWidth: 2,
      }],
    };

    const usersRows = users.map((user, index) => `
      <tr data-aos="fade-up" data-aos-delay="${Math.min(index * 30, 300)}">
        <td class="text-center">${index + 1}</td>
        <td>${escapeHtml(user.name)}</td>
        <td class="text-center">${escapeHtml(user.email)}</td>
        <td class="text-center mono">${user.password ? escapeHtml(user.password.slice(0, Math.floor(user.password.length / 2))) + '&hellip;' : 'N/A'}</td>
        <td class="text-center"><span class="badge badge-active">Active</span></td>
        <td class="text-center">
          <button class="btn btn-danger" onclick="deleteUser('${user._id}', '${escapeHtml(user.name).replace(/'/g, "\\'")}')">
            <i class="fa-solid fa-trash"></i>
          </button>
        </td>
      </tr>`).join('');

    const adminsRows = admins.map((a, index) => `
      <tr data-aos="fade-up" data-aos-delay="${Math.min(index * 30, 300)}">
        <td class="text-center">${index + 1}</td>
        <td>${escapeHtml(a.username)}</td>
        <td class="text-center">${a.isEnvAdmin ? '<span class="badge badge-env">.env</span>' : '<span class="badge badge-db">Database</span>'}</td>
        <td class="text-center">${new Date(a.createdAt).toLocaleDateString()}</td>
        <td class="text-center">
          ${a.isEnvAdmin
            ? '<span class="muted-text">Protected</span>'
            : `<button class="btn btn-danger" onclick="deleteAdmin('${a._id}', '${escapeHtml(a.username).replace(/'/g, "\\'")}')"><i class="fa-solid fa-trash"></i></button>`}
        </td>
      </tr>`).join('');

    res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <title>Code Sync Admin Dashboard</title>
      ${sharedHead}
      <style>
        html{scroll-behavior:smooth;}
        body{display:flex;min-height:100vh;position:relative;overflow-x:hidden;background:var(--bg-1);}
        .bg-blob{position:fixed;border-radius:50%;filter:blur(100px);opacity:.22;z-index:0;pointer-events:none;animation:floatBlob 14s ease-in-out infinite;}
        .bg-blob.b1{width:420px;height:420px;background:var(--accent);top:-140px;left:10%;}
        .bg-blob.b2{width:380px;height:380px;background:var(--accent-2);bottom:-160px;right:5%;animation-delay:3s;}
        .bg-blob.b3{width:280px;height:280px;background:var(--accent-3);top:50%;left:60%;animation-delay:6s;}
        @keyframes floatBlob{0%,100%{transform:translateY(0) translateX(0) scale(1);}50%{transform:translateY(-40px) translateX(30px) scale(1.1);}}

        /* ---------- Sidebar ---------- */
        .sidebar{
          width:260px;background:var(--panel);border-right:1px solid var(--border);
          padding:24px 18px;position:fixed;top:0;left:0;bottom:0;z-index:50;
          display:flex;flex-direction:column;transition:transform .35s cubic-bezier(.4,0,.2,1);
        }
        .brand{display:flex;align-items:center;gap:10px;font-family:'Poppins',sans-serif;font-weight:700;font-size:20px;margin-bottom:34px;animation:slideDown .5s ease both;}
        .brand img{width:34px;height:34px;border-radius:8px;}
        @keyframes slideDown{from{opacity:0;transform:translateY(-14px);}to{opacity:1;transform:translateY(0);}}
        .nav-item{
          display:flex;align-items:center;gap:12px;padding:12px 14px;border-radius:12px;position:relative;
          color:var(--muted);font-weight:500;margin-bottom:6px;transition:.25s;cursor:pointer;overflow:hidden;
          animation:slideIn .45s ease both;
        }
        .nav-item:nth-child(2){animation-delay:.05s;} .nav-item:nth-child(3){animation-delay:.1s;} .nav-item:nth-child(4){animation-delay:.15s;}
        @keyframes slideIn{from{opacity:0;transform:translateX(-16px);}to{opacity:1;transform:translateX(0);}}
        .nav-item i{width:18px;text-align:center;transition:transform .25s;}
        .nav-item.active{background:linear-gradient(135deg,var(--accent),var(--accent-2));color:#fff;box-shadow:0 6px 18px rgba(108,92,231,.35);}
        .nav-item:not(.active):hover{background:rgba(255,255,255,.05);color:var(--text);transform:translateX(4px);}
        .nav-item:not(.active):hover i{transform:scale(1.15);}
        .sidebar-footer{margin-top:auto;padding-top:20px;border-top:1px solid var(--border);font-size:12px;color:var(--muted);}

        /* ---------- Topbar ---------- */
        .main{margin-left:260px;flex:1;min-width:0;transition:margin .3s ease;position:relative;z-index:1;}
        .topbar{
          position:sticky;top:0;z-index:40;display:flex;align-items:center;justify-content:space-between;
          padding:16px 28px;background:rgba(11,15,26,.7);backdrop-filter:blur(14px);border-bottom:1px solid var(--border);
          transition:box-shadow .3s ease, background .3s ease;
        }
        .topbar.scrolled{box-shadow:0 8px 24px rgba(0,0,0,.35);background:rgba(11,15,26,.92);}
        .hamburger{display:none;font-size:20px;cursor:pointer;background:none;border:none;color:var(--text);}
        .topbar h2{font-family:'Poppins',sans-serif;font-size:19px;display:flex;align-items:center;gap:10px;}
        .live-dot{width:8px;height:8px;border-radius:50%;background:var(--accent-3);box-shadow:0 0 0 0 rgba(0,229,160,.6);animation:pulseDot 1.8s infinite;}
        @keyframes pulseDot{0%{box-shadow:0 0 0 0 rgba(0,229,160,.55);}70%{box-shadow:0 0 0 9px rgba(0,229,160,0);}100%{box-shadow:0 0 0 0 rgba(0,229,160,0);}}
        .user-chip{display:flex;align-items:center;gap:10px;background:var(--panel-2);padding:8px 14px;border-radius:30px;border:1px solid var(--border);transition:.25s;}
        .user-chip:hover{border-color:var(--accent);box-shadow:0 0 0 3px rgba(108,92,231,.15);}
        .user-chip .avatar{width:30px;height:30px;border-radius:50%;background:linear-gradient(135deg,var(--accent),var(--accent-2));display:flex;align-items:center;justify-content:center;font-weight:700;font-size:13px;}
        .user-chip a{color:var(--danger);margin-left:6px;transition:.2s;}
        .user-chip a:hover{transform:scale(1.2);display:inline-block;}

        .content{padding:28px;max-width:1400px;animation:contentIn .6s cubic-bezier(.4,0,.2,1) both;}
        @keyframes contentIn{from{opacity:0;transform:translateY(18px);}to{opacity:1;transform:translateY(0);}}

        /* ---------- Stat cards ---------- */
        .stats-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:20px;margin-bottom:26px;}
        .stat-card{
          background:linear-gradient(155deg,var(--panel),var(--panel-2));border:1px solid var(--border);
          border-radius:var(--radius);padding:22px;position:relative;overflow:hidden;box-shadow:var(--shadow);
          transition:transform .35s cubic-bezier(.4,0,.2,1), box-shadow .35s ease, border-color .35s ease;
        }
        .stat-card::before{
          content:'';position:absolute;top:0;left:-75%;width:50%;height:100%;
          background:linear-gradient(120deg,transparent,rgba(255,255,255,.12),transparent);
          transform:skewX(-20deg);transition:left .6s ease;
        }
        .stat-card:hover::before{left:125%;}
        .stat-card:hover{transform:translateY(-8px) scale(1.015);box-shadow:0 16px 40px rgba(0,0,0,.4);border-color:rgba(255,255,255,.18);}
        .stat-card .icon-badge{
          width:46px;height:46px;border-radius:12px;display:flex;align-items:center;justify-content:center;
          font-size:18px;margin-bottom:14px;transition:transform .35s ease;
        }
        .stat-card:hover .icon-badge{transform:rotate(-8deg) scale(1.1);}
        .stat-card .num{font-size:30px;font-weight:800;font-family:'Poppins',sans-serif;}
        .stat-card .label{color:var(--muted);font-size:13px;margin-top:2px;}
        .stat-card .glow{position:absolute;width:130px;height:130px;border-radius:50%;filter:blur(60px);opacity:.35;top:-40px;right:-40px;transition:opacity .35s ease;}
        .stat-card:hover .glow{opacity:.55;}
        .c1 .icon-badge{background:rgba(0,210,255,.15);color:var(--accent-2);} .c1 .glow{background:var(--accent-2);}
        .c2 .icon-badge{background:rgba(108,92,231,.15);color:var(--accent);} .c2 .glow{background:var(--accent);}
        .c3 .icon-badge{background:rgba(0,229,160,.15);color:var(--accent-3);} .c3 .glow{background:var(--accent-3);}

        /* ---------- Panels / Cards ---------- */
        .panel{background:var(--panel);border:1px solid var(--border);border-radius:var(--radius);box-shadow:var(--shadow);margin-bottom:24px;overflow:hidden;position:relative;transition:border-color .3s ease, transform .3s ease;}
        .panel::after{content:'';position:absolute;top:0;left:0;right:0;height:2px;background:linear-gradient(90deg,var(--accent),var(--accent-2),var(--accent-3));background-size:200% 100%;animation:gradientSlide 5s linear infinite;}
        @keyframes gradientSlide{0%{background-position:0% 0;}100%{background-position:200% 0;}}
        .panel:hover{border-color:rgba(255,255,255,.16);}
        .panel-header{display:flex;align-items:center;justify-content:space-between;padding:18px 22px;border-bottom:1px solid var(--border);}
        .panel-header h3{font-family:'Poppins',sans-serif;font-size:16px;display:flex;align-items:center;gap:10px;}
        .panel-body{padding:22px;}
        .charts-grid{display:grid;grid-template-columns:1.3fr 1fr;gap:20px;margin-bottom:24px;}
        @media(max-width:1000px){.charts-grid{grid-template-columns:1fr;}}

        table{width:100%;border-collapse:collapse;font-size:14px;}
        thead th{text-align:left;color:var(--muted);font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.5px;padding:10px 12px;border-bottom:1px solid var(--border);}
        tbody td{padding:12px;border-bottom:1px solid var(--border);}
        tbody tr{transition:background .2s ease, transform .2s ease;}
        tbody tr:hover{background:rgba(255,255,255,.04);transform:scale(1.005);}
        .text-center{text-align:center;}
        .mono{font-family:monospace;color:var(--muted);}
        .table-scroll{overflow-x:auto;max-height:420px;overflow-y:auto;}
        .badge{padding:4px 10px;border-radius:20px;font-size:11px;font-weight:700;transition:transform .2s ease;}
        tr:hover .badge{transform:scale(1.06);}
        .badge-active{background:rgba(0,229,160,.15);color:var(--accent-3);}
        .badge-env{background:rgba(255,200,87,.15);color:var(--warn);}
        .badge-db{background:rgba(0,210,255,.15);color:var(--accent-2);}
        .muted-text{color:var(--muted);font-size:12px;}

        /* ---------- Add Admin form ---------- */
        .add-admin-form{display:flex;gap:14px;flex-wrap:wrap;align-items:flex-end;}
        .form-group{flex:1;min-width:180px;display:flex;flex-direction:column;gap:6px;}
        .form-group label{font-size:12px;color:var(--muted);}
        .form-group input{padding:11px 14px;border-radius:10px;border:1px solid var(--border);background:rgba(255,255,255,.04);color:var(--text);transition:.2s;}
        .form-group input:focus{outline:none;border-color:var(--accent);box-shadow:0 0 0 3px rgba(108,92,231,.15);}

        /* ---------- Buttons: ripple + micro-interactions ---------- */
        .btn{position:relative;overflow:hidden;}
        .ripple{position:absolute;border-radius:50%;background:rgba(255,255,255,.5);transform:scale(0);animation:rippleAnim .55s ease-out;pointer-events:none;}
        @keyframes rippleAnim{to{transform:scale(3);opacity:0;}}

        /* ---------- Back to top ---------- */
        .back-to-top{
          position:fixed;bottom:24px;right:24px;width:46px;height:46px;border-radius:50%;
          background:linear-gradient(135deg,var(--accent),var(--accent-2));color:#fff;display:flex;
          align-items:center;justify-content:center;box-shadow:0 8px 24px rgba(108,92,231,.4);
          cursor:pointer;opacity:0;pointer-events:none;transform:translateY(20px) scale(.8);
          transition:.3s ease;z-index:60;
        }
        .back-to-top.show{opacity:1;pointer-events:auto;transform:translateY(0) scale(1);}
        .back-to-top:hover{transform:translateY(-4px) scale(1.05);}

        /* ---------- Mobile ---------- */
        .overlay{display:none;position:fixed;inset:0;background:rgba(0,0,0,.5);z-index:45;}
        @media(max-width:900px){
          .sidebar{transform:translateX(-100%);}
          .sidebar.open{transform:translateX(0);}
          .main{margin-left:0;}
          .hamburger{display:block;}
          .overlay.show{display:block;}
          .charts-grid{grid-template-columns:1fr;}
          .content{padding:18px;}
        }
      </style>
    </head>
    <body>
      <div class="bg-blob b1"></div><div class="bg-blob b2"></div><div class="bg-blob b3"></div>
      <div class="overlay" id="overlay" onclick="toggleSidebar()"></div>

      <aside class="sidebar" id="sidebar">
        <div class="brand"><img src="/assets/logo.png" onerror="this.style.display='none'"> Code <span class="grad-text">Sync</span></div>
        <div class="nav-item active"><i class="fa-solid fa-gauge-high"></i> Dashboard</div>
        <div class="nav-item" onclick="document.getElementById('usersPanel').scrollIntoView({behavior:'smooth'})"><i class="fa-solid fa-users"></i> Users</div>
        <div class="nav-item" onclick="document.getElementById('adminsPanel').scrollIntoView({behavior:'smooth'})"><i class="fa-solid fa-user-shield"></i> Admins</div>
        <div class="sidebar-footer">
          Code Sync Private Limited<br>
          <span style="color:var(--accent-2)">v2.0</span> &middot; Admin Panel
        </div>
      </aside>

      <div class="main">
        <div class="topbar" id="topbar">
          <div style="display:flex;align-items:center;gap:14px;">
            <button class="hamburger" onclick="toggleSidebar()"><i class="fa-solid fa-bars"></i></button>
            <h2><span class="live-dot"></span> Dashboard <span class="grad-text">Overview</span></h2>
          </div>
          <div class="user-chip">
            <div class="avatar">${escapeHtml((req.session.username || 'A').charAt(0).toUpperCase())}</div>
            <span>${escapeHtml(req.session.username)}</span>
            <a href="#" onclick="logout(event)"><i class="fa-solid fa-right-from-bracket"></i></a>
          </div>
        </div>

        <div class="content">
          <div class="stats-grid">
            <div class="stat-card c1" data-aos="fade-up">
              <div class="glow"></div>
              <div class="icon-badge"><i class="fa-solid fa-users"></i></div>
              <div class="num" data-count="${totalUsers}">0</div>
              <div class="label">Total Users</div>
            </div>
            <div class="stat-card c2" data-aos="fade-up" data-aos-delay="100">
              <div class="glow"></div>
              <div class="icon-badge"><i class="fa-solid fa-user-shield"></i></div>
              <div class="num" data-count="${totalAdmins}">0</div>
              <div class="label">Total Admins</div>
            </div>
            <div class="stat-card c3" data-aos="fade-up" data-aos-delay="200">
              <div class="glow"></div>
              <div class="icon-badge"><i class="fa-solid fa-database"></i></div>
              <div class="num" data-count="${dbAdminCount}">0</div>
              <div class="label">Admins Added via Panel</div>
            </div>
          </div>

          <div class="charts-grid">
            <div class="panel" data-aos="fade-up">
              <div class="panel-header"><h3><i class="fa-solid fa-chart-column grad-text"></i> Users vs Admins</h3></div>
              <div class="panel-body"><canvas id="salesChartCanvas" height="140"></canvas></div>
            </div>
            <div class="panel" data-aos="fade-up" data-aos-delay="100">
              <div class="panel-header"><h3><i class="fa-solid fa-chart-pie grad-text"></i> Admin Source Breakdown</h3></div>
              <div class="panel-body"><canvas id="comparisonChartCanvas" height="140"></canvas></div>
            </div>
          </div>

          <div class="panel" id="adminsPanel" data-aos="fade-up">
            <div class="panel-header"><h3><i class="fa-solid fa-user-shield grad-text"></i> Admin Accounts</h3></div>
            <div class="panel-body">
              <form class="add-admin-form" id="addAdminForm">
                <div class="form-group">
                  <label>New Username</label>
                  <input type="text" id="newAdminUsername" required placeholder="e.g. zaibten2">
                </div>
                <div class="form-group">
                  <label>New Password</label>
                  <input type="password" id="newAdminPassword" required placeholder="min 6 characters">
                </div>
                <button type="submit" class="btn btn-primary"><i class="fa-solid fa-user-plus"></i> Add Admin</button>
              </form>
              <div class="table-scroll" style="margin-top:20px;">
                <table>
                  <thead><tr><th class="text-center">#</th><th>Username</th><th class="text-center">Source</th><th class="text-center">Created</th><th class="text-center">Actions</th></tr></thead>
                  <tbody id="adminsTbody">${adminsRows}</tbody>
                </table>
              </div>
            </div>
          </div>

          <div class="panel" id="usersPanel" data-aos="fade-up">
            <div class="panel-header"><h3><i class="fa-solid fa-users grad-text"></i> Code Sync Users</h3></div>
            <div class="panel-body">
              <div class="table-scroll">
                <table>
                  <thead>
                    <tr>
                      <th class="text-center">#</th><th>Username</th><th class="text-center">Email</th>
                      <th class="text-center">Password (Encrypted)</th><th class="text-center">Status</th><th class="text-center">Actions</th>
                    </tr>
                  </thead>
                  <tbody id="usersTbody">${usersRows || '<tr><td colspan="6" class="text-center muted-text" style="padding:24px;">No users yet</td></tr>'}</tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="back-to-top" id="backToTop" onclick="window.scrollTo({top:0,behavior:'smooth'})">
        <i class="fa-solid fa-arrow-up"></i>
      </div>

      <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
      <script>
        AOS.init({ duration: 600, once: true, easing: 'ease-out-cubic' });

        // sidebar toggle (mobile)
        function toggleSidebar(){
          document.getElementById('sidebar').classList.toggle('open');
          document.getElementById('overlay').classList.toggle('show');
        }

        // topbar shadow + back-to-top on scroll
        window.addEventListener('scroll', () => {
          const y = window.scrollY;
          document.getElementById('topbar').classList.toggle('scrolled', y > 8);
          document.getElementById('backToTop').classList.toggle('show', y > 300);
        });

        // button ripple micro-interaction
        document.addEventListener('click', (e) => {
          const btn = e.target.closest('.btn');
          if (!btn) return;
          const rect = btn.getBoundingClientRect();
          const ripple = document.createElement('span');
          const size = Math.max(rect.width, rect.height);
          ripple.className = 'ripple';
          ripple.style.width = ripple.style.height = size + 'px';
          ripple.style.left = (e.clientX - rect.left - size / 2) + 'px';
          ripple.style.top = (e.clientY - rect.top - size / 2) + 'px';
          btn.appendChild(ripple);
          setTimeout(() => ripple.remove(), 550);
        });

        // animated counters
        document.querySelectorAll('.num[data-count]').forEach(el => {
          const target = parseInt(el.getAttribute('data-count'), 10) || 0;
          let current = 0;
          const step = Math.max(1, Math.ceil(target / 40));
          const timer = setInterval(() => {
            current += step;
            if (current >= target) { current = target; clearInterval(timer); }
            el.textContent = current;
          }, 25);
        });

        Chart.defaults.color = '#8b93a7';
        Chart.defaults.borderColor = 'rgba(255,255,255,.08)';
        Chart.defaults.font.family = "'Inter', sans-serif";

        const barCtx = document.getElementById('salesChartCanvas').getContext('2d');
        const barGradient1 = barCtx.createLinearGradient(0, 0, 0, 260);
        barGradient1.addColorStop(0, 'rgba(0,210,255,.75)');
        barGradient1.addColorStop(1, 'rgba(0,210,255,.05)');
        const barGradient2 = barCtx.createLinearGradient(0, 0, 0, 260);
        barGradient2.addColorStop(0, 'rgba(108,92,231,.75)');
        barGradient2.addColorStop(1, 'rgba(108,92,231,.05)');
        const barData = ${JSON.stringify(chartData1)};
        barData.datasets[0].backgroundColor = [barGradient1, barGradient2];
        barData.datasets[0].hoverBackgroundColor = ['rgba(0,210,255,.9)', 'rgba(108,92,231,.9)'];

        new Chart(barCtx, {
          type: 'bar',
          data: barData,
          options: {
            responsive: true,
            animation: { duration: 1400, easing: 'easeOutQuart' },
            scales: { y: { beginAtZero: true, grid: { color: 'rgba(255,255,255,.06)' } }, x: { grid: { display: false } } },
            plugins: { legend: { display: false } },
          },
        });

        new Chart(document.getElementById('comparisonChartCanvas'), {
          type: 'doughnut',
          data: ${JSON.stringify(chartData2)},
          options: {
            responsive: true,
            animation: { duration: 1400, easing: 'easeOutQuart', animateRotate: true, animateScale: true },
            plugins: { legend: { position: 'bottom' } },
            cutout: '65%',
          },
        });

        function toast(icon, title) {
          Swal.fire({ icon, title, toast: true, position: 'top-end', timer: 2500, showConfirmButton: false, background: '#151c30', color: '#eef1f8' });
        }

        async function logout(e) {
          e.preventDefault();
          const result = await Swal.fire({
            title: 'Log out?', icon: 'question', showCancelButton: true,
            confirmButtonText: 'Yes, log out', background: '#151c30', color: '#eef1f8',
            confirmButtonColor: '#6c5ce7',
          });
          if (result.isConfirmed) {
            await fetch('/logout', { method: 'POST' });
            window.location.href = '/';
          }
        }

        document.getElementById('addAdminForm').addEventListener('submit', async (e) => {
          e.preventDefault();
          const username = document.getElementById('newAdminUsername').value.trim();
          const password = document.getElementById('newAdminPassword').value;
          const btn = e.target.querySelector('button');
          btn.disabled = true;
          try {
            const res = await fetch('/add-admin', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({ username, password }),
            });
            const data = await res.json();
            if (data.success) {
              toast('success', 'Admin added');
              setTimeout(() => window.location.reload(), 900);
            } else {
              toast('error', data.message || 'Failed to add admin');
            }
          } catch (err) {
            toast('error', 'Something went wrong');
          } finally {
            btn.disabled = false;
          }
        });

        async function deleteUser(id, name) {
          const result = await Swal.fire({
            title: 'Delete user?', text: name ? \`This will remove "\${name}" permanently.\` : undefined,
            icon: 'warning', showCancelButton: true, confirmButtonText: 'Delete',
            confirmButtonColor: '#ff5f6d', background: '#151c30', color: '#eef1f8',
          });
          if (!result.isConfirmed) return;
          const res = await fetch('/delete-user/' + id, { method: 'POST' });
          const data = await res.json();
          if (data.success) { toast('success', 'User deleted'); setTimeout(() => window.location.reload(), 700); }
          else toast('error', data.message || 'Failed to delete');
        }

        async function deleteAdmin(id, name) {
          const result = await Swal.fire({
            title: 'Remove admin?', text: name ? \`This will revoke access for "\${name}".\` : undefined,
            icon: 'warning', showCancelButton: true, confirmButtonText: 'Remove',
            confirmButtonColor: '#ff5f6d', background: '#151c30', color: '#eef1f8',
          });
          if (!result.isConfirmed) return;
          const res = await fetch('/delete-admin/' + id, { method: 'POST' });
          const data = await res.json();
          if (data.success) { toast('success', 'Admin removed'); setTimeout(() => window.location.reload(), 700); }
          else toast('error', data.message || 'Failed to remove');
        }
      </script>
    </body>
    </html>
    `);
  } catch (error) {
    console.error(error);
    res.status(500).send('Error fetching dashboard data');
  }
});

/* =========================================================
   LOGOUT
   ========================================================= */
app.post('/logout', (req, res) => {
  req.session.destroy(() => res.json({ success: true }));
});
app.get('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/'));
});

/* =========================================================
   START SERVER
   ========================================================= */
app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});

module.exports = app;