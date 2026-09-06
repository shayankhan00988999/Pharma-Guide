/**
 * Pharma's Guide — Sheets-based signup / login / forgot-password backend.
 *
 * NOTE: No changes needed here. The "folders take a long time to show
 * up after login" issue was entirely on the Drive-tree script's side
 * (it was recursively scanning every subfolder on every request) —
 * this auth script was already fast and doesn't need any changes.
 * Kept here unmodified for reference alongside Code_DriveTree.gs.
 *
 * SETUP:
 * 1. Open a Google Sheet (new or existing) that you want to use as your
 *    user database.
 * 2. Extensions > Apps Script. Delete any starter code, paste this whole
 *    file in.
 * 3. Deploy > New deployment > select type "Web app".
 *      - Execute as: Me
 *      - Who has access: Anyone
 * 4. Click Deploy, authorize the permissions it asks for, then copy the
 *    "/exec" Web app URL it gives you.
 * 5. Paste that URL into lib/config.dart as authApiUrl in your Flutter app.
 *
 * The sheet named "Users" is created automatically the first time this
 * script runs — you don't need to set up columns yourself.
 */

function doPost(e) {
  var params = (e && e.parameter) || {};
  var action = params.action;
  var result;

  try {
    if (action === 'signup') {
      result = handleSignup(params);
    } else if (action === 'login') {
      result = handleLogin(params);
    } else if (action === 'forgot_password') {
      result = handleForgotPassword(params);
    } else {
      result = { success: false, message: 'Unknown action: ' + action };
    }
  } catch (err) {
    result = { success: false, message: 'Server error: ' + err.message };
  }

  return ContentService.createTextOutput(JSON.stringify(result))
      .setMimeType(ContentService.MimeType.JSON);
}

// A GET request (e.g. opening the URL directly in a browser) returns a
// friendly JSON message instead of an error, so you can quickly sanity
// check that the deployment itself is reachable.
function doGet(e) {
  var body = { success: true, message: "Pharma's Guide auth endpoint is live. Use POST requests." };
  return ContentService.createTextOutput(JSON.stringify(body))
      .setMimeType(ContentService.MimeType.JSON);
}

function getSheet() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName('Users');
  if (!sheet) {
    sheet = ss.insertSheet('Users');
    sheet.appendRow(['Timestamp', 'Name', 'Email', 'PasswordHash', 'Token', 'City', 'Region', 'Country', 'IP']);
  }
  return sheet;
}

function hashPassword(password) {
  var digest = Utilities.computeDigest(Utilities.DigestAlgorithm.SHA_256, password, Utilities.Charset.UTF_8);
  return digest.map(function (b) {
    var v = (b < 0 ? b + 256 : b).toString(16);
    return v.length === 1 ? '0' + v : v;
  }).join('');
}

function generateToken() {
  return Utilities.getUuid();
}

function findRowByEmail(sheet, email) {
  var data = sheet.getDataRange().getValues();
  var lowerEmail = String(email).trim().toLowerCase();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][2]).trim().toLowerCase() === lowerEmail) {
      return { rowIndex: i + 1, row: data[i] };
    }
  }
  return null;
}

function handleSignup(params) {
  var name = (params.name || '').trim();
  var email = (params.email || '').trim();
  var password = params.password || '';

  if (!name || !email || !password) {
    return { success: false, message: 'Name, email and password are required.' };
  }
  if (password.length < 4) {
    return { success: false, message: 'Password must be at least 4 characters.' };
  }

  var sheet = getSheet();
  if (findRowByEmail(sheet, email)) {
    return { success: false, message: 'An account with this email already exists.' };
  }

  sheet.appendRow([
    new Date(),
    name,
    email,
    hashPassword(password),
    '',
    params.location_city || '',
    params.location_region || '',
    params.location_country || '',
    params.location_ip || ''
  ]);

  return { success: true, message: 'Account created successfully.' };
}

function handleLogin(params) {
  var email = (params.email || '').trim();
  var password = params.password || '';

  if (!email || !password) {
    return { success: false, message: 'Email and password are required.' };
  }

  var sheet = getSheet();
  var found = findRowByEmail(sheet, email);
  if (!found || found.row[3] !== hashPassword(password)) {
    return { success: false, message: 'Invalid email or password.' };
  }

  var token = generateToken();
  sheet.getRange(found.rowIndex, 5).setValue(token);

  return { success: true, message: 'Login successful.', token: token };
}

function handleForgotPassword(params) {
  var email = (params.email || '').trim();
  if (!email) {
    return { success: false, message: 'Email is required.' };
  }

  var sheet = getSheet();
  var found = findRowByEmail(sheet, email);

  // Don't reveal whether the email exists — same message either way.
  if (!found) {
    return { success: true, message: 'If this email is registered, a new password has been sent.' };
  }

  var tempPassword = generateTempPassword();
  sheet.getRange(found.rowIndex, 4).setValue(hashPassword(tempPassword));

  MailApp.sendEmail({
    to: email,
    subject: "Your Pharma's Guide temporary password",
    body: 'Hello,\n\nYour temporary password is: ' + tempPassword +
        '\n\nPlease log in with it, then you can keep using it or it will be' +
        ' replaced next time you request a reset.\n\n- Pharma\'s Guide'
  });

  return { success: true, message: 'If this email is registered, a new password has been sent.' };
}

function generateTempPassword() {
  var chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  var pass = '';
  for (var i = 0; i < 10; i++) {
    pass += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return pass;
}
