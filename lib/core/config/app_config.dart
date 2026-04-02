enum Environment { dev, prod }

class AppConfig {
  final Environment environment;
  final String baseUrl;
  final String tusUrl;

  const AppConfig({
    required this.environment,
    required this.baseUrl,
    required this.tusUrl,
  });

  static late AppConfig instance;


  static void initialize(Environment env) {
    switch (env) {
      case Environment.dev:
        instance = const AppConfig(
          environment: Environment.dev,
          baseUrl: 'https://api.bulutcha.com/api/v1/',
          tusUrl: 'https://minio1.bulutcha.com/files/',
        );
        break;
      case Environment.prod:
        instance = const AppConfig(
          environment: Environment.prod,
          baseUrl: 'https://api.bulutcha.com/api/v1/',
          tusUrl: 'https://minio1.bulutcha.com/files/',
        );
        break;
    }
  }
}

