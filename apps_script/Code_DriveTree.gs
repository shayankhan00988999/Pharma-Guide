/**
 * Shayan Pharma Guide — Drive Folder Tree API
 * ---------------------------------------------
 * Deploy this as a Web App. GET requests return a JSON node for ONE
 * folder at a time (its direct subfolders + files) — not the whole
 * Drive tree recursively. The Flutter app calls this once for the
 * root folder right after login (fast), then calls it again with
 * ?folderId=<id> only when the student actually taps into a folder.
 *
 * This is the key change from the old version: the old script walked
 * the ENTIRE folder tree on every request (recursing into every
 * subfolder), which is why folders took a long time to show up after
 * login once you had more than a handful of files. This version only
 * ever looks at one folder's direct contents, so the response time
 * stays roughly constant no matter how much you upload.
 *
 * SETUP:
 * 1. Go to script.google.com -> New project, paste this in as Code.gs
 * 2. Set ROOT_FOLDER_ID below to your Year 2 notes folder's ID
 *    (the long string in the folder's Drive URL after /folders/)
 * 3. Deploy -> New deployment -> type: Web app
 *      - Execute as: Me
 *      - Who has access: Anyone (the app calls this anonymously;
 *        access to the actual files is still controlled by Drive
 *        sharing settings on ROOT_FOLDER_ID)
 * 4. Copy the deployment URL — that's the endpoint your Flutter app calls.
 * 5. Every time you edit the script (not just the Drive contents),
 *    you must create a NEW deployment version for changes to go live.
 *    Editing files *inside* the Drive folder does NOT require a
 *    redeploy — the script reads Drive live on every request.
 */

// ==== CONFIG ====
const ROOT_FOLDER_ID = '1dWtyWxqoRRftwaUWCeS4SmVDB1fdpFAm';
const CACHE_SECONDS = 300; // 5 min cache per folder to keep things fast

/**
 * Entry point for GET requests.
 *   ?folderId=<id>  — return that folder's direct contents (defaults
 *                      to ROOT_FOLDER_ID when omitted, i.e. the first
 *                      screen after login).
 *   ?refresh=1       — bypass the cache and force a fresh Drive read
 *                      for that folder (used for pull-to-refresh).
 */
function doGet(e) {
  try {
    const params = (e && e.parameter) || {};
    const folderId = params.folderId || ROOT_FOLDER_ID;
    const forceRefresh = params.refresh === '1';

    const node = forceRefresh ? buildShallowNode(folderId) : getCachedNode(folderId);

    return ContentService
      .createTextOutput(JSON.stringify({ success: true, data: node }))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService
      .createTextOutput(JSON.stringify({ success: false, error: err.message }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

function cacheKeyFor(folderId) {
  return 'folder_v2_' + folderId;
}

/**
 * Returns the cached node for this folder if present and fresh,
 * otherwise rebuilds just this one folder from Drive.
 */
function getCachedNode(folderId) {
  const cache = CacheService.getScriptCache();
  const cached = cache.get(cacheKeyFor(folderId));
  if (cached) {
    return JSON.parse(cached);
  }
  return buildShallowNode(folderId);
}

/**
 * Builds ONE folder's node: its own id/name plus its DIRECT children
 * only. Subfolders are listed with a cheap itemCount (their own
 * direct child count) so the UI can show "12 items" without having
 * to descend any further — the actual contents of a subfolder are
 * only fetched when the student taps into it.
 */
function buildShallowNode(folderId) {
  const folder = DriveApp.getFolderById(folderId);
  const node = {
    type: 'folder',
    id: folder.getId(),
    name: folder.getName(),
    children: []
  };

  // Subfolders first, then files, both alphabetical — keeps the UI predictable.
  const subfolders = getSortedFolders(folder);
  for (let i = 0; i < subfolders.length; i++) {
    const sub = subfolders[i];
    node.children.push({
      type: 'folder',
      id: sub.getId(),
      name: sub.getName(),
      itemCount: countImmediateChildren(sub),
      children: []
    });
  }

  const files = getSortedFiles(folder);
  for (let j = 0; j < files.length; j++) {
    node.children.push(fileToNode(files[j]));
  }

  const cache = CacheService.getScriptCache();
  try {
    cache.put(cacheKeyFor(folderId), JSON.stringify(node), CACHE_SECONDS);
  } catch (e) {
    // Node too large for the 100KB per-key cache limit — safe to
    // ignore, next request just rebuilds this one folder (still fast,
    // since it's only ever 1 level deep).
  }

  return node;
}

/**
 * Direct child count of a folder (subfolders + files), without
 * descending into any of them. Cheap — used only to show "N items"
 * on a subfolder's card before the student opens it.
 */
function countImmediateChildren(folder) {
  let count = 0;
  const fIt = folder.getFolders();
  while (fIt.hasNext()) { fIt.next(); count++; }
  const it = folder.getFiles();
  while (it.hasNext()) { it.next(); count++; }
  return count;
}

/**
 * Converts a Drive file into a plain JSON node with everything the
 * app needs to show it and let students open/download it.
 */
function fileToNode(file) {
  return {
    type: 'file',
    id: file.getId(),
    name: file.getName(),
    mimeType: file.getMimeType(),
    sizeBytes: file.getSize(),
    modifiedAt: file.getLastUpdated().toISOString(),
    // Opens Drive's built-in viewer — works for PDFs, docs, images, etc.
    viewUrl: 'https://drive.google.com/file/d/' + file.getId() + '/view',
    // Direct download link the app can hand to its download manager.
    downloadUrl: 'https://drive.google.com/uc?export=download&id=' + file.getId()
  };
}

// ---- Helpers: sorted iteration over folders/files ----

function getSortedFolders(folder) {
  const result = [];
  const it = folder.getFolders();
  while (it.hasNext()) result.push(it.next());
  result.sort(function (a, b) { return a.getName().localeCompare(b.getName()); });
  return result;
}

function getSortedFiles(folder) {
  const result = [];
  const it = folder.getFiles();
  while (it.hasNext()) result.push(it.next());
  result.sort(function (a, b) { return a.getName().localeCompare(b.getName()); });
  return result;
}

/**
 * Run this manually from the Apps Script editor (select it in the
 * function dropdown, then Run) to sanity-check ROOT_FOLDER_ID and
 * grant Drive permissions before you deploy.
 */
function testBuildTree() {
  const node = buildShallowNode(ROOT_FOLDER_ID);
  Logger.log(JSON.stringify(node, null, 2));
}
