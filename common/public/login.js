const loginForm = document.getElementById('loginForm');
loginForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const username = document.getElementById('username').value.trim();
  const password = document.getElementById('password').value;
  try {
    const response = await fetch('/api/login', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ username, password }) });
    const data = await response.json();
    if (response.ok && data.success) { localStorage.setItem('token', data.token); window.location.href = '/dashboard.html'; return; }
    alert(data.message || '로그인 중 오류가 발생했습니다.');
  } catch (error) { console.error('Login request failed:', error); alert('서버에 연결할 수 없습니다.'); }
});
