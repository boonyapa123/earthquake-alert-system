// Earthquake Events Routes
const express = require('express');
const router = express.Router();
const EarthquakeEvent = require('../models/EarthquakeEvent');
const Device = require('../models/Device');
const authMiddleware = require('../middleware/auth');

// All routes require authentication
router.use(authMiddleware);

// Get Earthquake Events (with filtering and pagination)
router.get('/earthquake', async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      deviceId,
      startDate,
      endDate,
      minMagnitude
    } = req.query;

    const result = await EarthquakeEvent.findAll({
      page: parseInt(page),
      limit: parseInt(limit),
      deviceId,
      startDate,
      endDate,
      minMagnitude: minMagnitude ? parseFloat(minMagnitude) : null
    });

    // Filter events to only show user's devices
    const userDevices = await Device.findByOwner(req.user.id);
    const userDeviceIds = userDevices.map(d => d.device_id);
    
    const filteredEvents = result.events.filter(event => 
      userDeviceIds.includes(event.device_id) || event.owner_id === req.user.id
    );

    res.json({
      success: true,
      events: filteredEvents,
      pagination: result.pagination
    });
  } catch (error) {
    console.error('Get events error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get events'
    });
  }
});

// Get Event Details
router.get('/:id', async (req, res) => {
  try {
    const event = await EarthquakeEvent.findById(req.params.id);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found'
      });
    }

    // Check if user owns the device
    const device = await Device.findByDeviceId(event.device_id);
    if (device && device.owner_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    res.json({
      success: true,
      event
    });
  } catch (error) {
    console.error('Get event error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get event'
    });
  }
});

// Report False Positive
router.put('/:id/report-false-positive', async (req, res) => {
  try {
    const event = await EarthquakeEvent.findById(req.params.id);

    if (!event) {
      return res.status(404).json({
        success: false,
        message: 'Event not found'
      });
    }

    // Check if user owns the device
    const device = await Device.findByDeviceId(event.device_id);
    if (device && device.owner_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    const updatedEvent = await EarthquakeEvent.reportFalsePositive(req.params.id);

    res.json({
      success: true,
      message: 'Event reported as false positive',
      event: updatedEvent
    });
  } catch (error) {
    console.error('Report false positive error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to report false positive'
    });
  }
});

// Get Recent Alerts
router.get('/alerts/recent', async (req, res) => {
  try {
    const limit = parseInt(req.query.limit) || 10;
    const alerts = await EarthquakeEvent.getRecentAlerts(limit);

    // Filter to user's devices
    const userDevices = await Device.findByOwner(req.user.id);
    const userDeviceIds = userDevices.map(d => d.device_id);
    
    const filteredAlerts = alerts.filter(alert => 
      userDeviceIds.includes(alert.device_id)
    );

    res.json({
      success: true,
      alerts: filteredAlerts
    });
  } catch (error) {
    console.error('Get recent alerts error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get recent alerts'
    });
  }
});

module.exports = router;
