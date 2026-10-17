function fn() {
  karate.configure('connectTimeout', 5000);
  karate.configure('readTimeout', 120000);
  return { baseUrl: karate.properties['baseUrl'] || 'http://127.0.0.1:8001' };
}
