const jsonServer = require('json-server');
const path = require('path');
const fs = require('fs');

// Create server
const server = jsonServer.create();
const middlewares = jsonServer.defaults();

// Load routes
const routes = require('./routes.json');

// ============================================
// CUSTOM EXTRA BREAK HANDLER
// ============================================
server.post('/api/attendance/mark/break/extra', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/attendance/mark/break/extra (custom handler)`);
  
  const extraBreaks = require('./data/extra-breaks.json');
  res.status(200).json(extraBreaks[0]);
});

server.post('/extraBreaks', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /extraBreaks (custom handler)`);
  
  const extraBreaks = require('./data/extra-breaks.json');
  res.status(200).json(extraBreaks[0]);
});

// Load data from separate files
const loadData = () => {
  const dataConfig = require('./db.json');
  const data = {};
  
  Object.keys(dataConfig).forEach(key => {
    const filename = dataConfig[key];
    const filepath = path.join(__dirname, 'data', filename);
    if (fs.existsSync(filepath)) {
      const fileContent = fs.readFileSync(filepath, 'utf8');
      const fileData = JSON.parse(fileContent);
      
      // Determine if the file contains an array or object
      if (Array.isArray(fileData)) {
        data[key] = fileData;
      } else if (typeof fileData === 'object') {
        data[key] = fileData;
      } else {
        console.warn(`Warning: Data in "${filename}" is not an object or array`);
        data[key] = [];
      }
    } else {
      console.warn(`Warning: File not found for key "${key}": ${filepath}`);
      data[key] = [];
    }
  });
  
  // Special handling for login (auth.login structure)
  if (data.login && typeof data.login === 'object' && !Array.isArray(data.login)) {
    if (data.login.login) {
      data.login = data.login.login;
    }
  }
  
  return data;
};

const db = loadData();
const router = jsonServer.router(db);

// Set up middlewares
server.use(middlewares);
server.use(jsonServer.bodyParser);

// CORS middleware
server.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// ============================================
// CUSTOM LOGIN HANDLER - MUST BE BEFORE REWRITER
// ============================================
// Handle both /login and /api/login BEFORE the rewriter processes them

server.post('/login', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /login (custom handler)`);
  console.log('  → Email:', req.body?.email);
  
  if (db.login) {
    console.log('  → Returning login response:', JSON.stringify(db.login));
    res.status(200).json(db.login);
  } else {
    console.log('  → No login data available');
    res.status(500).json({ error: 'Login data not found' });
  }
});

// ============================================
// TASK MANAGEMENT CUSTOM HANDLERS
// ============================================
server.post('/api/employee/tasks', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/tasks (custom handler)`);
  console.log('  → User ID:', req.body?.user_id);
  
  // Return tasks data with proper structure
  const tasksData = require('./data/tasks.json');
  res.status(200).json(tasksData[0]);
});

