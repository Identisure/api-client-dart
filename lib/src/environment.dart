enum Environment {
  production('https://api.idkollen.se'),
  staging('https://stgapi.idkollen.se');

  const Environment(this.baseUrl);
  final String baseUrl;
}
