const dns = require('dns');
dns.setServers(['8.8.8.8', '8.8.4.4']);
const path = require('path');
const dotenv = require('dotenv');
const mongoose = require('mongoose');

dotenv.config({ path: path.join(__dirname, '../.env') });

const User = require('../src/models/User');

async function ensureAdmin() {
  try {
    console.log('[Admin Setup] Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('[Admin Setup] Connected to MongoDB.');

    const adminEmail = 'admin@sahyan.app';
    const plainPassword = 'AdminPassword123!';

    let admin = await User.findOne({ email: adminEmail }).select('+password');

    if (!admin) {
      console.log('[Admin Setup] Creating root admin user...');
      admin = await User.create({
        name: 'Sahyān SuperAdmin',
        email: adminEmail,
        phone: '+919999988888',
        password: plainPassword,
        role: 'admin',
        city: 'Ahmedabad',
        isVerified: true,
        capabilities: { canRide: true, canDrive: true },
      });
      console.log('[Admin Setup] Admin user created successfully with ID:', admin._id);
    } else {
      console.log('[Admin Setup] Admin user already exists. Updating credentials and role...');
      admin.name = 'Sahyān SuperAdmin';
      admin.role = 'admin';
      admin.isVerified = true;
      admin.password = plainPassword; // Triggers pre-save bcrypt hook
      await admin.save();
      console.log('[Admin Setup] Admin user credentials reset successfully.');
    }

    console.log('\n--- ADMIN CREDENTIALS ---');
    console.log('Email:    ' + adminEmail);
    console.log('Password: ' + plainPassword);
    console.log('Role:     ' + admin.role);
    console.log('Status:   Active & Verified');
    console.log('-------------------------\n');

    await mongoose.disconnect();
    console.log('[Admin Setup] Done.');
    process.exit(0);
  } catch (err) {
    console.error('[Admin Setup] Error:', err);
    process.exit(1);
  }
}

ensureAdmin();
