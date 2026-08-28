function test() {
  fetch('/api/orders');
  fetch('http://localhost:7071/api/ping');
  fetch('https://127.0.0.1:443/path');
  const ignored = '//set';
}
