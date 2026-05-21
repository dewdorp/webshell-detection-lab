const runtimeName = document.getElementById('runtimeName');
const watchPath = document.getElementById('watchPath');
const uploadForm = document.getElementById('uploadForm');
const fileInput = document.getElementById('fileInput');
const uploadResult = document.getElementById('uploadResult');
const fileList = document.getElementById('fileList');
const refreshFiles = document.getElementById('refreshFiles');

function formatBytes(size) {
  if (size < 1024) return `${size} B`;
  if (size < 1024 * 1024) return `${(size / 1024).toFixed(1)} KB`;
  return `${(size / 1024 / 1024).toFixed(1)} MB`;
}

async function fetchJson(url, options) {
  const response = await fetch(url, options);
  const text = await response.text();
  const data = text ? JSON.parse(text) : {};
  if (!response.ok) throw new Error(data.message || `Request failed with ${response.status}`);
  return data;
}

async function loadHealth() {
  try {
    const health = await fetchJson('/health');
    runtimeName.textContent = health.runtime || 'unknown';
    watchPath.textContent = health.uploadPath || 'upload path unavailable';
  } catch (error) {
    runtimeName.textContent = 'offline';
    watchPath.innerHTML = `<span class="error">${error.message}</span>`;
  }
}

function renderFiles(files) {
  if (!files.length) {
    fileList.innerHTML = '<p class="empty">No uploaded files.</p>';
    return;
  }
  fileList.innerHTML = files.map((file) => {
    const modified = file.modifiedAt ? new Date(file.modifiedAt).toLocaleString() : 'unknown time';
    const href = file.url || `/uploads/${encodeURIComponent(file.name)}`;
    return `<article class="file-row"><div><strong>${file.name}</strong><span>${formatBytes(file.size || 0)} · ${modified}</span></div><a href="${href}" target="_blank" rel="noreferrer">Open</a></article>`;
  }).join('');
}

async function loadFiles() {
  try {
    const data = await fetchJson('/files');
    renderFiles(data.files || []);
  } catch (error) {
    fileList.innerHTML = `<p class="error">${error.message}</p>`;
  }
}

uploadForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const file = fileInput.files[0];
  if (!file) return;
  const formData = new FormData();
  formData.append('file', file);
  uploadResult.textContent = 'Uploading...';
  try {
    const data = await fetchJson('/upload', { method: 'POST', body: formData });
    uploadResult.textContent = JSON.stringify(data, null, 2);
    fileInput.value = '';
    await loadFiles();
  } catch (error) {
    uploadResult.textContent = error.message;
    uploadResult.classList.add('error');
  }
});

refreshFiles.addEventListener('click', loadFiles);
loadHealth();
loadFiles();
