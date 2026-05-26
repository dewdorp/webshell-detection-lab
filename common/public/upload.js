const watchPath = document.getElementById('watchPath');
const uploadForm = document.getElementById('uploadForm');
const fileInput = document.getElementById('fileInput');
const uploadResult = document.getElementById('uploadResult');
const fileList = document.getElementById('fileList');
const refreshFiles = document.getElementById('refreshFiles');

function basePath() {
  const script = document.currentScript || document.querySelector('script[src$="upload.js"]');
  if (!script) return '';
  const url = new URL(script.getAttribute('src'), window.location.href);
  return url.pathname.replace(/\/upload\.js$/, '').replace(/\/$/, '');
}

const apiBase = basePath();
const labUrl = (path) => `${apiBase}${path}`;

function formatBytes(size) { if (size < 1024) return `${size} B`; if (size < 1024 * 1024) return `${(size / 1024).toFixed(1)} KB`; return `${(size / 1024 / 1024).toFixed(1)} MB`; }
async function fetchJson(url, options) { const response = await fetch(url, options); const text = await response.text(); const data = text ? JSON.parse(text) : {}; if (!response.ok) throw new Error(data.message || `Request failed with ${response.status}`); return data; }
async function loadHealth() { try { const health = await fetchJson(labUrl('/health')); watchPath.textContent = `${health.runtime || 'unknown'} runtime upload path: ${health.uploadPath}`; } catch (error) { watchPath.textContent = error.message; } }
function renderFiles(files) { if (!files.length) { fileList.innerHTML = '<p class="form-copy">업로드된 파일이 없습니다.</p>'; return; } fileList.innerHTML = files.map((file) => { const modified = file.modifiedAt ? new Date(file.modifiedAt).toLocaleString() : 'unknown time'; const rawHref = file.url || `/uploads/${encodeURIComponent(file.name)}`; const href = rawHref.startsWith('/uploads/') ? labUrl(rawHref) : rawHref; return `<div class="file-row"><div><strong>${file.name}</strong><span>${formatBytes(file.size || 0)} · ${modified}</span></div><a class="secondary-btn" href="${href}" target="_blank" rel="noreferrer">열기</a></div>`; }).join(''); }
async function loadFiles() { try { const data = await fetchJson(labUrl('/files')); renderFiles(data.files || []); } catch (error) { fileList.innerHTML = `<p class="form-copy">${error.message}</p>`; } }
uploadForm.addEventListener('submit', async (event) => { event.preventDefault(); const file = fileInput.files[0]; if (!file) return; const formData = new FormData(); formData.append('file', file); uploadResult.textContent = '업로드 중...'; try { const data = await fetchJson(labUrl('/upload'), { method: 'POST', body: formData }); uploadResult.textContent = JSON.stringify(data, null, 2); fileInput.value = ''; await loadFiles(); } catch (error) { uploadResult.textContent = error.message; } });
refreshFiles.addEventListener('click', loadFiles);
loadHealth();
loadFiles();
