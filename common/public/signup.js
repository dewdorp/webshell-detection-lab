const signupForm = document.getElementById('signupForm');
signupForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const username = document.getElementById('username').value.trim();
  const password = document.getElementById('password').value;
  const confirmPassword = document.getElementById('confirmPassword').value;
  if (password !== confirmPassword) { alert('비밀번호와 비밀번호 확인이 일치하지 않습니다.'); return; }
  try {
    const response = await fetch('/api/signup', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ username, password }) });
    const data = await response.json();
    if (response.ok && data.success) { alert('회원가입 성공!'); window.location.href = '/login.html'; return; }
    alert(data.message || '회원가입 중 오류가 발생했습니다.');
  } catch (error) { console.error('Signup request failed:', error); alert('서버에 연결할 수 없습니다.'); }
});