server.post('/api/employee/tasks/statistics', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/tasks/statistics (custom handler)`);
  console.log('  → User ID:', req.body?.user_id);
  
  // Return task statistics
  const taskStats = require('./data/task-statistics.json');
  res.status(200).json(taskStats[0]);
});

// Get task by ID handler
server.get('/api/employee/tasks/:taskId', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  console.log(`[${timestamp}] GET /api/employee/tasks/${taskId} (custom handler)`);
  
  const tasksData = require('./data/tasks.json');
  const taskDetails = require('./data/get-task-by-id.json');
  
  res.status(200).json(taskDetails);
});

// Time logs handlers
server.get('/api/employee/tasks/:taskId/time-logs', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  console.log(`[${timestamp}] GET /api/employee/tasks/${taskId}/time-logs (custom handler)`);
  
  const timeLogs = require('./data/time-logs.json');
  res.status(200).json(timeLogs);
});

server.post('/api/employee/tasks/:taskId/time-logs/start', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  console.log(`[${timestamp}] POST /api/employee/tasks/${taskId}/time-logs/start (custom handler)`);
  
  const startTimeTracking = require('./data/start-time-tracking.json');
  res.status(200).json(startTimeTracking);
});

server.post('/api/employee/tasks/:taskId/time-logs/:timeLogId/stop', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  const timeLogId = req.params.timeLogId;
  console.log(`[${timestamp}] POST /api/employee/tasks/${taskId}/time-logs/${timeLogId}/stop (custom handler)`);
  
  const stopTimeTracking = require('./data/stop-time-tracking.json');
  res.status(200).json(stopTimeTracking);
});

server.delete('/api/employee/tasks/:taskId/time-logs/:timeLogId', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  const timeLogId = req.params.timeLogId;
  console.log(`[${timestamp}] DELETE /api/employee/tasks/${taskId}/time-logs/${timeLogId} (custom handler)`);
  
  const deleteTimeLog = require('./data/delete-time-log.json');
  res.status(200).json(deleteTimeLog);
});

// Checklists handlers
server.get('/api/employee/tasks/:taskId/checklists', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  console.log(`[${timestamp}] GET /api/employee/tasks/${taskId}/checklists (custom handler)`);
  
  const checklists = require('./data/checklists.json');
  res.status(200).json(checklists[0]);
});

server.post('/api/employee/tasks/:taskId/checklists/create', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  console.log(`[${timestamp}] POST /api/employee/tasks/${taskId}/checklists/create (custom handler)`);
  
  const createChecklist = require('./data/create-checklist.json');
  res.status(200).json(createChecklist);
});

server.delete('/api/employee/tasks/:taskId/checklists/:checklistId', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  const checklistId = req.params.checklistId;
  console.log(`[${timestamp}] DELETE /api/employee/tasks/${taskId}/checklists/${checklistId} (custom handler)`);
  
  const deleteChecklist = require('./data/delete-checklist.json');
  res.status(200).json(deleteChecklist);
});

server.post('/api/employee/tasks/:taskId/checklists/:checklistId/items', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  const checklistId = req.params.checklistId;
  console.log(`[${timestamp}] POST /api/employee/tasks/${taskId}/checklists/${checklistId}/items (custom handler)`);
  
  const addChecklistItem = require('./data/add-checklist-item.json');
  res.status(200).json(addChecklistItem);
});

server.put('/api/employee/tasks/:taskId/checklists/items/:itemId', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  const itemId = req.params.itemId;
  console.log(`[${timestamp}] PUT /api/employee/tasks/${taskId}/checklists/items/${itemId} (custom handler)`);
  
  const updateChecklistItem = require('./data/update-checklist-item.json');
  res.status(200).json(updateChecklistItem);
});

server.delete('/api/employee/tasks/:taskId/checklists/items/:itemId/delete', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  const itemId = req.params.itemId;
  console.log(`[${timestamp}] DELETE /api/employee/tasks/${taskId}/checklists/items/${itemId}/delete (custom handler)`);
  
  const deleteChecklistItem = require('./data/delete-checklist-item.json');
  res.status(200).json(deleteChecklistItem);
});

// Comments handlers
server.get('/api/employee/tasks/:taskId/comments/list', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  console.log(`[${timestamp}] GET /api/employee/tasks/${taskId}/comments/list (custom handler)`);
  
  const listComments = require('./data/list-comments.json');
  res.status(200).json(listComments[0]);
});

server.post('/api/employee/tasks/:taskId/comments', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  console.log(`[${timestamp}] POST /api/employee/tasks/${taskId}/comments (custom handler)`);
  
  const comments = require('./data/comments.json');
  res.status(200).json(comments);
});

server.delete('/api/employee/tasks/:taskId/comments/:commentId', (req, res) => {
  const timestamp = new Date().toISOString();
  const taskId = req.params.taskId;
  const commentId = req.params.commentId;
  console.log(`[${timestamp}] DELETE /api/employee/tasks/${taskId}/comments/${commentId} (custom handler)`);
  
  const deleteComment = require('./data/delete-comment.json');
  res.status(200).json(deleteComment);
});

server.post('/api/login', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/login (custom handler)`);
  console.log('  → Email:', req.body?.email);
  
  if (db.login) {
    console.log('  → Returning login response:', JSON.stringify(db.login));
    res.status(200).json(db.login);
  } else {
    console.log('  → No login data available');
    res.status(500).json({ error: 'Login data not found' });
  }
});

