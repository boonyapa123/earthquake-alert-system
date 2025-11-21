// User Model (MongoDB)
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

// User Schema
const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: true
  },
  phone: {
    type: String,
    required: true
  },
  address: {
    type: String,
    default: ''
  },
  devices: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Device'
  }],
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Create model
const UserModel = mongoose.model('User', userSchema);

// User class with static methods (compatible with existing code)
class User {
  static async create({ name, email, password, phone, address }) {
    const hashedPassword = await bcrypt.hash(password, parseInt(process.env.BCRYPT_ROUNDS) || 10);
    
    const user = new UserModel({
      name,
      email,
      password: hashedPassword,
      phone,
      address: address || ''
    });
    
    await user.save();
    
    return {
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      phone: user.phone,
      address: user.address,
      created_at: user.createdAt
    };
  }

  static async findByEmail(email) {
    const user = await UserModel.findOne({ email: email.toLowerCase() });
    if (!user) return null;
    
    return {
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      password: user.password,
      phone: user.phone,
      address: user.address,
      created_at: user.createdAt,
      updated_at: user.updatedAt
    };
  }

  static async findById(id) {
    const user = await UserModel.findById(id);
    if (!user) return null;
    
    return {
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      phone: user.phone,
      address: user.address,
      created_at: user.createdAt,
      updated_at: user.updatedAt
    };
  }

  static async update(id, { name, phone, address }) {
    const user = await UserModel.findByIdAndUpdate(
      id,
      { 
        name, 
        phone, 
        address,
        updatedAt: new Date()
      },
      { new: true }
    );
    
    if (!user) return null;
    
    return {
      id: user._id.toString(),
      name: user.name,
      email: user.email,
      phone: user.phone,
      address: user.address,
      updated_at: user.updatedAt
    };
  }

  static async updatePassword(id, newPassword) {
    const hashedPassword = await bcrypt.hash(newPassword, parseInt(process.env.BCRYPT_ROUNDS) || 10);
    
    await UserModel.findByIdAndUpdate(id, { 
      password: hashedPassword,
      updatedAt: new Date()
    });
    
    return true;
  }

  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  static async delete(id) {
    await UserModel.findByIdAndDelete(id);
    return true;
  }

  static async getDeviceCount(userId) {
    const user = await UserModel.findById(userId);
    return user ? user.devices.length : 0;
  }
}

module.exports = User;
