// Device Routes
const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const Device = require('../models/Device');
const User = require('../models/User');
const authMiddleware = require('../middleware/auth');

// All routes require authentication
router.use(authMiddleware);

// Register Device
router.post('/register', [
  body('deviceId').trim().notEmpty().withMessage('Device ID is required'),
  body('name').trim().notEmpty().withMessage('Device name is required'),
  body('location').trim().notEmpty().withMessage('Location is required'),
  body('latitude').isFloat().withMessage('Valid latitude is required'),
  body('longitude').isFloat().withMessage('Valid longitude is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: errors.array()[0].msg
      });
    }

    const { deviceId, name, type, location, latitude, longitude } = req.body;

    // Check if device already exists
    const existingDevice = await Device.findByDeviceId(deviceId);
    if (existingDevice) {
      return res.status(400).json({
        success: false,
        message: 'Device ID already registered'
      });
    }

    // Check device limit
    const deviceCount = await User.getDeviceCount(req.user.id);
    const maxDevices = parseInt(process.env.MAX_DEVICES_PER_USER) || 10;
    
    if (deviceCount >= maxDevices) {
      return res.status(400).json({
        success: false,
        message: `Maximum device limit (${maxDevices}) reached`
      });
    }

    // Create device
    const device = await Device.create({
      deviceId,
      name,
      type,
      location,
      latitude,
      longitude,
      ownerId: req.user.id
    });

    res.status(201).json({
      success: true,
      message: 'Device registered successfully',
      device
    });
  } catch (error) {
    console.error('Register device error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to register device'
    });
  }
});

// Get User Devices
router.get('/user', async (req, res) => {
  try {
    const devices = await Device.findByOwner(req.user.id);

    res.json({
      success: true,
      devices
    });
  } catch (error) {
    console.error('Get devices error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get devices'
    });
  }
});

// Get Device Details
router.get('/:id', async (req, res) => {
  try {
    const device = await Device.findById(req.params.id);

    if (!device) {
      return res.status(404).json({
        success: false,
        message: 'Device not found'
      });
    }

    // Check ownership
    if (device.owner_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      device
    });
  } catch (error) {
    console.error('Get device error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get device'
    });
  }
});

// Update Device
router.put('/:id', [
  body('name').trim().notEmpty().withMessage('Device name is required'),
  body('location').trim().notEmpty().withMessage('Location is required'),
  body('latitude').isFloat().withMessage('Valid latitude is required'),
  body('longitude').isFloat().withMessage('Valid longitude is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: errors.array()[0].msg
      });
    }

    const device = await Device.findById(req.params.id);

    if (!device) {
      return res.status(404).json({
        success: false,
        message: 'Device not found'
      });
    }

    // Check ownership
    if (device.owner_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const { name, location, latitude, longitude } = req.body;
    const updatedDevice = await Device.update(req.params.id, {
      name,
      location,
      latitude,
      longitude
    });

    res.json({
      success: true,
      message: 'Device updated successfully',
      device: updatedDevice
    });
  } catch (error) {
    console.error('Update device error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update device'
    });
  }
});

// Delete Device
router.delete('/:id', async (req, res) => {
  try {
    const device = await Device.findById(req.params.id);

    if (!device) {
      return res.status(404).json({
        success: false,
        message: 'Device not found'
      });
    }

    // Check ownership
    if (device.owner_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    await Device.delete(req.params.id);

    res.json({
      success: true,
      message: 'Device deleted successfully'
    });
  } catch (error) {
    console.error('Delete device error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete device'
    });
  }
});

// Get Device Status
router.get('/:id/status', async (req, res) => {
  try {
    const device = await Device.findById(req.params.id);

    if (!device) {
      return res.status(404).json({
        success: false,
        message: 'Device not found'
      });
    }

    // Check ownership
    if (device.owner_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const now = new Date();
    const lastSeen = new Date(device.last_seen);
    const minutesSinceLastSeen = (now - lastSeen) / 1000 / 60;

    res.json({
      success: true,
      status: {
        deviceId: device.device_id,
        online: minutesSinceLastSeen < 10, // Consider online if seen in last 10 minutes
        lastSeen: device.last_seen,
        status: device.status,
        batteryLevel: 85, // Mock data - would come from device
        signalStrength: -45, // Mock data
        firmware: '1.2.3' // Mock data
      }
    });
  } catch (error) {
    console.error('Get device status error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get device status'
    });
  }
});

// Transfer Device Ownership
router.put('/:id/transfer', [
  body('newOwnerEmail').isEmail().withMessage('Valid email is required'),
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: errors.array()[0].msg
      });
    }

    const device = await Device.findById(req.params.id);

    if (!device) {
      return res.status(404).json({
        success: false,
        message: 'Device not found'
      });
    }

    // Check ownership
    if (device.owner_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Find new owner
    const newOwner = await User.findByEmail(req.body.newOwnerEmail);
    if (!newOwner) {
      return res.status(404).json({
        success: false,
        message: 'New owner not found'
      });
    }

    // Check new owner's device limit
    const newOwnerDeviceCount = await User.getDeviceCount(newOwner.id);
    const maxDevices = parseInt(process.env.MAX_DEVICES_PER_USER) || 10;
    
    if (newOwnerDeviceCount >= maxDevices) {
      return res.status(400).json({
        success: false,
        message: 'New owner has reached maximum device limit'
      });
    }

    // Transfer ownership
    const updatedDevice = await Device.transferOwnership(req.params.id, newOwner.id);

    res.json({
      success: true,
      message: 'Device ownership transferred successfully',
      device: updatedDevice
    });
  } catch (error) {
    console.error('Transfer device error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to transfer device'
    });
  }
});

// Get Device Statistics
router.get('/:id/statistics', async (req, res) => {
  try {
    const device = await Device.findById(req.params.id);

    if (!device) {
      return res.status(404).json({
        success: false,
        message: 'Device not found'
      });
    }

    // Check ownership
    if (device.owner_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const { startDate, endDate } = req.query;
    const stats = await Device.getStatistics(device.device_id, startDate, endDate);

    res.json({
      success: true,
      statistics: {
        deviceId: device.device_id,
        totalEvents: parseInt(stats.total_events) || 0,
        averageMagnitude: parseFloat(stats.avg_magnitude) || 0,
        maxMagnitude: parseFloat(stats.max_magnitude) || 0,
        minMagnitude: parseFloat(stats.min_magnitude) || 0,
        uptime: 98.5, // Mock data
        lastEvent: device.last_seen
      }
    });
  } catch (error) {
    console.error('Get device statistics error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get device statistics'
    });
  }
});

module.exports = router;