// ============================================
// CUSTOM DASHBOARD HANDLER
// ============================================
server.post('/dashboard', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /dashboard (custom handler)`);
  
  if (db.dashboard && db.dashboard.length > 0) {
    console.log('  → Returning dashboard data:', JSON.stringify(db.dashboard[0]));
    res.status(200).json(db.dashboard[0]);
  } else {
    console.log('  → No dashboard data available');
    res.status(404).json({ error: 'Dashboard data not found' });
  }
});

server.post('/api/dashboard', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/dashboard (custom handler)`);
  
  if (db.dashboard && db.dashboard.length > 0) {
    console.log('  → Returning dashboard data:', JSON.stringify(db.dashboard[0]));
    res.status(200).json(db.dashboard[0]);
  } else {
    console.log('  → No dashboard data available');
    res.status(404).json({ error: 'Dashboard data not found' });
  }
});

server.post('/api/employee/dashboard', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/dashboard (custom handler)`);
  
  if (db.dashboard && db.dashboard.length > 0) {
    console.log('  → Returning dashboard data:', JSON.stringify(db.dashboard[0]));
    res.status(200).json(db.dashboard[0]);
  } else {
    console.log('  → No dashboard data available');
    res.status(404).json({ error: 'Dashboard data not found' });
  }
});

// ============================================
// CUSTOM TASK STATUS UPDATE HANDLER
// ============================================
server.post('/api/employee/tasks/:taskId/status', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/tasks/:taskId/status (custom handler)`);
  console.log('  → Task ID:', req.params.taskId);
  console.log('  → Status:', req.body?.status);
  
  if (db.updateTaskStatus) {
    console.log('  → Returning task status update response:', JSON.stringify(db.updateTaskStatus));
    res.status(200).json(db.updateTaskStatus);
  } else {
    console.log('  → No task status update data available');
    res.status(404).json({ error: 'Task status update data not found' });
  }
});

server.post('/updateTaskStatus', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /updateTaskStatus (custom handler)`);
  console.log('  → Task ID:', req.params.taskId);
  console.log('  → Status:', req.body?.status);
  
  if (db.updateTaskStatus) {
    console.log('  → Returning task status update response:', JSON.stringify(db.updateTaskStatus));
    res.status(200).json(db.updateTaskStatus);
  } else {
    console.log('  → No task status update data available');
    res.status(404).json({ error: 'Task status update data not found' });
  }
});

// ============================================
// CUSTOM TIME LOGS HANDLER
// ============================================
server.get('/api/employee/tasks/:taskId/time-logs', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] GET /api/employee/tasks/:taskId/time-logs (custom handler)`);
  console.log('  → Task ID:', req.params.taskId);
  
  if (db.timeLogs) {
    console.log('  → Returning time logs response:', JSON.stringify(db.timeLogs));
    res.status(200).json(db.timeLogs);
  } else {
    console.log('  → No time logs data available');
    res.status(404).json({ error: 'Time logs data not found' });
  }
});

server.get('/timeLogs', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] GET /timeLogs (custom handler)`);
  console.log('  → Task ID:', req.params.taskId);
  
  if (db.timeLogs) {
    console.log('  → Returning time logs response:', JSON.stringify(db.timeLogs));
    res.status(200).json(db.timeLogs);
  } else {
    console.log('  → No time logs data available');
    res.status(404).json({ error: 'Time logs data not found' });
  }
});

// ============================================
// CUSTOM BREAK REQUESTS HANDLER
// ============================================
server.post('/api/employee/break-change-requests/list', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/break-change-requests/list (custom handler)`);
  
  if (db.breakChangeRequests && db.breakChangeRequests.length > 0) {
    console.log('  → Returning break change requests response:', JSON.stringify(db.breakChangeRequests[0]));
    res.status(200).json(db.breakChangeRequests[0]);
  } else {
    console.log('  → No break change requests data available');
    res.status(404).json({ error: 'Break change requests data not found' });
  }
});

