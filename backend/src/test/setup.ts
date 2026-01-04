beforeAll(() => {
  process.env.NODE_ENV = 'test';
  process.env.PORT = '3001';
  process.env.DB_PATH = ':memory:';
});
