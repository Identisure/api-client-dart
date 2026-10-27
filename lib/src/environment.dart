enum Environment {
  production('https://api.identisure.com'),
  staging('https://stgapi.identisure.com');

  const Environment(this.baseUrl);
  final String baseUrl;
}