server.post('/breakChangeRequests', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /breakChangeRequests (custom handler)`);
  
  if (db.breakChangeRequests && db.breakChangeRequests.length > 0) {
    console.log('  → Returning break change requests response:', JSON.stringify(db.breakChangeRequests[0]));
    res.status(200).json(db.breakChangeRequests[0]);
  } else {
    console.log('  → No break change requests data available');
    res.status(404).json({ error: 'Break change requests data not found' });
  }
});

// ============================================
// CUSTOM START TIME TRACKING HANDLER
// ============================================
server.post('/api/employee/tasks/:taskId/time-logs/start', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/tasks/:taskId/time-logs/start (custom handler)`);
  console.log('  → Task ID:', req.params.taskId);
  
  if (db.startTimeTracking) {
    console.log('  → Returning start time tracking response:', JSON.stringify(db.startTimeTracking));
    res.status(200).json(db.startTimeTracking);
  } else {
    console.log('  → No start time tracking data available');
    res.status(404).json({ error: 'Start time tracking data not found' });
  }
});

server.post('/startTimeTracking', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /startTimeTracking (custom handler)`);
  console.log('  → Task ID:', req.params.taskId);
  
  if (db.startTimeTracking) {
    console.log('  → Returning start time tracking response:', JSON.stringify(db.startTimeTracking));
    res.status(200).json(db.startTimeTracking);
  } else {
    console.log('  → No start time tracking data available');
    res.status(404).json({ error: 'Start time tracking data not found' });
  }
});

// ============================================
// CUSTOM STOP TIME TRACKING HANDLER
// ============================================
server.post('/api/employee/tasks/:taskId/time-logs/:timeLogId/stop', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/tasks/:taskId/time-logs/:timeLogId/stop (custom handler)`);
  console.log('  → Task ID:', req.params.taskId);
  console.log('  → Time Log ID:', req.params.timeLogId);
  
  if (db.stopTimeTracking) {
    console.log('  → Returning stop time tracking response:', JSON.stringify(db.stopTimeTracking));
    res.status(200).json(db.stopTimeTracking);
  } else {
    console.log('  → No stop time tracking data available');
    res.status(404).json({ error: 'Stop time tracking data not found' });
  }
});

server.post('/stopTimeTracking', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /stopTimeTracking (custom handler)`);
  console.log('  → Task ID:', req.params.taskId);
  console.log('  → Time Log ID:', req.params.timeLogId);
  
  if (db.stopTimeTracking) {
    console.log('  → Returning stop time tracking response:', JSON.stringify(db.stopTimeTracking));
    res.status(200).json(db.stopTimeTracking);
  } else {
    console.log('  → No stop time tracking data available');
    res.status(404).json({ error: 'Stop time tracking data not found' });
  }
});

// ============================================
// CUSTOM DELETE TIME LOG HANDLER
// ============================================
server.delete('/api/employee/tasks/:taskId/time-logs/:timeLogId', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] DELETE /api/employee/tasks/:taskId/time-logs/:timeLogId (custom handler)`);
  console.log('  → Task ID:', req.params.taskId);
  console.log('  → Time Log ID:', req.params.timeLogId);
  
  if (db.deleteTimeLog) {
    console.log('  → Returning delete time log response:', JSON.stringify(db.deleteTimeLog));
    res.status(200).json(db.deleteTimeLog);
  } else {
    console.log('  → No delete time log data available');
    res.status(404).json({ error: 'Delete time log data not found' });
  }
});

server.delete('/deleteTimeLog', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] DELETE /deleteTimeLog (custom handler)`);
  console.log('  → Task ID:', req.params.taskId);
  console.log('  → Time Log ID:', req.params.timeLogId);
  
  if (db.deleteTimeLog) {
    console.log('  → Returning delete time log response:', JSON.stringify(db.deleteTimeLog));
    res.status(200).json(db.deleteTimeLog);
  } else {
    console.log('  → No delete time log data available');
    res.status(404).json({ error: 'Delete time log data not found' });
  }
});

// ============================================
// CUSTOM BREAK TYPES HANDLER
// ============================================
server.post('/api/employee/break-types', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/break-types (custom handler)`);
  
  const breakTypesData = require('./data/break-types.json');
  if (breakTypesData && breakTypesData.length > 0) {
    console.log('  → Returning break types response:', JSON.stringify(breakTypesData[0]));
    res.status(200).json(breakTypesData[0]);
  } else {
    console.log('  → No break types data available');
    res.status(404).json({ error: 'Break types data not found' });
  }
});

