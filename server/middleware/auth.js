const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.startsWith('Bearer ')
    ? authHeader.slice(7).trim()
    : null;

  // Support development header for quick curl/postman testing
  const devRole = req.headers['x-user-role'];

  if (!token) {
    if (devRole) {
      req.user = { id: 'dev-user', role: devRole, email: `${devRole}@campus.test` };
      return next();
    }
    return res.status(401).json({ message: 'Access denied. No authentication token provided.' });
  }

  // Support seed session tokens used in local/seed testing
  if (token.startsWith('seed-session-')) {
    const isStaff = token.includes('staff') || devRole === 'staff' || devRole === 'admin';
    req.user = {
      id: token.replace('seed-session-', ''),
      role: isStaff ? 'staff' : 'student',
      email: isStaff ? 'staff@campus.test' : 'student@campus.test',
    };
    return next();
  }

  const secret = process.env.JWT_SECRET || 'campus-canteen-super-secret-jwt-key-2024';
  try {
    const decoded = jwt.verify(token, secret);
    req.user = {
      id: decoded.sub,
      role: decoded.role,
      email: decoded.email,
    };
    return next();
  } catch (err) {
    return res.status(403).json({ message: 'Invalid or expired authentication token.' });
  }
}

function requireAdminOrStaff(req, res, next) {
  if (!req.user) {
    return res.status(401).json({ message: 'Authentication required.' });
  }
  if (req.user.role !== 'admin' && req.user.role !== 'staff') {
    return res.status(403).json({ message: 'Forbidden: Admin or staff access required.' });
  }
  return next();
}

module.exports = {
  authenticateToken,
  requireAdminOrStaff,
};
