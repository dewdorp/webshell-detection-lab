const userInfo = document.getElementById('userInfo');
const logoutBtn = document.getElementById('logoutBtn');
const userStats = document.getElementById('userStats');
const systemStatus = document.getElementById('systemStatus');
const recentActivity = document.getElementById('recentActivity');
const alerts = document.getElementById('alerts');
function randomInt(min, max) { return Math.floor(Math.random() * (max - min + 1)) + min; }
function renderUserStats() { userStats.innerHTML = `<div class="metric"><span>이번 달 로그인 횟수</span><strong>${randomInt(8, 48)}회</strong></div><div class="metric"><span>활성 세션 수</span><strong>${randomInt(1, 6)}개</strong></div><div class="metric"><span>감지된 이벤트</span><strong>${randomInt(0, 12)}건</strong></div><span class="badge">Gemini Sync 안정적</span>`; }
function renderSystemStatus() { systemStatus.innerHTML = `<div class="metric"><span>CPU 사용률</span><strong>${randomInt(21, 63)}%</strong></div><div class="metric"><span>메모리 사용률</span><strong>${randomInt(34, 76)}%</strong></div><div class="metric"><span>네트워크 안정도</span><strong>${randomInt(92, 99)}%</strong></div><span class="badge">보안 노드 정상 작동 중</span>`; }
function renderRecentActivity() { const items = ['보안 정책 점검이 완료되었습니다.', '새 로그인 세션이 감지되었습니다.', '계정 보호 상태가 업데이트되었습니다.', '웹쉘 탐지 PoC 업로드 페이지가 준비되었습니다.']; recentActivity.innerHTML = `<ul>${items.map((item) => `<li>${item}</li>`).join('')}</ul>`; }
function renderAlerts() { alerts.innerHTML = `<p>현재 확인이 필요한 알림은 <strong>${randomInt(1, 5)}건</strong>입니다.</p><ul><li>주의: 업로드 테스트 디렉터리는 Agent 감시 대상이어야 합니다.</li><li>안내: 런타임 교체 시 업로드 경로를 다시 확인하세요.</li><li>알림: HTTPS 접속은 Nginx reverse proxy를 통해 제공됩니다.</li></ul>`; }
async function loadDashboard() { const token = localStorage.getItem('token'); if (!token) { window.location.href = '/login.html'; return; } try { const response = await fetch('/api/dashboard', { headers: { Authorization: `Bearer ${token}` } }); const data = await response.json(); if (!response.ok || !data.success) { alert(data.message || '인증에 실패했습니다.'); localStorage.removeItem('token'); window.location.href = '/login.html'; return; } userInfo.textContent = `환영합니다, ${data.username}님!`; renderUserStats(); renderSystemStatus(); renderRecentActivity(); renderAlerts(); } catch (error) { console.error('Dashboard load failed:', error); alert('대시보드를 불러올 수 없습니다.'); localStorage.removeItem('token'); window.location.href = '/login.html'; } }
document.addEventListener('DOMContentLoaded', loadDashboard);
logoutBtn.addEventListener('click', () => { localStorage.removeItem('token'); window.location.href = '/login.html'; });