server.post('/employee/break-types', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /employee/break-types (custom handler)`);
  
  const breakTypesData = require('./data/break-types.json');
  if (breakTypesData && breakTypesData.length > 0) {
    console.log('  → Returning break types response:', JSON.stringify(breakTypesData[0]));
    res.status(200).json(breakTypesData[0]);
  } else {
    console.log('  → No break types data available');
    res.status(404).json({ error: 'Break types data not found' });
  }
});

server.post('/breakTypes', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /breakTypes (custom handler)`);
  
  const breakTypesData = require('./data/break-types.json');
  if (breakTypesData && breakTypesData.length > 0) {
    console.log('  → Returning break types response:', JSON.stringify(breakTypesData[0]));
    res.status(200).json(breakTypesData[0]);
  } else {
    console.log('  → No break types data available');
    res.status(404).json({ error: 'Break types data not found' });
  }
});

// ============================================
// CUSTOM HALL OF FAME HANDLER
// ============================================
server.post('/hallOfFame', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /hallOfFame (custom handler)`);
  
  if (db.hallOfFame) {
    console.log('  → Returning hall of fame data:', JSON.stringify(db.hallOfFame));
    res.status(200).json(db.hallOfFame);
  } else {
    console.log('  → No hall of fame data available');
    res.status(404).json({ error: 'Hall of fame data not found' });
  }
});

server.post('/api/hallOfFame', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/hallOfFame (custom handler)`);
  
  if (db.hallOfFame) {
    console.log('  → Returning hall of fame data:', JSON.stringify(db.hallOfFame));
    res.status(200).json(db.hallOfFame);
  } else {
    console.log('  → No hall of fame data available');
    res.status(404).json({ error: 'Hall of fame data not found' });
  }
});

server.post('/api/employee/hall-of-fame', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/hall-of-fame (custom handler)`);
  
  if (db.hallOfFame) {
    console.log('  → Returning hall of fame data:', JSON.stringify(db.hallOfFame));
    res.status(200).json(db.hallOfFame);
  } else {
    console.log('  → No hall of fame data available');
    res.status(404).json({ error: 'Hall of fame data not found' });
  }
});

// ============================================
// CUSTOM ATTENDANCE MARK HANDLER (Clock In/Out)
// ============================================
server.post('/api/employee/attendance/mark', (req, res) => {
  const timestamp = new Date().toISOString();
  const action = req.body?.action;
  console.log(`[${timestamp}] POST /api/employee/attendance/mark (custom handler)`);
  console.log('  → Action:', action);
  
  const attendanceMarks = require('./data/attendance-marks.json');
  
  // Find the appropriate response based on action
  let responseData;
  if (action === 'clock_in') {
    responseData = attendanceMarks.find(m => m.type === 'clock-in');
  } else if (action === 'clock_out') {
    responseData = attendanceMarks.find(m => m.type === 'clock-out');
  } else {
    responseData = attendanceMarks[0]; // Default to first entry
  }
  
  if (responseData) {
    console.log('  → Returning attendance mark response:', JSON.stringify(responseData));
    res.status(200).json(responseData);
  } else {
    console.log('  → No attendance mark data available');
    res.status(404).json({ error: 'Attendance mark data not found' });
  }
});

server.post('/api/employee/attendance', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/attendance (custom handler)`);
  console.log('  → Request body:', JSON.stringify(req.body));
  
  const attendances = require('./data/attendances.json');
  res.status(200).json(attendances[0]);
});

server.post('/employee/attendance', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /employee/attendance (custom handler)`);
  console.log('  → Request body:', JSON.stringify(req.body));
  
  const attendances = require('./data/attendances.json');
  res.status(200).json(attendances[0]);
});

server.post('/employee/attendance/mark', (req, res) => {
  const timestamp = new Date().toISOString();
  const action = req.body?.action;
  console.log(`[${timestamp}] POST /employee/attendance/mark (custom handler)`);
  console.log('  → Action:', action);

  const attendanceMarks = require('./data/attendance-marks.json');
  
  // Find the appropriate response based on action
  let responseData;
  if (action === 'clock_in') {
    responseData = attendanceMarks.find(m => m.type === 'clock-in');
  } else if (action === 'clock_out') {
    responseData = attendanceMarks.find(m => m.type === 'clock-out');
  } else {
    responseData = attendanceMarks[0]; // Default to first entry
  }
  
  if (responseData) {
    console.log('  → Returning attendance mark response:', JSON.stringify(responseData));
    res.status(200).json(responseData);
  } else {
    console.log('  → No attendance mark data available');
    res.status(404).json({ error: 'Attendance mark data not found' });
  }
});

// ============================================
// CUSTOM PROFILE HANDLER
// ============================================
server.post('/api/employee/profile', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/profile (custom handler)`);
  
  if (db.profile && db.profile.length > 0) {
    console.log('  → Returning profile data:', JSON.stringify(db.profile[0]));
    res.status(200).json(db.profile[0]);
  } else {
    console.log('  → No profile data available');
    res.status(404).json({ error: 'Profile data not found' });
  }
});

server.post('/employee/profile', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /employee/profile (custom handler)`);
  
  if (db.profile && db.profile.length > 0) {
    console.log('  → Returning profile data:', JSON.stringify(db.profile[0]));
    res.status(200).json(db.profile[0]);
  } else {
    console.log('  → No profile data available');
    res.status(404).json({ error: 'Profile data not found' });
  }
});

// ============================================
// CUSTOM BREAK TYPES HANDLER
// ============================================
server.post('/api/employee/break-types', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /api/employee/break-types (custom handler)`);
  
  if (db.breakTypes && db.breakTypes.length > 0) {
    console.log('  → Returning break types data:', JSON.stringify(db.breakTypes[0]));
    res.status(200).json(db.breakTypes[0]);
  } else {
    console.log('  → No break types data available');
    res.status(404).json({ error: 'Break types data not found' });
  }
});

server.post('/breakTypes', (req, res) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] POST /breakTypes (custom handler)`);
  
  if (db.breakTypes && db.breakTypes.length > 0) {
    console.log('  → Returning break types data:', JSON.stringify(db.breakTypes[0]));
    res.status(200).json(db.breakTypes[0]);
  } else {
    console.log('  → No break types data available');
    res.status(404).json({ error: 'Break types data not found' });
  }
});

// ============================================
// ROUTES REWRITER - Runs AFTER custom handlers
// ============================================
server.use(jsonServer.rewriter(routes));

// ============================================
// CUSTOM MIDDLEWARE - Change 201 to 200 for POST
// ============================================
server.use((req, res, next) => {
  const originalEnd = res.end;
  res.end = function(...args) {
    if (req.method === 'POST' && res.statusCode === 201) {
      res.statusCode = 200;
    }
    return originalEnd.apply(this, args);
  };
  next();
});

// ============================================
// JSON SERVER ROUTER - For all other endpoints
// ============================================
server.use(router);

// Start server
const PORT = 5000;
server.listen(PORT, () => {
  console.log('========================================');
  console.log('HR System Mock Server');
  console.log('========================================');
  console.log(`Server is running on http://localhost:${PORT}`);
  console.log(`API available at http://localhost:${PORT}/api`);
  console.log('');
  console.log('Login endpoint: POST /api/login (accepts any credentials)');
  console.log('');
  console.log('Data loaded from separate JSON files');
  console.log(`Number of data files loaded: ${Object.keys(db).length}`);
  console.log('Data keys:', Object.keys(db));
  console.log('Break types data:', db.breakTypes);
  console.log('');
  console.log('Press Ctrl+C to stop the server');
  console.log('========================================');
});
